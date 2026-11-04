import java.io.FileInputStream
import java.util.Properties

// Signing secrets live in android/key.properties, which .gitignore keeps out of
// the repo. The file is optional on purpose: without it the release build falls
// back to the debug key, so a fresh clone still compiles instead of failing on
// a missing keystore. Only the machine that has key.properties can produce an
// APK that Play Store will accept.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasKeystore = keystorePropertiesFile.exists()
if (hasKeystore) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.kms.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.kms.app"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        // Both come from pubspec.yaml's `version: 1.0.0+1` - bump it there, not
        // here, or the two will drift apart.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasKeystore) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasKeystore) {
                signingConfigs.getByName("release")
            } else {
                // Debug-signed: installable for testing, rejected by Play Store.
                signingConfigs.getByName("debug")
            }

            // R8 is left off deliberately. Dart code is already tree-shaken by
            // the Flutter toolchain, so shrinking only touches the small Java
            // side - and a bad ProGuard rule shows up as a crash that happens
            // in release and nowhere else. Turn it on only with a test pass.
            isMinifyEnabled = false
            isShrinkResources = false
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
