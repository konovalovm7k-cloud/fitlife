# package:jni resolves these Kotlin coroutine types and members by name from Dart.
# shared_preferences_android 2.5.x uses them even for the first getInstance().
# Keep R8 enabled; preserve only the runtime surface used by this JNI bridge.
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.Unit { *; }
-keep interface kotlin.coroutines.Continuation { *; }
-keep class kotlin.coroutines.intrinsics.CoroutineSingletons { *; }
-keep class kotlin.coroutines.intrinsics.IntrinsicsKt** { *; }
