package ph.ozone.ozone

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import java.io.File

/**
 * Recipe photos (docs/spec/F4-01 §3): any picture → a JPEG of at most
 * maxSide px on its longest side, upright, with the phone's own encoder,
 * so no image package is needed (F4-03 §1). Runs off the main thread.
 */
object JpegConverter {
    fun convert(from: String, to: String, maxSide: Int, quality: Int) {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(from, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) throw IllegalArgumentException("not_an_image")
        // Decode at the smallest power-of-two size that is still at least maxSide.
        var sample = 1
        while (maxOf(bounds.outWidth, bounds.outHeight) / (sample * 2) >= maxSide) sample *= 2
        val decoded = BitmapFactory.decodeFile(from, BitmapFactory.Options().apply { inSampleSize = sample })
            ?: throw IllegalArgumentException("not_an_image")
        val scale = minOf(1f, maxSide.toFloat() / maxOf(decoded.width, decoded.height))
        val m = Matrix()
        m.postScale(scale, scale)
        m.postRotate(rotation(from).toFloat())
        val out = Bitmap.createBitmap(decoded, 0, 0, decoded.width, decoded.height, m, true)
        File(to).outputStream().use { if (!out.compress(Bitmap.CompressFormat.JPEG, quality, it)) throw IllegalStateException("encode_failed") }
        if (out !== decoded) out.recycle()
        decoded.recycle()
    }

    private fun rotation(path: String): Int = try {
        when (ExifInterface(path).getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)) {
            ExifInterface.ORIENTATION_ROTATE_90 -> 90
            ExifInterface.ORIENTATION_ROTATE_180 -> 180
            ExifInterface.ORIENTATION_ROTATE_270 -> 270
            else -> 0
        }
    } catch (e: Exception) {
        0
    }
}
