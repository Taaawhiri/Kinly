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
 */
class KinlyWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val prefs = HomeWidgetPlugin.getData(context)
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.kinly_widget)

            views.setTextViewText(R.id.widget_title, prefs.getString("title", "Kinly") ?: "Kinly")
            views.setTextViewText(R.id.widget_line1, prefs.getString("line1", "Apri l'app per aggiornare") ?: "")
            views.setTextViewText(R.id.widget_line2, prefs.getString("line2", "") ?: "")
            views.setTextViewText(R.id.widget_line3, prefs.getString("line3", "") ?: "")

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
