package com.skondit.skondit_wearable

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothServerSocket
import android.bluetooth.BluetoothSocket
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.IOException
import java.io.InputStreamReader
import java.nio.charset.StandardCharsets
import java.util.UUID

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "skondit/classic"
        private const val EVENTS = "skondit/classic_events"
        private const val SPP_UUID = "00001101-0000-1000-8000-00805f9b34fb"
    }

    private var serverSocket: BluetoothServerSocket? = null
    private var clientSocket: BluetoothSocket? = null
    private var acceptThread: Thread? = null
    private var readerThread: Thread? = null

    @Volatile
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> startServer(result)
                    "send" -> sendData(call.argument<String>("json"), result)
                    "stop" -> stopServer(result)
                    "makeDiscoverable" -> makeDiscoverable(result)
                    else -> result.notImplemented()
                }
            }
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENTS)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    private fun startServer(result: MethodChannel.Result) {
        try {
            val adapter = BluetoothAdapter.getDefaultAdapter()
            if (!adapter.isEnabled) {
                result.error("BT_OFF", "Bluetooth is off", null)
                return
            }
            adapter.name = "SkonditBeats"
            serverSocket = adapter.listenUsingRfcommWithServiceRecord(
                "SkonditBeats",
                UUID.fromString(SPP_UUID)
            )
            acceptThread = Thread {
                while (!Thread.currentThread().isInterrupted) {
                    try {
                        val socket = serverSocket?.accept() ?: break
                        runOnUiThread {
                            try {
                                clientSocket?.close()
                            } catch (_: IOException) {
                            }
                            clientSocket = socket
                            eventSink?.success("{\"type\":\"conn\",\"connected\":true}")
                        }
                        startReader(socket)
                    } catch (e: IOException) {
                        break
                    }
                }
            }.apply { isDaemon = true }
            acceptThread?.start()
            result.success("listening")
        } catch (e: Exception) {
            result.error("START_FAILED", e.message, null)
        }
    }

    /** Lee las líneas JSON que el teléfono manda por el socket SPP. */
    private fun startReader(socket: BluetoothSocket) {
        readerThread?.interrupt()
        readerThread = Thread {
            try {
                val reader = BufferedReader(
                    InputStreamReader(socket.inputStream, StandardCharsets.UTF_8)
                )
                var line = reader.readLine()
                while (line != null && !Thread.currentThread().isInterrupted) {
                    val msg = line
                    runOnUiThread { eventSink?.success(msg) }
                    line = reader.readLine()
                }
            } catch (_: IOException) {
            }
            runOnUiThread { eventSink?.success("{\"type\":\"conn\",\"connected\":false}") }
        }.apply { isDaemon = true }
        readerThread?.start()
    }

    private fun makeDiscoverable(result: MethodChannel.Result) {
        try {
            startActivity(
                Intent(BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    .putExtra(BluetoothAdapter.EXTRA_DISCOVERABLE_DURATION, 300)
            )
            result.success(true)
        } catch (e: Exception) {
            result.error("DISCOVER_FAILED", e.message, null)
        }
    }

    private fun sendData(json: String?, result: MethodChannel.Result) {
        val socket = clientSocket
        if (socket == null || json == null) {
            result.success(false)
            return
        }
        Thread {
            try {
                socket.outputStream.write((json + "\n").toByteArray())
                socket.outputStream.flush()
                runOnUiThread { result.success(true) }
            } catch (e: IOException) {
                runOnUiThread { result.success(false) }
            }
        }.start()
    }

    private fun stopServer(result: MethodChannel.Result) {
        try {
            acceptThread?.interrupt()
            acceptThread = null
            try {
                clientSocket?.close()
            } catch (_: IOException) {
            }
            clientSocket = null
            try {
                serverSocket?.close()
            } catch (_: IOException) {
            }
            serverSocket = null
            eventSink?.success("{\"type\":\"conn\",\"connected\":false}")
            result.success(true)
        } catch (e: Exception) {
            result.error("STOP_FAILED", e.message, null)
        }
    }

    override fun onDestroy() {
        acceptThread?.interrupt()
        try {
            clientSocket?.close()
        } catch (_: IOException) {
        }
        try {
            serverSocket?.close()
        } catch (_: IOException) {
        }
        super.onDestroy()
    }
}
