using System.Net;
using System.Net.Sockets;
using System.Text.Json;
using System.Text;

namespace CompanionApp;

public sealed class UdpGamepadServer : IDisposable
{
    private readonly UdpClient _client;
    private readonly CancellationTokenSource _cts = new();
    private readonly ControllerMapper _mapper;
    private readonly string? _sharedSecret;
    private readonly PairingSession _pairingSession;
    private readonly string _pairCode;
    private byte[]? _sessionKey;
    private DateTime _lastPacketUtc = DateTime.MinValue;
    private double? _lastLatencyMs;

    public event EventHandler<PairingStatusEventArgs>? PairingCompleted;
    public event EventHandler<double>? LatencyUpdated;

    public UdpGamepadServer(int port, ControllerMapper mapper, string pairCode, string? sharedSecret, PairingSession pairingSession)
    {
        _client = new UdpClient(new IPEndPoint(IPAddress.Any, port));
        _mapper = mapper;
        _sharedSecret = string.IsNullOrWhiteSpace(sharedSecret) ? null : sharedSecret;
        _pairingSession = pairingSession;
        _pairCode = pairCode;
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
                _lastPacketUtc = DateTime.UtcNow;
                if (TryHandlePairing(result))
                {
                    continue;
                }

                var packet = ParsePacket(result.Buffer);
                if (packet == null)
                {
                    continue;
                }
                UpdateLatency(packet);
                _mapper.Update(packet);
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch (Exception)
            {
                await Task.Delay(50, _cts.Token);
            }
        }
    }

    public bool IsIdle(TimeSpan threshold) => DateTime.UtcNow - _lastPacketUtc > threshold;

    public double? LastLatencyMs => _lastLatencyMs;
    public DateTime LastPacketUtc => _lastPacketUtc;

    private bool TryHandlePairing(UdpReceiveResult result)
    {
        try
        {
            using var document = JsonDocument.Parse(result.Buffer);
            if (!document.RootElement.TryGetProperty("type", out var typeElement) ||
                typeElement.GetString() != "mg_pairing_exchange")
            {
                return false;
            }

            if (!document.RootElement.TryGetProperty("pairCode", out var pairCodeElement) ||
                !document.RootElement.TryGetProperty("keyId", out var keyIdElement) ||
                !document.RootElement.TryGetProperty("clientPublicKey", out var clientKeyElement))
            {
                return true;
            }

            var pairCode = pairCodeElement.GetString() ?? string.Empty;
            var keyId = keyIdElement.GetString() ?? string.Empty;
            var clientPublicKey = clientKeyElement.GetString() ?? string.Empty;
            var deviceName = document.RootElement.TryGetProperty("deviceName", out var deviceElement)
                ? deviceElement.GetString()
                : null;

            if (string.IsNullOrWhiteSpace(pairCode))
            {
                return true;
            }

            if (!string.IsNullOrWhiteSpace(_pairCode) &&
                !string.Equals(pairCode, _pairCode, StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }

            if (string.IsNullOrWhiteSpace(clientPublicKey) ||
                !string.Equals(keyId, _pairingSession.KeyId, StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }

            _sessionKey = _pairingSession.DeriveSessionKey(clientPublicKey);
            PairingCompleted?.Invoke(this, new PairingStatusEventArgs(pairCode, keyId, clientPublicKey, deviceName));

            var response = new
            {
                type = "mg_pairing_ack",
                keyId
            };
            var bytes = JsonSerializer.SerializeToUtf8Bytes(response);
            _client.Send(bytes, bytes.Length, result.RemoteEndPoint);
            return true;
        }
        catch (Exception)
        {
            return false;
        }
    }

    private GamepadPacket? ParsePacket(byte[] buffer)
    {
        var json = Encoding.UTF8.GetString(buffer);
        if (_sessionKey != null)
        {
            try
            {
                var decrypted = CryptoUtils.TryDecrypt(json, _sessionKey);
                if (decrypted != null)
                {
                    return decrypted;
                }
            }
            catch (Exception)
            {
                return null;
            }
        }

        if (_sharedSecret != null)
        {
            try
            {
                var decrypted = CryptoUtils.TryDecrypt(json, _sharedSecret);
                if (decrypted != null)
                {
                    return decrypted;
                }
            }
            catch (Exception)
            {
                return null;
            }
        }

        return JsonSerializer.Deserialize<GamepadPacket>(buffer, new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true
        });
    }

    private void UpdateLatency(GamepadPacket packet)
    {
        if (packet.Timestamp is null)
        {
            return;
        }

        var nowMs = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
        var latency = Math.Max(0, nowMs - packet.Timestamp.Value);
        _lastLatencyMs = latency;
        LatencyUpdated?.Invoke(this, latency);
    }
}
