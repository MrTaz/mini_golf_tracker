import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // Note: kotlin-android is now built-in to AGP 9.0+, so id("kotlin-android") is removed
    id("dev.flutter.flutter-gradle-plugin")
}

// 1. Load local.properties for Flutter SDK versions and app versioning
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode", "1").toInt()
val flutterVersionName = localProperties.getProperty("flutter.versionName", "1.0")

// 2. Load key.properties for secure signing
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

// Ensure flutter sdk properties are available globally
rootProject.extra.set("flutter", mapOf(
    "compileSdkVersion" to flutter.compileSdkVersion,
    "minSdkVersion" to flutter.minSdkVersion,
    "targetSdkVersion" to flutter.targetSdkVersion
))

android {
    // Set your specific namespace for org.dahome.mini_golf_tracker
    namespace = "org.dahome.mini_golf_tracker"
    compileSdk = flutter.compileSdkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "org.dahome.mini_golf_tracker"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutterVersionCode
        versionName = flutterVersionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            // Optional: isMinifyEnabled = true for production
        }
    }
}

flutter {
    source = "../.."
}
