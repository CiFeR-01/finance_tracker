package com.example.finance_tracker

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.net.HttpURLConnection
import java.net.URL
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.finance_tracker/network_test"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "testUrl") {
                val urlString = call.argument<String>("url") ?: ""
                thread {
                    try {
                        val url = URL(urlString)
                        val connection = url.openConnection() as HttpURLConnection
                        connection.connectTimeout = 8000
                        connection.readTimeout = 8000
                        connection.requestMethod = "GET"
                        connection.instanceFollowRedirects = true

                        val responseCode = connection.responseCode
                        val responseMessage = connection.responseMessage ?: ""
                        connection.disconnect()

                        val responseData = mapOf(
                            "success" to true,
                            "statusCode" to responseCode,
                            "responseMessage" to responseMessage,
                            "error" to null,
                            "errorClass" to null,
                            "isCleartextBlocked" to false
                        )
                        runOnUiThread {
                            result.success(responseData)
                        }
                    } catch (e: Exception) {
                        val errMsg = e.message ?: e.toString()
                        val errorClass = e.javaClass.name
                        val isCleartextBlocked = errMsg.contains("cleartext", ignoreCase = true) ||
                                                 errMsg.contains("CLEARTEXT", ignoreCase = true) ||
                                                 errMsg.contains("not permitted by network security policy", ignoreCase = true)

                        val responseData = mapOf(
                            "success" to false,
                            "statusCode" to null,
                            "responseMessage" to null,
                            "error" to errMsg,
                            "errorClass" to errorClass,
                            "isCleartextBlocked" to isCleartextBlocked
                        )
                        runOnUiThread {
                            result.success(responseData)
                        }
                    }
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
