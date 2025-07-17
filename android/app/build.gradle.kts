// Import yang dibutuhkan untuk membaca file properties
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// =================================================================
// KODE YANG SUDAH DIPERBAIKI (Sintaks Kotlin)
// =================================================================
// Membaca file key.properties dengan sintaks Kotlin yang benar
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
// =================================================================

android {
    namespace = "com.sentinel.project3"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.sentinel.project3"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // =================================================================
    // KODE YANG SUDAH DIPERBAIKI (Sintaks Kotlin)
    // =================================================================
    signingConfigs {
        create("release") {
            // Mengambil nilai dari key.properties dengan cara Kotlin
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = file(keystoreProperties.getProperty("storeFile"))
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            // Menghubungkan build 'release' dengan signing config 'release'
            signingConfig = signingConfigs.getByName("release")
            // Menggunakan tanda '=' untuk assignment
            // isMinifyEnabled = false // Anda bisa aktifkan jika perlu
            // shrinkResources = false // Anda bisa aktifkan jika perlu
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
    // =================================================================
}

flutter {
    source = "../.."
}
