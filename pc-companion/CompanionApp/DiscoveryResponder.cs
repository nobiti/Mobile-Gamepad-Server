using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Text.Json;

namespace CompanionApp;

public sealed class DiscoveryResponder : IDisposable
{
    private readonly UdpClient _client;
    private readonly CancellationTokenSource _cts = new();
    private readonly int _streamPort;
    private readonly string _pairCode;
    private readonly PairingSession _pairingSession;

    public DiscoveryResponder(int discoveryPort, int streamPort, string pairCode, PairingSession pairingSession)
    {
        _streamPort = streamPort;
        _pairCode = pairCode;
        _pairingSession = pairingSession;
        _client = new UdpClient(discoveryPort) { EnableBroadcast = true };
    }

    public Task StartAsync() => Task.Run(ListenLoopAsync, _cts.Token);

    public void Stop() => _cts.Cancel();

    public void Dispose()
    {
        Stop();
        _client.Dispose();
        _cts.Dispose();
    }

    private async Task ListenLoopAsync()
    {
        while (!_cts.IsCancellationRequested)
        {
            try
            {
                var result = await _client.ReceiveAsync(_cts.Token);
                var message = Encoding.UTF8.GetString(result.Buffer);
                if (!TryValidateRequest(message))
                {
                    continue;
                }

                var host = GetLocalAddress(result.RemoteEndPoint.AddressFamily) ?? "127.0.0.1";
                var response = new
                {
                    type = "mg_discovery_response",
                    host,
                    port = _streamPort,
                    pairCode = _pairCode,
                    publicKey = _pairingSession.PublicKeyBase64,
                    keyId = _pairingSession.KeyId
                };
                var bytes = JsonSerializer.SerializeToUtf8Bytes(response);
                await _client.SendAsync(bytes, bytes.Length, result.RemoteEndPoint);
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch (Exception)
            {
                await Task.Delay(200, _cts.Token);
            }
        }
    }

    private bool TryValidateRequest(string message)
    {
        try
        {
            using var document = JsonDocument.Parse(message);
            if (!document.RootElement.TryGetProperty("type", out var typeElement) ||
                typeElement.GetString() != "mg_discovery_request")
            {
                return false;
            }

            if (string.IsNullOrWhiteSpace(_pairCode))
            {
                return true;
            }

            if (!document.RootElement.TryGetProperty("pairCode", out var pairElement))
            {
                return false;
            }

            return string.Equals(pairElement.GetString(), _pairCode, StringComparison.OrdinalIgnoreCase);
        }
        catch (Exception)
        {
            return false;
        }
    }

    private static string? GetLocalAddress(AddressFamily family)
    {
        var host = Dns.GetHostEntry(Dns.GetHostName());
        return host.AddressList.FirstOrDefault(ip => ip.AddressFamily == family)?.ToString();
    }
}
