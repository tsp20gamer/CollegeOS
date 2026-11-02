# Suppress R8 warnings for unused ML Kit text recognition language models
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions

# ML Kit on-device text recognition (bundled Latin + Devanagari models, used
# for OCR of scanned PDF pages).
#
# Why these rules exist: ML Kit wires itself together with Firebase component
# discovery. MlKitComponentDiscoveryService lists each ComponentRegistrar by
# name in the manifest, and ComponentDiscovery creates them by reflection
# (Class.forName(name).getDeclaredConstructor().newInstance()). R8 full mode
# keeps a class named by "-keep class X" but NOT its no-arg constructor, so
# release builds shipped CommonComponentRegistrar, VisionCommonRegistrar and
# TextRegistrar with no constructor at all. Discovery then dropped all three
# silently, MlKitContext.get(SharedPrefManager.class) returned null, and the
# first InputImage.fromFilePath call crashed inside ML Kit with
# "NullPointerException: ... getClass() on a null object reference"
# (retraced: mlkit_vision_common.zzmj.<init> <- zzmr.create <-
# LazyInstanceMap.get <- InputImage.fromFilePath <- InputImageConverter).
# Release builds only; debug builds are not minified.
-keep class * implements com.google.firebase.components.ComponentRegistrar {
    public <init>();
    public java.util.List getComponents();
}
-keep class com.google.firebase.components.** { *; }

# Keep ML Kit, its GMS-internal implementation, the native-pipeline JNI
# bridge and the two Flutter plugins whole. ML Kit calls into itself by
# reflection and from native code (libmlkit_google_ocr_pipeline.so), so
# renaming or stripping any of it can break OCR on the phone while every test
# still passes. It costs well under 1 MB.
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_common.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_common.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_bundled_common.** { *; }
-keep class com.google.android.libraries.vision.visionkit.** { *; }
-keep class com.google.android.odml.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }
-keep class com.google_mlkit_commons.** { *; }
-dontwarn com.google.android.odml.**
