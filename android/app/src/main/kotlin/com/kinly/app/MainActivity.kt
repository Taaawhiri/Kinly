package com.kinly.app

import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Build
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
                "hasManufacturerBatterySettings" -> result.success(hasManufacturerBatterySettings())
                "manufacturerBatterySettingsLabel" -> result.success(manufacturerDisplayName())
                "openManufacturerBatterySettings" -> {
                    openManufacturerBatterySettings()
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

    // Samsung, Xiaomi/Redmi, Huawei/Honor, Oppo/OnePlus e Vivo hanno un
    // secondo livello di gestione batteria/autostart, del tutto separato da
    // PowerManager.isIgnoringBatteryOptimizations: un'app può risultare
    // "esente" per Android e venire comunque messa in sospensione dal
    // produttore. Google (Pixel, Android puro) e Nothing (Nothing OS, molto
    // vicino ad Android puro, nessun layer proprietario noto) non hanno
    // bisogno di niente di tutto questo: l'esenzione standard sopra basta
    // già. Redmi è un marchio di Xiaomi: quasi sempre Build.MANUFACTURER
    // riporta comunque "Xiaomi" anche su un Redmi, ma teniamo l'alias per
    // sicurezza nel caso capiti una ROM che riporti "Redmi" direttamente.
    private fun manufacturerKey(): String = Build.MANUFACTURER.lowercase()

    private val manufacturersWithBatterySettings =
        setOf("samsung", "xiaomi", "redmi", "huawei", "honor", "oppo", "oneplus", "vivo")

    private fun hasManufacturerBatterySettings(): Boolean = manufacturerKey() in manufacturersWithBatterySettings

    private fun manufacturerDisplayName(): String = when (manufacturerKey()) {
        "samsung" -> "Samsung"
        "xiaomi" -> "Xiaomi"
        "redmi" -> "Redmi"
        "huawei" -> "Huawei"
        "honor" -> "Honor"
        "oppo" -> "Oppo"
        "oneplus" -> "OnePlus"
        "vivo" -> "Vivo"
        else -> Build.MANUFACTURER
    }

    // Non esiste un Intent pubblico e documentato per aprire direttamente
    // queste schermate (a differenza di
    // ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, che è AOSP): questi nomi
    // di componente sono noti solo per uso comune tra sviluppatori
    // (dontkillmyapp.com) e non garantiti — possono cambiare o sparire con
    // gli aggiornamenti di sistema, da qui la catena di tentativi con
    // fallback finale sulle impostazioni app standard, mai un errore visibile.
    // Oppo e OnePlus condividono la stessa base (ColorOS/OxygenOS fusi dal
    // 2021): proviamo entrambi i set di nomi noti su entrambi i marchi.
    private fun openManufacturerBatterySettings() {
        val candidates = when (manufacturerKey()) {
            "samsung" -> listOf(
                ComponentName("com.samsung.android.lool", "com.samsung.android.sm.ui.battery.BatteryActivity"),
                ComponentName("com.samsung.android.lool", "com.samsung.android.sm.battery.ui.BatteryActivity"),
            )
            "xiaomi", "redmi" -> listOf(
                ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity"),
                ComponentName("com.miui.powerkeeper", "com.miui.powerkeeper.ui.HiddenAppsConfigActivity"),
            )
            "huawei", "honor" -> listOf(
                ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"),
                ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.optimize.process.ProtectActivity"),
            )
            "oppo", "oneplus" -> listOf(
                ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity"),
                ComponentName("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity"),
                ComponentName("com.oneplus.security", "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity"),
            )
            "vivo" -> listOf(
                ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"),
                ComponentName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity"),
            )
            else -> emptyList()
        }
        for (target in candidates) {
            try {
                val intent = Intent()
                intent.component = target
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                startActivity(intent)
                return
            } catch (_: Exception) {
                // Prova il prossimo componente noto.
            }
        }
        try {
            startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName")))
        } catch (_: Exception) {
            // Va bene rinunciare: non è un'operazione critica per l'app.
        }
    }
}
