using System.Security.Cryptography;

namespace CompanionApp;

public sealed class PairingSession : IDisposable
{
    private ECDiffieHellman? _keyPair;

    public string KeyId { get; private set; } = Guid.NewGuid().ToString("N");
    public string PublicKeyBase64 { get; private set; } = string.Empty;

    public PairingSession()
    {
        Rotate();
    }

    public void Rotate()
    {
        _keyPair?.Dispose();
        _keyPair = KeyExchangeUtils.CreateKeyPair();
        KeyId = Guid.NewGuid().ToString("N");
        PublicKeyBase64 = KeyExchangeUtils.ExportPublicKey(_keyPair);
    }

    public byte[] DeriveSessionKey(string clientPublicKeyBase64)
    {
        if (_keyPair == null)
        {
            throw new InvalidOperationException("Pairing keypair not initialized.");
        }
        return KeyExchangeUtils.DeriveSessionKey(_keyPair, clientPublicKeyBase64, KeyId);
    }

    public void Dispose()
    {
        _keyPair?.Dispose();
    }
}
