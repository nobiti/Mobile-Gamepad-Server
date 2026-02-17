package com.example.mobilegamepad

import android.util.Base64
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

object CryptoUtils {
    private const val NONCE_LENGTH = 12
    private const val TAG_LENGTH_BITS = 128

    fun encryptJson(json: String, keyBytes: ByteArray): EncryptedPayload {
        val key = SecretKeySpec(keyBytes.copyOf(32), "AES")
        val nonce = ByteArray(NONCE_LENGTH)
        SecureRandom().nextBytes(nonce)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key, GCMParameterSpec(TAG_LENGTH_BITS, nonce))
        val cipherText = cipher.doFinal(json.toByteArray(Charsets.UTF_8))
        return EncryptedPayload(
            nonce = Base64.encodeToString(nonce, Base64.NO_WRAP),
            payload = Base64.encodeToString(cipherText, Base64.NO_WRAP)
        )
    }

    fun keyFromSharedSecret(sharedSecret: String): ByteArray {
        return sharedSecret.toByteArray(Charsets.UTF_8).copyOf(32)
    }
}

data class EncryptedPayload(
    val nonce: String,
    val payload: String
)
