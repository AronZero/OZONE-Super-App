package ph.ozone.ozone

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * "Save to" for exports (docs/spec/F2-03 §2): the system save dialog
 * (ACTION_CREATE_DOCUMENT) starting in Downloads. No storage permission is
 * needed; the person picks the place. The built file is copied to it.
 */
class FilesChannel(private val activity: Activity) {
    private var pending: MethodChannel.Result? = null
    private var source: File? = null

    fun saveAs(path: String, name: String, mime: String?, result: MethodChannel.Result) {
        if (pending != null) {
            result.error("busy", "A save is already open", null)
            return
        }
        pending = result
        source = File(path)
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = mime ?: XLSX
            putExtra(Intent.EXTRA_TITLE, name)
            putExtra(
                DocumentsContract.EXTRA_INITIAL_URI,
                Uri.parse("content://com.android.externalstorage.documents/document/primary%3ADownload"),
            )
        }
        try {
            activity.startActivityForResult(intent, REQUEST)
        } catch (e: Exception) {
            finish(null, "no_picker")
        }
    }

    /** Returns true when the result was ours. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST) return false
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            finish(null, null) // cancelled
            return true
        }
        try {
            activity.contentResolver.openOutputStream(uri, "w")!!.use { out ->
                source!!.inputStream().use { it.copyTo(out) }
            }
            finish(displayName(uri) ?: "", null)
        } catch (e: Exception) {
            // A half-written file must not stay behind under the chosen name.
            try { DocumentsContract.deleteDocument(activity.contentResolver, uri) } catch (_: Exception) {}
            finish(null, "write_failed")
        }
        return true
    }

    private fun displayName(uri: Uri): String? =
        activity.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { c ->
            if (c.moveToFirst()) c.getString(0) else null
        }

    private fun finish(name: String?, error: String?) {
        val r = pending
        pending = null
        source = null
        if (error != null) r?.error(error, error, null) else r?.success(name)
    }

    companion object {
        const val REQUEST = 7341
        const val XLSX = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    }
}
