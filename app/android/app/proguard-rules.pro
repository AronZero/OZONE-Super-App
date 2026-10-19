# ML Kit text recognition: only the bundled Latin model ships (F4-03 §1).
# The plugin also references the other scripts, which are compileOnly and not in the APK.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# ML Kit reads its own classes by reflection (component registrars and logging
# messages). Without these, R8 strips them and reading text fails with a
# NullPointerException inside ML Kit (found on the emulator, M12).
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_common.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_bundled_common.** { *; }
-keep class com.google.android.gms.internal.mlkit_common.** { *; }
