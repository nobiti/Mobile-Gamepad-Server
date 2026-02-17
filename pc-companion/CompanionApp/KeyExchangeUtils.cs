using System.Security.Cryptography;
using System.Text;

namespace CompanionApp;

public static class KeyExchangeUtils
{
    public static ECDiffieHellman CreateKeyPair() => ECDiffieHellman.Create(ECCurve.NamedCurves.nistP256);

    public static string ExportPublicKey(ECDiffieHellman keyPair)
    {
        var bytes = keyPair.PublicKey.ExportSubjectPublicKeyInfo();
        return Convert.ToBase64String(bytes);
    }

    public static byte[] DeriveSessionKey(ECDiffieHellman keyPair, string clientPublicKeyBase64, string keyId)
    {
        var clientKeyBytes = Convert.FromBase64String(clientPublicKeyBase64);
        using var clientKey = ECDiffieHellman.Create();
        clientKey.ImportSubjectPublicKeyInfo(clientKeyBytes, out _);
        var sharedSecret = keyPair.DeriveKeyMaterial(clientKey.PublicKey);
        var salt = Encoding.UTF8.GetBytes(keyId);
        return HkdfSha256(sharedSecret, salt, Encoding.UTF8.GetBytes("mobile-gamepad-ecdh"), 32);
    }

    private static byte[] HkdfSha256(byte[] ikm, byte[] salt, byte[] info, int length)
    {
        using var hmac = new HMACSHA256(salt);
        var prk = hmac.ComputeHash(ikm);
        var output = new byte[length];
        var previous = Array.Empty<byte>();
        var offset = 0;
        byte counter = 1;
        while (offset < length)
        {
            using var mac = new HMACSHA256(prk);
            mac.TransformBlock(previous, 0, previous.Length, null, 0);
            mac.TransformBlock(info, 0, info.Length, null, 0);
            mac.TransformFinalBlock(new[] { counter }, 0, 1);
            previous = mac.Hash ?? Array.Empty<byte>();
            var toCopy = Math.Min(previous.Length, length - offset);
            Array.Copy(previous, 0, output, offset, toCopy);
            offset += toCopy;
            counter++;
        }

        return output;
    }
}
