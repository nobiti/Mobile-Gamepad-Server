package com.example.mobilegamepad

data class NetworkConfig(
    val host: String,
    val port: Int,
    val sharedSecret: String?,
    val sessionKey: ByteArray? = null,
    val keyId: String? = null
)
