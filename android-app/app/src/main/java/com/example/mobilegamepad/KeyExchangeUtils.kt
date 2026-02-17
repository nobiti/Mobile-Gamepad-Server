package com.example.mobilegamepad

import android.util.Base64
import java.security.KeyFactory
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.PrivateKey
import java.security.PublicKey
import java.security.SecureRandom
import java.security.spec.ECGenParameterSpec
import java.security.spec.X509EncodedKeySpec
import javax.crypto.KeyAgreement
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

object KeyExchangeUtils {
    private const val CURVE_NAME = "secp256r1"

    fun generateKeyPair(): KeyPair {
        val generator = KeyPairGenerator.getInstance("EC")
        generator.initialize(ECGenParameterSpec(CURVE_NAME), SecureRandom())
        return generator.generateKeyPair()
    }

    fun publicKeyToBase64(publicKey: PublicKey): String {
        return Base64.encodeToString(publicKey.encoded, Base64.NO_WRAP)
    }

    fun parsePublicKey(base64: String): PublicKey {
        val keyBytes = Base64.decode(base64, Base64.NO_WRAP)
        val spec = X509EncodedKeySpec(keyBytes)
        val factory = KeyFactory.getInstance("EC")
        return factory.generatePublic(spec)
    }

    fun deriveSessionKey(privateKey: PrivateKey, remotePublicKey: PublicKey, keyId: String): ByteArray {
        val agreement = KeyAgreement.getInstance("ECDH")
        agreement.init(privateKey)
        agreement.doPhase(remotePublicKey, true)
        val sharedSecret = agreement.generateSecret()
        val salt = keyId.toByteArray(Charsets.UTF_8)
        return hkdfSha256(sharedSecret, salt, "mobile-gamepad-ecdh".toByteArray(Charsets.UTF_8), 32)
    }

    private fun hkdfSha256(ikm: ByteArray, salt: ByteArray, info: ByteArray, length: Int): ByteArray {
        val prk = hmacSha256(salt, ikm)
        val result = ByteArray(length)
        var t = ByteArray(0)
        var offset = 0
        var counter = 1
        while (offset < length) {
            val mac = Mac.getInstance("HmacSHA256")
            mac.init(SecretKeySpec(prk, "HmacSHA256"))
            mac.update(t)
            mac.update(info)
            mac.update(counter.toByte())
            t = mac.doFinal()
            val toCopy = minOf(t.size, length - offset)
            System.arraycopy(t, 0, result, offset, toCopy)
            offset += toCopy
            counter++
        }
        return result
    }

    private fun hmacSha256(key: ByteArray, data: ByteArray): ByteArray {
        val mac = Mac.getInstance("HmacSHA256")
        mac.init(SecretKeySpec(key, "HmacSHA256"))
        return mac.doFinal(data)
    }
}
