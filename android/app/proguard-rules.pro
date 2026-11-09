# Medify ProGuard Rules for Release Build Optimization

## Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

## ObjectBox - Keep database models
-keep class io.objectbox.** { *; }
-keepclassmembers class * extends io.objectbox.converter.PropertyConverter { *; }
-keep @io.objectbox.annotation.Entity class * { *; }
-keep class **$MyObjectBox { *; }
-keep class **_Cursor { *; }

## Keep notification service classes
-keep class com.sumit.medify.** { *; }
-keep class androidx.core.app.NotificationCompat** { *; }
-keep class androidx.work.** { *; }

## Keep Kotlin metadata
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

## Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

## Keep enum values
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

## Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

## Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

## Remove logging for release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

## Optimization flags
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-dontpreverify
-verbose

## Obfuscation
-repackageclasses ''
-allowaccessmodification
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*

## Keep attributes for debugging stack traces
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

## Keep annotations
-keepattributes *Annotation*,Signature,Exception,InnerClasses

## AndroidX
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-dontwarn androidx.**

## Google Material Components
-keep class com.google.android.material.** { *; }
-dontwarn com.google.android.material.**

## Gson (if used)
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }

## Prevent obfuscation of model classes (if using reflection/JSON)
# Add your model classes here if needed
# -keep class com.sumit.medify.models.** { *; }

## Remove debug and verbose logs
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
    public static int i(...);
}

## Keep crashlytics (if added in future)
# -keep class com.google.firebase.crashlytics.** { *; }
# -dontwarn com.google.firebase.crashlytics.**

