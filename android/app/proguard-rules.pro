-keepattributes Signature

# ── FFmpeg Kit ─────────────────────────────────────────────────────────────
# Native code calls back into these classes, so they must keep their names
# if shrinking is ever turned on.
-keep class com.antonkarpenko.ffmpegkit.** { *; }
-keep class com.arthenica.ffmpegkit.** { *; }
-dontwarn com.antonkarpenko.ffmpegkit.**
-dontwarn com.arthenica.ffmpegkit.**

# ── ML Kit Text Recognition ────────────────────────────────────────────────
# Only the Latin script recognizer is used. Suppress warnings for optional
# script modules (Chinese, Japanese, Korean, Devanagari) that the plugin
# references but that are not included in the APK.
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
