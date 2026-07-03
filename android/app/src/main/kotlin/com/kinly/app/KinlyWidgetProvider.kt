package com.kinly.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Widget schermata home: mostra fino a tre membri della cerchia con la loro
 * ultima posizione, aggiornati dall'app (plugin home_widget) ad ogni
 * refresh dei dati. Toccarlo apre Kinly.
 *
 * Quando nessuno condivide ancora (isPreview = "1"), il testo trasmesso da
 * Flutter è un esempio finto invece dei dati reali (vedi
 * HomeWidgetService.update): qui lo mostriamo in grigio così è chiaro
 * anche visivamente che non è una posizione vera, ma un'anteprima di come
 * apparirà il widget appena qualcuno condivide.
 */
class KinlyWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val prefs = HomeWidgetPlugin.getData(context)
        val isPreview = prefs.getString("isPreview", "0") == "1"
        val textColor = if (isPreview) 0xFF8A93A6.toInt() else 0xFF222533.toInt()

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.kinly_widget)

            views.setTextViewText(R.id.widget_title, prefs.getString("title", "Kinly") ?: "Kinly")
            views.setTextViewText(R.id.widget_line1, prefs.getString("line1", "Apri l'app per aggiornare") ?: "")
            views.setTextViewText(R.id.widget_line2, prefs.getString("line2", "") ?: "")
            views.setTextViewText(R.id.widget_line3, prefs.getString("line3", "") ?: "")
            views.setTextColor(R.id.widget_line1, textColor)
            views.setTextColor(R.id.widget_line2, textColor)
            views.setTextColor(R.id.widget_line3, textColor)

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
}
