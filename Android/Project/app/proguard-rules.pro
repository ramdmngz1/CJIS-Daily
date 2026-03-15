# Keep only the fields needed for Gson serialization/deserialization.
# Gson uses field names at runtime; member names must be preserved but
# class-level obfuscation of non-data classes can still proceed.
-keepclassmembers class com.refuge.cjisdaily.data.** { *; }

# Preserve generic type signatures required by Gson's TypeToken reflection.
-keepattributes Signature

# Preserve only the annotations Gson and Kotlin require at runtime.
-keepattributes RuntimeVisibleAnnotations,RuntimeVisibleParameterAnnotations
