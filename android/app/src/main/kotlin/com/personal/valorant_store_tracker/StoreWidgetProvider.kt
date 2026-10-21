package com.personal.valorant_store_tracker

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class StoreWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.store_widget)

            views.setTextViewText(
                R.id.widget_reset,
                widgetData.getString("store_reset_label", "Not synced"),
            )
            views.setTextViewText(
                R.id.widget_summary,
                widgetData.getString(
                    "store_summary",
                    "Open the app to sync your store",
                ),
            )

            val itemIds = listOf(
                R.id.widget_item_1,
                R.id.widget_item_2,
                R.id.widget_item_3,
                R.id.widget_item_4,
            )
            itemIds.forEachIndexed { index, viewId ->
                val line = widgetData.getString("store_item_${index + 1}", null)
                if (line.isNullOrBlank()) {
                    views.setViewVisibility(viewId, View.GONE)
                } else {
                    views.setViewVisibility(viewId, View.VISIBLE)
                    views.setTextViewText(viewId, line)
                }
            }

            val nightMarket = widgetData.getString("store_night_market", null)
            if (nightMarket.isNullOrBlank()) {
                views.setViewVisibility(R.id.widget_night_market, View.GONE)
            } else {
                views.setViewVisibility(R.id.widget_night_market, View.VISIBLE)
                views.setTextViewText(R.id.widget_night_market, nightMarket)
            }

            views.setTextViewText(
                R.id.widget_updated,
                widgetData.getString("store_updated_label", ""),
            )

            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
