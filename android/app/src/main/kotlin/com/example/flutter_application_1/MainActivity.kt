package com.cuberix.ambigram

import android.content.ContentValues
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStream

class MainActivity : FlutterActivity() {

    private val CHANNEL = "gallery_saver" // Must match Dart channel name in your PreviewScreen

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "saveImageToGallery") {
                    val imageData = call.arguments as? ByteArray
                    if (imageData == null) {
                        result.error("INVALID_DATA", "No image data received", null)
                        return@setMethodCallHandler
                    }

                    val file = saveImageToGallery(imageData)
                    if (file != null) {
                        result.success("success")
                    } else {
                        result.error("SAVE_ERROR", "Failed to save image", null)
                    }

                } else {
                    result.notImplemented()
                }
            }
    }

    /**
     * Saves the given [imageData] as a PNG in the device's Gallery.
     * For Android 10+ (API 29+), it uses MediaStore with DCIM.
     * On older devices, it manually writes to DCIM and sends a broadcast.
     */
    private fun saveImageToGallery(imageData: ByteArray): File? {
        // 1. Decode the bytes into a Bitmap
        val bitmap = BitmapFactory.decodeByteArray(imageData, 0, imageData.size) ?: return null

        // 2. Generate a unique filename (timestamp-based)
        val filename = "ambigram_${System.currentTimeMillis()}.png"

        // 3. For Android 10+ (API 29), store via MediaStore in the DCIM folder
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val contentValues = ContentValues().apply {
                put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, filename)
                put(android.provider.MediaStore.MediaColumns.MIME_TYPE, "image/png")
                // Put them in DCIM, which is typically where camera images go
                put(
                    android.provider.MediaStore.MediaColumns.RELATIVE_PATH,
                    Environment.DIRECTORY_DCIM + "/Ambigrams"
                )
                put(android.provider.MediaStore.MediaColumns.IS_PENDING, 1)
            }

            val uri: Uri? = contentResolver.insert(
                android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                contentValues
            )

            if (uri != null) {
                // Safely handle the nullable OutputStream
                val outputStream = contentResolver.openOutputStream(uri) ?: return null
                outputStream.use { stream ->
                    bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, stream)
                }

                // Mark it as ready
                contentValues.clear()
                contentValues.put(android.provider.MediaStore.MediaColumns.IS_PENDING, 0)
                contentResolver.update(uri, contentValues, null, null)

                // Return a File reference, or you can just return null if you prefer
                File(uri.toString())
            } else {
                null
            }

        } else {
            // 4. On older devices, manually write to DCIM
            val dcimDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM)
            val ambigramsFolder = File(dcimDir, "Ambigrams")
            if (!ambigramsFolder.exists()) {
                ambigramsFolder.mkdirs()
            }

            val imageFile = File(ambigramsFolder, filename)
            try {
                val fos: OutputStream = FileOutputStream(imageFile)
                bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, fos)
                fos.flush()
                fos.close()

                // Notify the gallery so it can show up
                val mediaScanIntent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE)
                mediaScanIntent.data = Uri.fromFile(imageFile)
                sendBroadcast(mediaScanIntent)

                imageFile
            } catch (e: Exception) {
                e.printStackTrace()
                null
            }
        }
    }
}
