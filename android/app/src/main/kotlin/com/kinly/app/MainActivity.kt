package com.kinly.app

import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// local_auth (sblocco biometrico) richiede una FlutterFragmentActivity su
// Android invece della normale FlutterActivity.
class MainActivity : FlutterFragmentActivity() {
    private val channelName = "com.kinly.app/battery"

    // Non esposto da geolocator/home_widget: un canale nativo minimo per
    // capire se Android sta già "addormentando" Kinly in background
    // (Doze/App Standby) e per aprire la schermata di sistema dove
    // escluderla, invece di lasciare che il tracciamento smetta di
    // funzionare in silenzio su telefoni con una gestione batteria
    // aggressiva (Samsung, Xiaomi, Huawei e simili sono i casi peggiori:
    // vedi dontkillmyapp.com).
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "isIgnoringBatteryOptimizations" -> result.success(isIgnoringBatteryOptimizations())
                "requestIgnoreBatteryOptimizations" -> {
                    requestIgnoreBatteryOptimizations()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        val powerManager = getSystemService(POWER_SERVICE) as? PowerManager ?: return true
        return powerManager.isIgnoringBatteryOptimizations(packageName)
    }

    private fun requestIgnoreBatteryOptimizations() {
        try {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, Uri.parse("package:$packageName"))
            startActivity(intent)
        } catch (_: Exception) {
            // Alcuni produttori (es. alcuni MIUI/Xiaomi) non implementano
            // questa schermata di sistema standard: si ripiega sulle
            // impostazioni app generiche invece di far crashare l'app.
            try {
                startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName")))
            } catch (_: Exception) {
                // Va bene rinunciare: non è un'operazione critica per l'app.
            }
        }
    }
}
