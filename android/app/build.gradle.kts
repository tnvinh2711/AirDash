plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties from key.properties file
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = java.util.Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.flux.flux"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.flux.flux"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Check if running on Codemagic CI
            if (System.getenv("CI") != null) {
                // Codemagic CI environment variables
                keyAlias = System.getenv("FCI_KEY_ALIAS")
                keyPassword = System.getenv("FCI_KEY_PASSWORD")
                storeFile = file(System.getenv("FCI_KEYSTORE_PATH"))
                storePassword = System.getenv("FCI_KEYSTORE_PASSWORD")
            } else if (keystorePropertiesFile.exists()) {
                // Local build with key.properties file
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Use release signing if on CI or if key.properties exists
            signingConfig = if (System.getenv("CI") != null || keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                // Fallback to debug signing for local development without keystore
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
