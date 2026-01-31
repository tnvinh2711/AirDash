plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.bun.studio.flux"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Unique Application ID for Google Play Store
        applicationId = "com.bun.studio.flux"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Only use release signing on Codemagic CI
            if (System.getenv("CI") != null) {
                // Codemagic CI environment variables
                keyAlias = System.getenv("FCI_KEY_ALIAS")
                keyPassword = System.getenv("FCI_KEY_PASSWORD")
                storeFile = file(System.getenv("FCI_KEYSTORE_PATH"))
                storePassword = System.getenv("FCI_KEYSTORE_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            // Use release signing only on CI, otherwise use debug keystore for local builds
            signingConfig = if (System.getenv("CI") != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
