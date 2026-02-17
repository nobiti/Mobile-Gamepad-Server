package com.example.mobilegamepad

import org.json.JSONObject

data class QrPairingPayload(
    val host: String,
    val port: Int,
    val pairCode: String,
    val publicKey: String,
    val keyId: String
) {
    companion object {
        fun parse(raw: String): QrPairingPayload? {
            return runCatching {
                val json = JSONObject(raw)
                if (json.optString("type") != "mg_pairing_qr") {
                    return null
                }
                val host = json.optString("host")
                val port = json.optInt("port")
                val pairCode = json.optString("pairCode")
                val publicKey = json.optString("publicKey")
                val keyId = json.optString("keyId")
                if (host.isBlank() || port == 0 || pairCode.isBlank() || publicKey.isBlank() || keyId.isBlank()) {
                    null
                } else {
                    QrPairingPayload(host, port, pairCode, publicKey, keyId)
                }
            }.getOrNull()
        }
    }
}
