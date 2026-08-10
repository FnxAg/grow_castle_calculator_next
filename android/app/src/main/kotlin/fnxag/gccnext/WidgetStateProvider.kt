package fnxag.gccnext

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import org.json.JSONObject
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone

/**
 * 桌面小组件：展示当前用户的总波数 / 赛季波数 / 在线情况（实时）。
 *
 * 数据来源分两层：
 * 1. 快照兜底：Dart 侧写入的 widget_state.json（context.filesDir，见
 *    lib/data/store/widget_snapshot.dart），提供用户名与最近一次已知数据；
 * 2. 实时抓取：读快照用户名后，后台线程直接请求服务器（URL 构造/响应
 *    解析/在线时间格式化与 lib/core/service/api.dart 的 _queryPlayer、
 *    formatLastOnline 一一对应），成功后用实时数据覆盖渲染；失败保留快照值。
 *
 * 刷新时机：
 * - 系统每 30 分钟发 APPWIDGET_UPDATE（appwidget-provider 的
 *   updatePeriodMillis 下限，无需任何权限/闹钟）；
 * - 小组件上的刷新按钮 → 组件显式广播 [ACTION_REFRESH] 立即抓取。
 */
class WidgetStateProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, appWidgetIds: IntArray) {
        // 手动广播（adb 测试）时可能不带 appWidgetIds extra：回退到全部实例
        val ids = if (appWidgetIds.isEmpty()) {
            manager.getAppWidgetIds(ComponentName(context, WidgetStateProvider::class.java))
        } else {
            appWidgetIds
        }
        ids.forEach { updateWidget(context, manager, it) }
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_REFRESH) {
            val manager = AppWidgetManager.getInstance(context)
            val id = intent.getIntExtra(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID
            )
            val targets = if (id != AppWidgetManager.INVALID_APPWIDGET_ID) {
                intArrayOf(id)
            } else {
                manager.getAppWidgetIds(ComponentName(context, WidgetStateProvider::class.java))
            }
            targets.forEach { updateWidget(context, manager, it, showLoading = true) }
            return
        }
        super.onReceive(context, intent)
    }

    private fun updateWidget(
        context: Context,
        manager: AppWidgetManager,
        appWidgetId: Int,
        showLoading: Boolean = false,
    ) {
        val snapshot = readSnapshot(context)
        val dash = context.getString(R.string.widget_dash)

        if (snapshot == null || snapshot.username.isEmpty()) {
            // 未打开过应用 / 快照缺失：占位态（点击仍可打开应用）
            val views = buildViews(context, appWidgetId)
            views.setTextViewText(
                R.id.widget_username,
                context.getString(R.string.widget_placeholder_username)
            )
            views.setTextViewText(R.id.widget_last_online, dash)
            views.setTextViewText(R.id.widget_wave, dash)
            views.setTextViewText(R.id.widget_season_wave, dash)
            manager.updateAppWidget(appWidgetId, views)
            return
        }

        if (snapshot.isDefault) {
            // 默认用户：占位账号无真实数据，服务器上也不存在该玩家，
            // 不联网抓取，直接显示引导态（点击仍可打开应用创建账号）
            val views = buildViews(context, appWidgetId)
            views.setTextViewText(
                R.id.widget_username,
                context.getString(R.string.widget_default_username)
            )
            views.setTextViewText(
                R.id.widget_last_online,
                context.getString(R.string.widget_default_user_hint)
            )
            views.setTextViewText(R.id.widget_wave, dash)
            views.setTextViewText(R.id.widget_season_wave, dash)
            manager.updateAppWidget(appWidgetId, views)
            return
        }

        if (showLoading) {
            // 手动刷新：先显示「刷新中」，避免闪出快照旧数据
            val loading = buildViews(context, appWidgetId)
            loading.setTextViewText(R.id.widget_username, snapshot.username)
            loading.setTextViewText(
                R.id.widget_last_online,
                context.getString(R.string.widget_refreshing)
            )
            loading.setTextViewText(
                R.id.widget_wave,
                context.getString(R.string.widget_ellipsis)
            )
            loading.setTextViewText(
                R.id.widget_season_wave,
                context.getString(R.string.widget_ellipsis)
            )
            manager.updateAppWidget(appWidgetId, loading)
        } else {
            // 系统定时刷新：先展示快照数据（快），再后台抓取覆盖
            val views = buildViews(context, appWidgetId)
            views.setTextViewText(R.id.widget_username, snapshot.username)
            views.setTextViewText(R.id.widget_last_online, snapshot.lastOnline.ifEmpty { dash })
            views.setTextViewText(R.id.widget_wave, snapshot.wave.toString())
            views.setTextViewText(R.id.widget_season_wave, snapshot.seasonWave.toString())
            manager.updateAppWidget(appWidgetId, views)
        }

        Thread {
            val fresh = fetchPlayer(snapshot.username)
            val resultViews = buildViews(context, appWidgetId)
            resultViews.setTextViewText(R.id.widget_username, snapshot.username)
            if (fresh == null) {
                // 抓取失败：加载态恢复快照数据（定时刷新本就显示快照，无需处理）
                if (showLoading) {
                    resultViews.setTextViewText(
                        R.id.widget_last_online,
                        snapshot.lastOnline.ifEmpty { dash }
                    )
                    resultViews.setTextViewText(R.id.widget_wave, snapshot.wave.toString())
                    resultViews.setTextViewText(
                        R.id.widget_season_wave,
                        snapshot.seasonWave.toString()
                    )
                    manager.updateAppWidget(appWidgetId, resultViews)
                }
                return@Thread
            }
            resultViews.setTextViewText(R.id.widget_last_online, fresh.lastOnline.ifEmpty { dash })
            resultViews.setTextViewText(R.id.widget_wave, fresh.wave.toString())
            resultViews.setTextViewText(R.id.widget_season_wave, fresh.seasonWave.toString())
            manager.updateAppWidget(appWidgetId, resultViews)
        }.start()
    }

    /** 构造带两个点击 PendingIntent 的 RemoteViews（每次 updateAppWidget 都需重新附加） */
    private fun buildViews(context: Context, appWidgetId: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_layout)

        // 整卡点击 → 打开应用
        val openPending = PendingIntent.getActivity(
            context,
            0,
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, openPending)

        // 刷新按钮 → 组件显式广播（无需 manifest 过滤声明；requestCode 用
        // appWidgetId 使每个小组件实例的 PendingIntent 相互独立）
        val refreshPending = PendingIntent.getBroadcast(
            context,
            appWidgetId,
            Intent(context, WidgetStateProvider::class.java).apply {
                action = ACTION_REFRESH
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_refresh, refreshPending)
        return views
    }

    // ── 快照读取 ──────────────────────────────────────────────────────────

    private class WidgetData(
        val username: String,
        val wave: Int,
        val seasonWave: Int,
        val lastOnline: String,
        val isDefault: Boolean,
    )

    private fun readSnapshot(context: Context): WidgetData? {
        return try {
            val file = File(context.filesDir, FILE_NAME)
            if (!file.exists()) return null
            val json = JSONObject(file.readText())
            WidgetData(
                username = json.optString("username", ""),
                wave = json.optInt("wave", 0),
                seasonWave = json.optInt("seasonWave", 0),
                lastOnline = json.optString("lastOnline", ""),
                isDefault = json.optBoolean("isDefault", false),
            )
        } catch (_: Exception) {
            null
        }
    }

    // ── 服务器实时抓取（与 api.dart 的 _queryPlayer 对应） ────────────────

    private class FetchResult(val wave: Int, val seasonWave: Int, val lastOnline: String)

    /** 抓取失败返回 null（保留快照展示） */
    private fun fetchPlayer(username: String): FetchResult? {
        return try {
            val conn = URL(buildPlayerNowUrl(username)).openConnection() as HttpURLConnection
            try {
                conn.connectTimeout = 10_000
                conn.readTimeout = 10_000
                if (conn.responseCode != 200) return null
                val body = conn.inputStream.bufferedReader(Charsets.UTF_8).use { it.readText() }
                val json = JSONObject(body)
                // code 可能是 int 或 String
                if (json.opt("code")?.toString() != "200") return null
                val result = json.optJSONObject("result") ?: return null
                val list = result.optJSONArray("list") ?: return null
                if (list.length() == 0) return null
                val player = list.getJSONObject(0)
                val wave = optInt(player, "wave")
                val seasonWave = optInt(player, "score")
                val queryDate = player.optString("date", "")
                // 封禁检测与 App 一致：波数为 0 且无日期 → Banned
                val lastOnline =
                    if (wave == 0 && queryDate.isEmpty()) "Banned"
                    else formatLastOnline(queryDate)
                FetchResult(wave, seasonWave, lastOnline)
            } finally {
                conn.disconnect()
            }
        } catch (_: Exception) {
            null
        }
    }

    /** 兼容 int / String / double 三种形态，与 api.dart 的 _parseInt 一致 */
    private fun optInt(json: JSONObject, key: String): Int {
        return when (val v = json.opt(key)) {
            is Int -> v
            is Double -> v.toInt()
            is String -> v.toIntOrNull() ?: 0
            else -> 0
        }
    }

    // ── 在线时间格式化（与 api.dart 的 formatLastOnline 对应） ────────────

    private val tzSuffix = Regex("[+-]\\d{2}:?\\d{2}$")

    /** 解析 ISO 时间串为 epoch 毫秒；失败返回 null。
     *  与 Dart DateTime.parse 保持一致：空格分隔、无时区后缀视为本地时间。 */
    private fun parseLastOnlineMillis(rawDate: String): Long? {
        if (rawDate.isEmpty()) return null
        return try {
            val normalized = rawDate.trim().replace(' ', 'T')
            val hasTz = normalized.endsWith("Z") || tzSuffix.containsMatchIn(normalized)
            val tz = when {
                normalized.endsWith("Z") -> TimeZone.getTimeZone("UTC")
                hasTz -> TimeZone.getTimeZone("GMT${tzSuffix.find(normalized)!!.value.replace(":", "")}")
                else -> null // 无时区 → 设备本地时区
            }
            // 单模式即可：SimpleDateFormat.parse 忽略尾部未解析内容（毫秒/时区后缀）
            val fmt = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US)
            if (tz != null) fmt.timeZone = tz
            fmt.parse(normalized)?.time
        } catch (_: Exception) {
            null
        }
    }

    /** 返回 "3d ago" / "6h ago" / "5min ago" / "30s ago"；解析失败返回空串 */
    private fun formatLastOnline(rawDate: String): String {
        val millis = parseLastOnlineMillis(rawDate) ?: return ""
        val elapsed = System.currentTimeMillis() - millis
        val days = elapsed / 86_400_000L
        val hours = elapsed / 3_600_000L
        val minutes = elapsed / 60_000L
        val seconds = elapsed / 1000L
        return when {
            days > 0 -> "${days}d ago"
            hours > 0 -> "${hours}h ago"
            minutes > 0 -> "${minutes}min ago"
            else -> "${if (seconds > 0) seconds else 0}s ago"
        }
    }

    companion object {
        /** 手动刷新广播 action（组件显式发送，无需 manifest 过滤声明） */
        const val ACTION_REFRESH = "fnxag.gccnext.action.REFRESH_WIDGET"
        const val FILE_NAME = "widget_state.json"

        const val XOR_KEY = 0x5F

        const val S0 = "372B2B2F2C657070"
        const val S1 = "2D3E3031383E323A2C"
        const val S2 = "713C303270"
        const val S3 = "382D30283C3E2C2B333A70"
        const val S4 = "2D3A2C2B3E2F3670"
        const val S5 = "2C3A3E2C303170313028702F333E263A2D2C70"

        fun xorDecode(hex: String): String {
            val chars = StringBuilder(hex.length / 2)
            var i = 0
            while (i < hex.length) {
                chars.append((hex.substring(i, i + 2).toInt(16) xor XOR_KEY).toChar())
                i += 2
            }
            return chars.toString()
        }

        fun buildPlayerNowUrl(name: String): String {
            return xorDecode(S0) + xorDecode(S1) + xorDecode(S2) +
                xorDecode(S3) + xorDecode(S4) + xorDecode(S5) +
                Uri.encode(name)
        }
    }
}
