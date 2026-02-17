namespace CompanionApp;

public sealed record DiscoveryResponse(string Host, int Port, string PairCode, string PublicKey, string KeyId);

public sealed record PairingExchangeRequest(string PairCode, string KeyId, string ClientPublicKey, string? DeviceName);

public sealed record PairingExchangeResponse(string KeyId);

public sealed record PairingQrPayload(string Host, int Port, string PairCode, string PublicKey, string KeyId);

public sealed class PairingStatusEventArgs : EventArgs
{
    public PairingStatusEventArgs(string pairCode, string keyId, string clientPublicKey, string? deviceName)
    {
        PairCode = pairCode;
        KeyId = keyId;
        ClientPublicKey = clientPublicKey;
        DeviceName = deviceName;
    }

    public string PairCode { get; }
    public string KeyId { get; }
    public string ClientPublicKey { get; }
    public string? DeviceName { get; }
}

public sealed class GamepadPacket
{
    public Dictionary<string, float>? Axes { get; init; }
    public Dictionary<string, bool>? Buttons { get; init; }
    public string? DeviceName { get; init; }
    public long? Timestamp { get; init; }
}
