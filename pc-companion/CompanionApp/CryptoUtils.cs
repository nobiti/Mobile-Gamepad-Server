using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

namespace CompanionApp;

public static class CryptoUtils
{
    public static GamepadPacket? TryDecrypt(string json, string sharedSecret)
    {
        var key = NormalizeKey(sharedSecret);
        return TryDecrypt(json, key);
    }

    public static GamepadPacket? TryDecrypt(string json, byte[] key)
    {
        using var document = JsonDocument.Parse(json);
        if (!document.RootElement.TryGetProperty("type", out var typeElement))
        {
            return null;
        }

        if (typeElement.GetString() != "gamepad_encrypted")
        {
            return null;
        }

        if (!document.RootElement.TryGetProperty("nonce", out var nonceElement))
        {
            return null;
        }

        if (!document.RootElement.TryGetProperty("payload", out var payloadElement))
        {
            return null;
        }

        var nonce = Convert.FromBase64String(nonceElement.GetString() ?? string.Empty);
        var cipherText = Convert.FromBase64String(payloadElement.GetString() ?? string.Empty);
        var plainText = new byte[cipherText.Length];
        using var aes = new AesGcm(NormalizeKey(key));
        aes.Decrypt(nonce, cipherText, plainText, null);

        var decoded = Encoding.UTF8.GetString(plainText).TrimEnd('\0');
        return JsonSerializer.Deserialize<GamepadPacket>(decoded, new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true
        });
    }

    public static byte[] NormalizeKey(string sharedSecret) => NormalizeKey(Encoding.UTF8.GetBytes(sharedSecret));

    public static byte[] NormalizeKey(byte[] keyBytes)
    {
        if (keyBytes.Length == 32)
        {
            return keyBytes;
        }

        if (keyBytes.Length > 32)
        {
            return keyBytes[..32];
        }

        return keyBytes.Concat(new byte[32 - keyBytes.Length]).ToArray();
    }
}
