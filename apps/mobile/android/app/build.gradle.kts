plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "app.shootingcompanion.shooting_companion"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "app.shootingcompanion.shooting_companion"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 33
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Local release builds use the debug key until a GitHub signing
            // secret is configured. No signing material belongs in source.
            signingConfig = signingConfigs.getByName("debug")
            ndk {
                // The first public Android release is intentionally arm64-only.
                // Flutter's target-platform limits AOT output but does not
                // automatically filter every FFI plugin library.
                abiFilters.clear()
                abiFilters.add("arm64-v8a")
            }
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

androidComponents {
    onVariants(selector().withBuildType("release")) { variant ->
        // Native-assets plugins can contribute libraries outside the app
        // module's ndk.abiFilters. Strip every non-arm64 payload from the
        // release variant while retaining x86_64 for debug/emulator builds.
        variant.packaging.jniLibs.excludes.add("**/armeabi-v7a/**")
        variant.packaging.jniLibs.excludes.add("**/x86/**")
        variant.packaging.jniLibs.excludes.add("**/x86_64/**")
    }
}
