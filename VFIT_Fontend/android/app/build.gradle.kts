import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val defaultDebugKeystorePath = providers.environmentVariable("USERPROFILE")
    .map { "$it\\.android\\debug.keystore" }
    .orElse("${System.getProperty("user.home")}\\.android\\debug.keystore")
val debugKeystoreFile = file(
    providers.environmentVariable("ANDROID_DEBUG_KEYSTORE")
        .orElse(defaultDebugKeystorePath)
        .get()
)

fun configValue(name: String): String {
    return providers.gradleProperty(name)
        .orElse(providers.environmentVariable(name))
        .orElse("")
        .get()
}

android {
    namespace = "com.vfit.vfit_frontend"
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
        applicationId = "com.vfit.vfit_frontend"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["usesCleartextTraffic"] = "false"
        val facebookAppId = configValue("FACEBOOK_APP_ID")
        resValue("string", "facebook_app_id", facebookAppId)
        resValue("string", "facebook_client_token", configValue("FACEBOOK_CLIENT_TOKEN"))
        resValue("string", "fb_login_protocol_scheme", "fb$facebookAppId")
    }

    signingConfigs {
        getByName("debug") {
            if (debugKeystoreFile.exists()) {
                keyAlias = "androiddebugkey"
                keyPassword = "android"
                storeFile = debugKeystoreFile
                storePassword = "android"
            }
        }
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        debug {
            manifestPlaceholders["usesCleartextTraffic"] = "true"
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("profile") {
            manifestPlaceholders["usesCleartextTraffic"] = "true"
            signingConfig = signingConfigs.getByName("debug")
        }
        release {
            manifestPlaceholders["usesCleartextTraffic"] = "false"
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
