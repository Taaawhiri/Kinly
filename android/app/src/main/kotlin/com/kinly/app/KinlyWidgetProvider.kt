package com.kinly.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Widget schermata home: mostra fino a tre membri della cerchia con la loro
 * ultima posizione, aggiornati dall'app (plugin home_widget) ad ogni
 * refresh dei dati. Ogni riga ha un "avatar" (pallino colorato con sopra la
 * sagoma di una persona) più nome in grassetto e indirizzo/orario sotto in
 * grigio, separate da una sottile linea divisoria. Toccare una riga apre
 * Kinly centrato su quella persona; toccare altrove apre l'app e basta.
 *
 * Se l'utente ha più di una cerchia, sotto il titolo compare il nome della
 * cerchia mostrata con due frecce per passare alla precedente/successiva:
 * un tocco lì manda un broadcast diretto a questo provider (vedi
 * [onReceive]), che cambia l'indice salvato e ridisegna subito — nessun
 * bisogno di aprire l'app per sfogliare le cerchie.
 *
 * Quando la cerchia mostrata non ha ancora nessuno che condivide (isPreview
 * = "1" da Flutter, vedi HomeWidgetService), invece di un testo di esempio
 * mostriamo righe puramente visive: pallino colorato + due barre grigie
 * astratte al posto del testo, la stessa illustrazione usata per spiegare
 * la funzione sul sito.
 */
