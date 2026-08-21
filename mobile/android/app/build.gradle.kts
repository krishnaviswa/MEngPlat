import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing: reads android/key.properties if present (gitignored; created
// locally per ANDROID_APP_STRATEGY.md, or written from CI secrets in
// .github/workflows/mobile-release-aab.yml). When absent, uses the committed
// sideload.keystore so GitHub Actions APK SHA-1 stays stable for the Android
// OAuth client. Last resort is the ephemeral debug key.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
val sideloadKeystoreFile = rootProject.file("sideload.keystore")

/** Host for HTTPS /collect App Links. Same origin as Dart [WEB_BASE_URL], from env (CI) or -PWEB_BASE_URL. Not a brand domain in source. */
fun collectWebHost(): String {
    val raw = (project.findProperty("WEB_BASE_URL") as String?)?.trim().orEmpty()
        .ifEmpty { System.getenv("WEB_BASE_URL")?.trim().orEmpty() }
    if (raw.isEmpty()) return "localhost"
    val withScheme = if (raw.contains("://")) raw else "https://$raw"
    return try {
        java.net.URI(withScheme).host ?: "localhost"
    } catch (_: Exception) {
        "localhost"
    }
}

android {
    namespace = "com.merchanthub.merchanthub_mobile"
    // flutter_secure_storage requires compileSdk 37; flutter.compileSdkVersion (36) is too low.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.merchanthub.merchanthub_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["collectWebHost"] = collectWebHost()
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        } else if (sideloadKeystoreFile.exists()) {
            create("sideload") {
                keyAlias = "sideload"
                keyPassword = "merchanthub"
                storeFile = sideloadKeystoreFile
                storePassword = "merchanthub"
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else if (sideloadKeystoreFile.exists()) {
                signingConfigs.getByName("sideload")
            } else {
                signingConfigs.getByName("debug")
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
