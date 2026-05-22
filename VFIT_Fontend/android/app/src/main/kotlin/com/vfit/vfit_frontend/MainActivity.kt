package com.vfit.vfit_frontend

import android.content.ContentValues
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterActivity() {
    private val mediaChannelName = "vfit/media"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            mediaChannelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveImageToGallery" -> {
                    val path = call.argument<String>("path")
                    if (path.isNullOrBlank()) {
                        result.error("INVALID_PATH", "Image path is required", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val uri = saveImageToGallery(path)
                        result.success(uri.toString())
                    } catch (error: Exception) {
                        result.error(
                            "SAVE_IMAGE_FAILED",
                            error.localizedMessage ?: "Cannot save image",
                            null
                        )
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun saveImageToGallery(path: String): Uri {
        val source = File(path)
        if (!source.exists()) {
            throw IllegalArgumentException("Image file not found")
        }

        val extension = source.extension.lowercase().ifBlank { "jpg" }
        val mimeType = when (extension) {
            "png" -> "image/png"
            "webp" -> "image/webp"
            else -> "image/jpeg"
        }
        val displayName = "VFIT_${System.currentTimeMillis()}.$extension"
        val resolver = applicationContext.contentResolver
        val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        } else {
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        }

        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, displayName)
            put(MediaStore.Images.Media.MIME_TYPE, mimeType)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/V-FIT")
                put(MediaStore.Images.Media.IS_PENDING, 1)
            } else {
                val directory = File(
                    Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES),
                    "V-FIT"
                )
                directory.mkdirs()
                put(MediaStore.Images.Media.DATA, File(directory, displayName).absolutePath)
            }
        }

        val uri = resolver.insert(collection, values)
            ?: throw IllegalStateException("Cannot create gallery image")

        try {
            resolver.openOutputStream(uri)?.use { output ->
                FileInputStream(source).use { input ->
                    input.copyTo(output)
                }
            } ?: throw IllegalStateException("Cannot open gallery image")

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                values.clear()
                values.put(MediaStore.Images.Media.IS_PENDING, 0)
                resolver.update(uri, values, null, null)
            }
        } catch (error: Exception) {
            resolver.delete(uri, null, null)
            throw error
        }

        return uri
    }
}
