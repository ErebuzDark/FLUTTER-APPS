# Flutter Local Notifications
-keep class com.dexterous.** { *; }
-keepclassmembers class com.dexterous.** { *; }

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable

# Hive
-keep class ** implements com.google.gson.TypeAdapterFactory { *; }
-keep class ** implements com.google.gson.JsonSerializer { *; }
-keep class ** implements com.google.gson.JsonDeserializer { *; }

# Google Play Core — suppress missing class warnings
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-dontwarn com.google.android.play.core.**