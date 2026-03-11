# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in /sdk/tools/proguard/proguard-android-optimize.txt

# Keep Kotlinx Serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt

-keepclassmembers class kotlinx.serialization.json.** {
    *** Companion;
}
-keepclasseswithmembers class kotlinx.serialization.json.** {
    kotlinx.serialization.KSerializer serializer(...);
}

-keep,includedescriptorclasses class ai.openclaw.android.**$$serializer { *; }
-keepclassmembers class ai.openclaw.android.** {
    *** Companion;
}
-keepclasseswithmembers class ai.openclaw.android.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# OkHttp
-dontnote okhttp3.internal.Platform
-keepclassmembers class okhttp3.internal.Platform {
    <fields>;
}