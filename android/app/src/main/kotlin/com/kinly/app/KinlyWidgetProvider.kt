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
 * refresh dei dati. Ogni riga ha un "avatar" (pallino colorato con sopra la
 * sagoma di una persona) più nome in grassetto e indirizzo/orario sotto in
 * grigio, separate da una sottile linea divisoria. Toccare una riga apre
 * Kinly centrato su quella persona; toccare altrove apre l'app e basta.
 *
 * Quando nessuno condivide ancora (isPreview = "1" da Flutter, vedi
 * HomeWidgetService), invece di un testo di esempio mostriamo righe
 * puramente visive: pallino colorato + due barre grigie astratte al posto
 * del testo, la stessa illustrazione usata per spiegare la funzione sul
 * sito — fa capire a colpo d'occhio come apparirà il widget, senza bisogno
 * di leggere un esempio scritto.
 */
class KinlyWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val prefs = HomeWidgetPlugin.getData(context)
        val isPreview = prefs.getString("isPreview", "0") == "1"

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.kinly_widget)
            views.setTextViewText(R.id.widget_title, prefs.getString("title", "Kinly") ?: "Kinly")

            if (isPreview) {
                // Righe puramente illustrative (pallino + barre), niente
                // testo: rappresentano genericamente "qui comparirà chi
                // condivide", non un esempio specifico da leggere.
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
                setDataRow(
                    views, context,
                    rowId = R.id.widget_row1, dividerId = null, dotId = R.id.widget_dot1,
                    textGroupId = R.id.widget_text_group1, barsGroupId = R.id.widget_bars_group1,
                    nameId = R.id.widget_name1, subId = R.id.widget_sub1,
                    name = prefs.getString("name1", "") ?: "", sub = prefs.getString("sub1", "") ?: "",
                    personId = prefs.getString("id1", null), colorHex = prefs.getString("color1", null),
                )
                setDataRow(
                    views, context,
                    rowId = R.id.widget_row2, dividerId = R.id.widget_divider2, dotId = R.id.widget_dot2,
                    textGroupId = R.id.widget_text_group2, barsGroupId = R.id.widget_bars_group2,
                    nameId = R.id.widget_name2, subId = R.id.widget_sub2,
                    name = prefs.getString("name2", "") ?: "", sub = prefs.getString("sub2", "") ?: "",
                    personId = prefs.getString("id2", null), colorHex = prefs.getString("color2", null),
                )
                setDataRow(
                    views, context,
                    rowId = R.id.widget_row3, dividerId = R.id.widget_divider3, dotId = R.id.widget_dot3,
                    textGroupId = R.id.widget_text_group3, barsGroupId = R.id.widget_bars_group3,
                    nameId = R.id.widget_name3, subId = R.id.widget_sub3,
                    name = prefs.getString("name3", "") ?: "", sub = prefs.getString("sub3", "") ?: "",
                    personId = prefs.getString("id3", null), colorHex = prefs.getString("color3", null),
                )
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
        name: String,
        sub: String,
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
