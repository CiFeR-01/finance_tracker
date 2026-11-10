package com.example.finance_tracker

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.net.ConnectException
import java.net.HttpURLConnection
import java.net.SocketTimeoutException
import java.net.URL
import java.net.UnknownHostException
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.finance_tracker/network_diagnostic"
    private val executor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "runNetworkDiagnostic") {
                executor.execute {
                    val httpResult = performRequest("http://example.com")
                    val httpsResult = performRequest("https://example.com")

                    val resultMap = mapOf(
                        "http" to httpResult,
                        "https" to httpsResult
                    )

                    runOnUiThread {
                        result.success(resultMap)
                    }
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun performRequest(urlString: String): Map<String, Any?> {
        var connection: HttpURLConnection? = null
        try {
            val url = URL(urlString)
            connection = url.openConnection() as HttpURLConnection
            connection.connectTimeout = 8000
            connection.readTimeout = 8000
            connection.instanceFollowRedirects = false
            connection.requestMethod = "GET"

            val responseCode = connection.responseCode
            return mapOf(
                "success" to true,
                "statusCode" to responseCode,
                "errorType" to null,
                "errorMessage" to null,
                "exceptionClass" to null
            )
        } catch (e: Exception) {
            val errorMsg = e.message ?: e.toString()
            val exceptionClass = e.javaClass.name
            val errorType = classifyException(e, errorMsg)

            return mapOf(
                "success" to false,
                "statusCode" to null,
                "errorType" to errorType,
                "errorMessage" to errorMsg,
                "exceptionClass" to exceptionClass
            )
        } finally {
            connection?.disconnect()
        }
    }

    private fun classifyException(e: Exception, message: String): String {
        val lowerMsg = message.lowercase()
        val className = e.javaClass.name.lowercase()
        return when {
            lowerMsg.contains("cleartext") ||
            lowerMsg.contains("not permitted by network security policy") ||
            className.contains("unknownserviceexception") -> "CLEARTEXT_BLOCKED"

            e is SocketTimeoutException || lowerMsg.contains("timeout") -> "TIMEOUT"
            e is UnknownHostException || lowerMsg.contains("unable to resolve host") -> "DNS_FAILURE"
            e is ConnectException || lowerMsg.contains("connection refused") -> "CONNECTION_REFUSED"
            else -> "OTHER_ERROR"
        }
    }
}
