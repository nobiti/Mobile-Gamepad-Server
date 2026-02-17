package com.example.mobilegamepad

import org.json.JSONObject
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress

class PairingClient {
    fun exchange(
        host: String,
        port: Int,
        pairCode: String,
        keyId: String,
        clientPublicKey: String,
        deviceName: String,
        timeoutMs: Int = 1500
    ): Boolean {
        DatagramSocket().use { socket ->
            socket.soTimeout = timeoutMs
            val request = JSONObject()
            request.put("type", "mg_pairing_exchange")
            request.put("pairCode", pairCode)
            request.put("keyId", keyId)
            request.put("clientPublicKey", clientPublicKey)
            request.put("deviceName", deviceName)
            val bytes = request.toString().toByteArray()
            val packet = DatagramPacket(bytes, bytes.size, InetAddress.getByName(host), port)
            socket.send(packet)

            val buffer = ByteArray(1024)
            val responsePacket = DatagramPacket(buffer, buffer.size)
            socket.receive(responsePacket)
            val response = String(responsePacket.data, 0, responsePacket.length)
            val json = JSONObject(response)
            return json.optString("type") == "mg_pairing_ack" && json.optString("keyId") == keyId
        }
    }
}
