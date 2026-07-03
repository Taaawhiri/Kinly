package com.kinly.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
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
 * refresh dei dati. Ogni riga ha un pallino colorato "avatar" accanto al
 * contenuto, come nei mockup del sito. Toccarlo apre Kinly.
 *
 * Quando nessuno condivide ancora (isPreview = "1" da Flutter, vedi
 * HomeWidgetService), invece di un testo di esempio mostriamo due righe
 * puramente visive: pallino colorato + barra grigia astratta al posto del
 * testo, la stessa illustrazione usata per spiegare la funzione sul sito —
 * fa capire a colpo d'occhio come apparirà il widget, senza bisogno di
 * leggere un esempio scritto.
 */
class KinlyWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val prefs = HomeWidgetPlugin.getData(context)
        val isPreview = prefs.getString("isPreview", "0") == "1"

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.kinly_widget)
            views.setTextViewText(R.id.widget_title, prefs.getString("title", "Kinly") ?: "Kinly")

            if (isPreview) {
                // Due righe puramente illustrative (pallino + barra), niente
                // testo: rappresentano genericamente "qui comparirà chi
                // condivide", non un esempio specifico da leggere.
                setPreviewRow(views, dotId = R.id.widget_dot1, lineId = R.id.widget_line1, barId = R.id.widget_bar1, rowId = R.id.widget_row1, color = 0xFF4A63E7.toInt())
                setPreviewRow(views, dotId = R.id.widget_dot2, lineId = R.id.widget_line2, barId = R.id.widget_bar2, rowId = R.id.widget_row2, color = 0xFFFF6B6B.toInt())
                views.setViewVisibility(R.id.widget_row3, View.GONE)
            } else {
                val line1 = prefs.getString("line1", "") ?: ""
                val line2 = prefs.getString("line2", "") ?: ""
                val line3 = prefs.getString("line3", "") ?: ""
                setDataRow(views, rowId = R.id.widget_row1, dotId = R.id.widget_dot1, lineId = R.id.widget_line1, barId = R.id.widget_bar1, text = line1, colorHex = prefs.getString("line1Color", null))
                setDataRow(views, rowId = R.id.widget_row2, dotId = R.id.widget_dot2, lineId = R.id.widget_line2, barId = R.id.widget_bar2, text = line2, colorHex = prefs.getString("line2Color", null))
                setDataRow(views, rowId = R.id.widget_row3, dotId = R.id.widget_dot3, lineId = R.id.widget_line3, barId = R.id.widget_bar3, text = line3, colorHex = prefs.getString("line3Color", null))
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

    private fun setPreviewRow(views: RemoteViews, dotId: Int, lineId: Int, barId: Int, rowId: Int, color: Int) {
        views.setViewVisibility(rowId, View.VISIBLE)
        views.setViewVisibility(lineId, View.GONE)
        views.setViewVisibility(barId, View.VISIBLE)
        views.setInt(dotId, "setColorFilter", color)
    }

    /** Nasconde la riga intera se non c'è nessun testo da mostrarci (meno
     *  di 3 persone condividono), invece di lasciare un pallino sospeso. */
    private fun setDataRow(views: RemoteViews, rowId: Int, dotId: Int, lineId: Int, barId: Int, text: String, colorHex: String?) {
        if (text.isEmpty()) {
            views.setViewVisibility(rowId, View.GONE)
            return
        }
        views.setViewVisibility(rowId, View.VISIBLE)
        views.setViewVisibility(barId, View.GONE)
        views.setViewVisibility(lineId, View.VISIBLE)
        views.setTextViewText(lineId, text)
        views.setTextColor(lineId, 0xFF222533.toInt())
        views.setInt(dotId, "setColorFilter", parseDotColor(colorHex))
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
