plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.io.FileInputStream
import java.util.Properties

val keystorePropertiesFile = rootProject.file("key.properties")


android {
    namespace = "ai.nastech.nasbeat"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "ai.nastech.nasbeat"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    splits {
        abi {
            isEnable = true
            reset()
            include("armeabi-v7a", "arm64-v8a", "x86_64")
            isUniversalApk = true
        }
    }
    dependenciesInfo {
        includeInApk = false
        includeInBundle = false
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            println("   ✅ key.properties found - configuring release signing")
            val keystoreProperties = Properties()
            keystoreProperties.load(FileInputStream(keystorePropertiesFile))

            val keyAliasValue = keystoreProperties["keyAlias"] as String?
            val storeTypeValue = (keystoreProperties["storeType"] as String?)

            println("   Key alias: $keyAliasValue")
            println("   Store type: ${storeTypeValue ?: "(auto-detect)"}")

            val ksFile = rootProject.file("nasbeat.jks")
            println("   Keystore file exists: ${ksFile.exists()}")
            println("   Keystore file path: ${ksFile.absolutePath}")

            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = ksFile
                storePassword = keystoreProperties["storePassword"] as String?
                // storeType is written by CI after auto-detecting magic bytes (JKS vs PKCS12).
                // If not set, Android Gradle uses the JVM default (PKCS12 on Java 17+).
                if (storeTypeValue != null) {
                    storeType = storeTypeValue
                }
                println("   ✅ Release signing config created (storeType=${storeType})")
            }
        } else {
            println("   ❌ key.properties not found - using debug signing")
        }
    }

    buildTypes {
        release {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
                println("   📦 Release build: Using release signing config")
            }
            else{
                signingConfig = signingConfigs.getByName("debug")
                println("   📦 Release build: Using debug signing config (no keystore)")
            }
        }
    }

    // To reduce the size of the APK, since from AGP 8.0.0 the default value of useLegacyPackaging is false.
     packagingOptions {
        jniLibs {
            useLegacyPackaging = true
        }
    }
}

flutter {
    source = "../.."
}
