package ph.ozone.ozone

import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity (not FlutterActivity) is required by local_auth for app lock and vault biometrics.
class MainActivity : FlutterFragmentActivity() {
    private val files = FilesChannel(this)

    @Deprecated("Activity result for the Save to dialog (FilesChannel)")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (!files.onActivityResult(requestCode, resultCode, data)) super.onActivityResult(requestCode, resultCode, data)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Export "Save to" (docs/spec/F2-03 §2).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ozone/files").setMethodCallHandler { call, result ->
            when (call.method) {
                "saveAs" -> files.saveAs(call.argument<String>("path")!!, call.argument<String>("name")!!, result)
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ozone/platform").setMethodCallHandler { call, result ->
            when (call.method) {
                // Blocks screenshots and blanks the recent-apps preview (docs/spec/F2-01 §6).
                "setSecure" -> {
                    if (call.argument<Boolean>("on") == true) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                }
                // "Set a screen lock first" → Open phone settings.
                "openSecuritySettings" -> {
                    try {
                        startActivity(Intent(Settings.ACTION_SECURITY_SETTINGS))
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                // "Notifications are off for OZONE" → Open settings (F2-03 §4).
                "openNotificationSettings" -> {
                    try {
                        startActivity(Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, packageName))
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                // Vault fingerprint unlock needs Android 9+ (biometric-bound keys).
                "sdkInt" -> result.success(Build.VERSION.SDK_INT)
                else -> result.notImplemented()
            }
        }
    }
}
