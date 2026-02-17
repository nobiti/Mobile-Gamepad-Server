package com.example.mobilegamepad

import org.json.JSONObject
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress

class DiscoveryClient {
    fun discover(pairCode: String?, timeoutMs: Int = 1500): DiscoveryResult? {
        DatagramSocket().use { socket ->
            socket.broadcast = true
            socket.soTimeout = timeoutMs

            val requestJson = JSONObject()
            requestJson.put("type", "mg_discovery_request")
            requestJson.put("timestamp", System.currentTimeMillis())
            if (!pairCode.isNullOrBlank()) {
                requestJson.put("pairCode", pairCode)
            }
            val requestBytes = requestJson.toString().toByteArray()
            val requestPacket = DatagramPacket(
                requestBytes,
                requestBytes.size,
                InetAddress.getByName(BROADCAST_ADDRESS),
                DISCOVERY_PORT
            )
            socket.send(requestPacket)

            val buffer = ByteArray(2048)
            val responsePacket = DatagramPacket(buffer, buffer.size)
            socket.receive(responsePacket)

            val response = String(responsePacket.data, 0, responsePacket.length)
            val json = JSONObject(response)
            if (json.optString("type") != "mg_discovery_response") {
                return null
            }
            val host = json.optString("host", responsePacket.address.hostAddress)
            val port = json.optInt("port", DEFAULT_STREAM_PORT)
            val publicKey = json.optString("publicKey").ifBlank { null }
            val keyId = json.optString("keyId").ifBlank { null }
            val pairCode = json.optString("pairCode").ifBlank { null }
            return DiscoveryResult(host, port, publicKey, keyId, pairCode)
        }
    }

    companion object {
        const val DISCOVERY_PORT = 9877
        const val DEFAULT_STREAM_PORT = 9876
        private const val BROADCAST_ADDRESS = "255.255.255.255"
    }
}

data class DiscoveryResult(
    val host: String,
    val port: Int,
    val publicKey: String? = null,
    val keyId: String? = null,
    val pairCode: String? = null
)
