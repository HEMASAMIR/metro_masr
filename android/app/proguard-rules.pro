# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Dart AOT
-keep class * implements io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }

# Fix for Google Play Core missing classes during R8 minification
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
