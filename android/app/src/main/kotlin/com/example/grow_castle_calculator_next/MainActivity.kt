package com.example.grow_castle_calculator_next

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.graphics.Color
import android.app.WallpaperManager
import android.os.Build.VERSION_CODES.S

class MainActivity : FlutterActivity() {
    private val channelName = "fnxag.dynamic_color/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSystemWallpaperSeedColor" -> {
                    if (Build.VERSION.SDK_INT >= S) {
                        val wallpaperManager = getSystemService(Context.WALLPAPER_SERVICE) as WallpaperManager
                        val wallpaperColors = wallpaperManager.getWallpaperColors(WallpaperManager.FLAG_SYSTEM)
                        val primaryArgb = wallpaperColors?.primaryColor?.toArgb()
                        result.success(primaryArgb)
                    } else {
                        // Android12以下无系统动态色
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}