class KinlyWidgetProvider : AppWidgetProvider() {
    companion object {
        private const val ACTION_PREV_CIRCLE = "com.kinly.app.WIDGET_CIRCLE_PREV"
        private const val ACTION_NEXT_CIRCLE = "com.kinly.app.WIDGET_CIRCLE_NEXT"
        private const val SELECTED_CIRCLE_KEY = "widget_selected_circle_index"
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_PREV_CIRCLE -> {
                shiftCircle(context, -1)
                return
            }
            ACTION_NEXT_CIRCLE -> {
                shiftCircle(context, 1)
                return
            }
        }
        super.onReceive(context, intent)
    }

    /** Cambia la cerchia mostrata (con giro completo ai due estremi) e
     *  ridisegna subito tutte le istanze del widget, senza aspettare il
     *  prossimo aggiornamento periodico del sistema. */
    private fun shiftCircle(context: Context, delta: Int) {
        val prefs = HomeWidgetPlugin.getData(context)
        val count = prefs.getString("circleCount", "0")?.toIntOrNull() ?: 0
        if (count <= 1) return
        val current = prefs.getInt(SELECTED_CIRCLE_KEY, 0).coerceIn(0, count - 1)
        prefs.edit().putInt(SELECTED_CIRCLE_KEY, (current + delta + count) % count).apply()

        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(ComponentName(context, KinlyWidgetProvider::class.java))
        onUpdate(context, manager, ids)
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val prefs = HomeWidgetPlugin.getData(context)
        val locked = prefs.getString("locked", "0") == "1"
        val circleCount = if (locked) 0 else prefs.getString("circleCount", "0")?.toIntOrNull() ?: 0
        val circleIndex = if (circleCount <= 0) 0 else prefs.getInt(SELECTED_CIRCLE_KEY, 0).coerceIn(0, circleCount - 1)
        // Nessuna cerchia: l'utente non ne ha ancora creata/joinata una,
        // niente da mostrare al posto del nome (diverso dal caso "cerchia
        // vuota", dove il nome resta visibile e sono le righe sotto ad
        // essere illustrative).
        val isPreview = circleCount <= 0 || prefs.getString("c${circleIndex}_isPreview", "1") == "1"

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.kinly_widget)
            views.setTextViewText(R.id.widget_title, prefs.getString("title", "Kinly") ?: "Kinly")

            if (locked) {
                // Funzione Kinly+: niente nome di cerchia né righe persona,
                // solo l'invito a sbloccare. Un tocco apre l'app dritta
                // sulla pagina di Kinly+ (kinly://paywall). Le scorciatoie
                // SOS/aiuto/accompagnami restano comunque attive più sotto:
                // sono funzioni di sicurezza gratuite, non legate a Kinly+.
                views.setViewVisibility(R.id.widget_circle_row, View.GONE)
                views.setViewVisibility(R.id.widget_content_frame, View.GONE)
                views.setViewVisibility(R.id.widget_locked_group, View.VISIBLE)
                views.setTextViewText(R.id.widget_locked_title, prefs.getString("lockedTitle", "Kinly+") ?: "Kinly+")
                views.setTextViewText(R.id.widget_locked_subtitle, prefs.getString("lockedSubtitle", "") ?: "")
                views.setOnClickPendingIntent(
                    R.id.widget_locked_group,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("kinly://paywall")),
                )
            } else {
                views.setViewVisibility(R.id.widget_locked_group, View.GONE)
                views.setViewVisibility(R.id.widget_content_frame, View.VISIBLE)

                if (circleCount <= 0) {
                    views.setViewVisibility(R.id.widget_circle_row, View.GONE)
                } else {
                    views.setViewVisibility(R.id.widget_circle_row, View.VISIBLE)
                    views.setTextViewText(R.id.widget_circle_name, prefs.getString("circleName$circleIndex", "") ?: "")
                    val showArrows = if (circleCount > 1) View.VISIBLE else View.INVISIBLE
                    views.setViewVisibility(R.id.widget_circle_prev, showArrows)
                    views.setViewVisibility(R.id.widget_circle_next, showArrows)
                    if (circleCount > 1) {
                        views.setOnClickPendingIntent(R.id.widget_circle_prev, circleNavPendingIntent(context, ACTION_PREV_CIRCLE, 10))
                        views.setOnClickPendingIntent(R.id.widget_circle_next, circleNavPendingIntent(context, ACTION_NEXT_CIRCLE, 11))
                    }
                }

                if (isPreview) {
                    // Righe puramente illustrative (pallino + barre), niente
                    // testo: rappresentano genericamente "qui comparirà chi
                    // condivide", non un esempio specifico da leggere.
                    views.setViewVisibility(R.id.widget_solo_group, View.GONE)
                    views.setViewVisibility(R.id.widget_rows_group, View.VISIBLE)
                    setPreviewRow(
                        views, context,
                        rowId = R.id.widget_row1, dotId = R.id.widget_dot1,
                        textGroupId = R.id.widget_text_group1, barsGroupId = R.id.widget_bars_group1,
                        color = 0xFF4A63E7.toInt(),
                    )
                    setPreviewRow(
                        views, context,
                        rowId = R.id.widget_row2, dotId = R.id.widget_dot2,
                        textGroupId = R.id.widget_text_group2, barsGroupId = R.id.widget_bars_group2,
                        color = 0xFFFF6B6B.toInt(),
                    )
                    views.setViewVisibility(R.id.widget_row3, View.GONE)
                    views.setViewVisibility(R.id.widget_divider3, View.GONE)
                } else {
                    val prefix = "c${circleIndex}_"
                    val name1 = prefs.getString("${prefix}name1", "") ?: ""
                    val name2 = prefs.getString("${prefix}name2", "") ?: ""
                    val name3 = prefs.getString("${prefix}name3", "") ?: ""
                    val shownCount = listOf(name1, name2, name3).count { it.isNotEmpty() }

                    if (shownCount == 1) {
                        // Una sola persona: mostrarla piccola in un angolo di
                        // una card che può essere anche molto grande (l'utente
                        // può ridimensionare il widget a piacere) lasciava un
                        // vuoto enorme intorno. Qui la mostriamo invece grande
                        // e centrata, l'unica cosa da guardare.
                        views.setViewVisibility(R.id.widget_rows_group, View.GONE)
                        views.setViewVisibility(R.id.widget_solo_group, View.VISIBLE)
                        views.setTextViewText(R.id.widget_solo_name, name1)
                        views.setTextViewText(R.id.widget_solo_sub, prefs.getString("${prefix}sub1", "") ?: "")
                        val soloBattery = prefs.getString("${prefix}battery1", "") ?: ""
                        views.setTextViewText(R.id.widget_solo_battery, soloBattery)
                        views.setViewVisibility(R.id.widget_solo_battery, if (soloBattery.isEmpty()) View.GONE else View.VISIBLE)
                        views.setInt(R.id.widget_solo_dot, "setColorFilter", parseDotColor(prefs.getString("${prefix}color1", null)))
                        val personId = prefs.getString("${prefix}id1", null)
                        if (!personId.isNullOrEmpty()) {
                            views.setOnClickPendingIntent(
                                R.id.widget_solo_group,
                                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("kinly://person/$personId")),
                            )
                        }
                    } else {
                        views.setViewVisibility(R.id.widget_solo_group, View.GONE)
                        views.setViewVisibility(R.id.widget_rows_group, View.VISIBLE)
                        setDataRow(
                            views, context,
                            rowId = R.id.widget_row1, dividerId = null, dotId = R.id.widget_dot1,
                            textGroupId = R.id.widget_text_group1, barsGroupId = R.id.widget_bars_group1,
                            nameId = R.id.widget_name1, subId = R.id.widget_sub1, batteryId = R.id.widget_battery1,
                            name = name1, sub = prefs.getString("${prefix}sub1", "") ?: "", battery = prefs.getString("${prefix}battery1", "") ?: "",
                            personId = prefs.getString("${prefix}id1", null), colorHex = prefs.getString("${prefix}color1", null),
                        )
                        setDataRow(
                            views, context,
                            rowId = R.id.widget_row2, dividerId = R.id.widget_divider2, dotId = R.id.widget_dot2,
                            textGroupId = R.id.widget_text_group2, barsGroupId = R.id.widget_bars_group2,
                            nameId = R.id.widget_name2, subId = R.id.widget_sub2, batteryId = R.id.widget_battery2,
                            name = name2, sub = prefs.getString("${prefix}sub2", "") ?: "", battery = prefs.getString("${prefix}battery2", "") ?: "",
                            personId = prefs.getString("${prefix}id2", null), colorHex = prefs.getString("${prefix}color2", null),
                        )
                        setDataRow(
                            views, context,
                            rowId = R.id.widget_row3, dividerId = R.id.widget_divider3, dotId = R.id.widget_dot3,
                            textGroupId = R.id.widget_text_group3, barsGroupId = R.id.widget_bars_group3,
                            nameId = R.id.widget_name3, subId = R.id.widget_sub3, batteryId = R.id.widget_battery3,
                            name = name3, sub = prefs.getString("${prefix}sub3", "") ?: "", battery = prefs.getString("${prefix}battery3", "") ?: "",
                            personId = prefs.getString("${prefix}id3", null), colorHex = prefs.getString("${prefix}color3", null),
                        )
                    }
                }
            }

            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                val pending = PendingIntent.getActivity(
                    context, 0, launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                views.setOnClickPendingIntent(R.id.widget_root, pending)
            }

            // Scorciatoie SOS / richiesta aiuto / accompagnami: aprono l'app
            // con un URI (kinly://sos, .../help, .../walk) che map_home_screen.dart
            // legge per mostrare la STESSA conferma dei pulsanti in app, mai
            // per attivare qualcosa direttamente da qui — un tocco accidentale
            // sul widget in tasca non deve poter far scattare un SOS vero.
            views.setOnClickPendingIntent(
                R.id.widget_btn_sos,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("kinly://sos")),
            )
            views.setOnClickPendingIntent(
                R.id.widget_btn_help,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("kinly://help")),
            )
            views.setOnClickPendingIntent(
                R.id.widget_btn_walk,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("kinly://walk")),
            )

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    /** Broadcast esplicito diretto a questo stesso provider (non un Intent
     *  che apre l'app): cambia solo l'indice salvato e ridisegna, restando
     *  nella schermata home. requestCode diverso da azione a azione per
     *  evitare che Android confonda i due PendingIntent tra loro. */
    private fun circleNavPendingIntent(context: Context, action: String, requestCode: Int): PendingIntent {
        val intent = Intent(context, KinlyWidgetProvider::class.java).apply { this.action = action }
        return PendingIntent.getBroadcast(context, requestCode, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }

    private fun setPreviewRow(views: RemoteViews, context: Context, rowId: Int, dotId: Int, textGroupId: Int, barsGroupId: Int, color: Int) {
        views.setViewVisibility(rowId, View.VISIBLE)
        views.setViewVisibility(textGroupId, View.GONE)
        views.setViewVisibility(barsGroupId, View.VISIBLE)
        views.setInt(dotId, "setColorFilter", color)
        // In anteprima non c'è nessuna persona vera su cui centrare la mappa:
        // il tocco sulla riga apre semplicemente l'app, come il resto del widget.
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        if (launchIntent != null) {
            views.setOnClickPendingIntent(
                rowId,
                PendingIntent.getActivity(context, 0, launchIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE),
            )
        }
    }

    /** Nasconde la riga (e la linea divisoria sopra di lei) se non c'è
     *  nessun nome da mostrarci (meno di 3 persone condividono), invece di
     *  lasciare un avatar sospeso. Toccare una riga con una persona vera
     *  apre l'app centrata su di lei (kinly://person/<id>, letto da
     *  map_home_screen.dart), non solo l'app in generale. */
    private fun setDataRow(
        views: RemoteViews,
        context: Context,
        rowId: Int,
        dividerId: Int?,
        dotId: Int,
        textGroupId: Int,
        barsGroupId: Int,
        nameId: Int,
        subId: Int,
        batteryId: Int,
        name: String,
        sub: String,
        battery: String,
        personId: String?,
        colorHex: String?,
    ) {
        if (name.isEmpty()) {
            views.setViewVisibility(rowId, View.GONE)
            if (dividerId != null) views.setViewVisibility(dividerId, View.GONE)
            return
        }
        views.setViewVisibility(rowId, View.VISIBLE)
        if (dividerId != null) views.setViewVisibility(dividerId, View.VISIBLE)
        views.setViewVisibility(barsGroupId, View.GONE)
        views.setViewVisibility(textGroupId, View.VISIBLE)
        views.setTextViewText(nameId, name)
        views.setTextViewText(subId, sub)
        views.setTextViewText(batteryId, battery)
        views.setViewVisibility(batteryId, if (battery.isEmpty()) View.GONE else View.VISIBLE)
        views.setInt(dotId, "setColorFilter", parseDotColor(colorHex))
        if (!personId.isNullOrEmpty()) {
            views.setOnClickPendingIntent(
                rowId,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("kinly://person/$personId")),
            )
        }
    }

    /** Non deve mai far crashare il widget per un colore scritto male. */
    private fun parseDotColor(hex: String?): Int {
        if (hex.isNullOrEmpty()) return 0xFF4A63E7.toInt()
        return try {
            Color.parseColor(hex)
        } catch (_: IllegalArgumentException) {
            0xFF4A63E7.toInt()
        }
    }
}
