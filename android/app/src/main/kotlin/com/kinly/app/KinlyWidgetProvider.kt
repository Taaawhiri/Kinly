package com.kinly.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Widget schermata home: mostra fino a tre membri della cerchia con la loro
 * ultima posizione, aggiornati dall'app (plugin home_widget) ad ogni
 * refresh dei dati. Ogni riga ha un pallino colorato "avatar" (il colore
 * vero della persona) accanto al testo, per essere più visivo di un
 * semplice elenco — coerente con lo stile a pallini usato nei mockup del
 * sito. Toccare il widget apre Kinly.
 *
 * Quando nessuno condivide ancora (isPreview = "1"), testo e colori
 * trasmessi da Flutter sono un esempio finto invece dei dati reali (vedi
 * HomeWidgetService.update): qui il testo è mostrato in grigio così è
 * chiaro anche visivamente che non è una posizione vera, ma un'anteprima
 * di come apparirà il widget appena qualcuno condivide.
 */
class KinlyWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val prefs = HomeWidgetPlugin.getData(context)
        val isPreview = prefs.getString("isPreview", "0") == "1"
        val textColor = if (isPreview) 0xFF8A93A6.toInt() else 0xFF222533.toInt()

        val line1 = prefs.getString("line1", "Apri l'app per aggiornare") ?: ""
        val line2 = prefs.getString("line2", "") ?: ""
        val line3 = prefs.getString("line3", "") ?: ""
        val dotColor1 = parseDotColor(prefs.getString("line1Color", null))
        val dotColor2 = parseDotColor(prefs.getString("line2Color", null))
        val dotColor3 = parseDotColor(prefs.getString("line3Color", null))

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.kinly_widget)

            views.setTextViewText(R.id.widget_title, prefs.getString("title", "Kinly") ?: "Kinly")
            views.setTextViewText(R.id.widget_line1, line1)
            views.setTextViewText(R.id.widget_line2, line2)
            views.setTextViewText(R.id.widget_line3, line3)
            views.setTextColor(R.id.widget_line1, textColor)
            views.setTextColor(R.id.widget_line2, textColor)
            views.setTextColor(R.id.widget_line3, textColor)
            views.setInt(R.id.widget_dot1, "setColorFilter", dotColor1)
            views.setInt(R.id.widget_dot2, "setColorFilter", dotColor2)
            views.setInt(R.id.widget_dot3, "setColorFilter", dotColor3)

            // La prima riga c'è sempre (anche solo con l'avviso "nessuno
            // condivide"); la seconda e la terza si nascondono del tutto se
            // non c'è niente da mostrarci, invece di lasciare un pallino
            // colorato accanto a una riga vuota.
            views.setViewVisibility(R.id.widget_row2, if (line2.isEmpty()) View.GONE else View.VISIBLE)
            views.setViewVisibility(R.id.widget_row3, if (line3.isEmpty()) View.GONE else View.VISIBLE)

            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                val pending = PendingIntent.getActivity(
                    context, 0, launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                views.setOnClickPendingIntent(R.id.widget_root, pending)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
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
