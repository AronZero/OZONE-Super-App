import java.util.Properties

// Release signing lives OUTSIDE the repository: %USERPROFILE%/.ozone-keys/key.properties (see docs/spec/F3-04).
val keyProps = Properties().apply {
    val f = file(System.getProperty("user.home") + "/.ozone-keys/key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "ph.ozone.ozone"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications on older Android versions.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // Never change: a different ID installs as a separate app and can't read the old data.
        applicationId = "ph.ozone.ozone"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26 // Android 8.0 (docs/spec/README.md)
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keyProps.isNotEmpty()) {
                storeFile = file(keyProps.getProperty("storeFile"))
                storePassword = keyProps.getProperty("storePassword")
                keyAlias = keyProps.getProperty("keyAlias")
                keyPassword = keyProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Never ship a debug-signed APK: without the key file, release builds stop with an error.
            if (keyProps.isEmpty()) {
                throw GradleException("Release signing key not found in ~/.ozone-keys/key.properties")
            }
            signingConfig = signingConfigs.getByName("release")
            // ML Kit plugin references the CJK and Devanagari scripts, which are left out (F4-03 §1).
            proguardFiles("proguard-rules.pro")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Google library, version taken from the flutter_local_notifications README (22.3.1).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
