import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // FlutterFire / Firebase
    id("com.google.gms.google-services")
    // Kotlin & Flutter-specific plugins
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

/* ────────────── Load keystore credentials ────────────── */
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    /* ---- Compile / target settings ---- */
    ndkVersion = "27.0.12077973"
    namespace    = "com.cuberix.ambigram"          // <— package root
    compileSdk   = 35

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }
    kotlinOptions { jvmTarget = JavaVersion.VERSION_11.toString() }

    /* ---- App-wide dependencies ---- */
    dependencies {
        coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
    }

    /* ---- Default manifest / version info ---- */
    defaultConfig {
        // Application ID shown on Play Console – MUST match your listing
        applicationId = "com.cuberix.ambigram"
        minSdk        = 23
        targetSdk     = flutter.targetSdkVersion
        versionCode   = flutter.versionCode   // from pubspec.yaml (e.g. 1, 2, 3…)
        versionName   = flutter.versionName   // from pubspec.yaml (e.g. 1.0.0)
    }

    /* ---- Signing configs ---- */
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                storeFile   = file(keystoreProperties["storeFile"]   as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias      = keystoreProperties["keyAlias"]      as String
                keyPassword   = keystoreProperties["keyPassword"]   as String
            }
        }
    }

    /* ---- Build variants ---- */
    buildTypes {
        getByName("release") {
            signingConfig  = signingConfigs.getByName("release")
            isMinifyEnabled = true                    // enable R8 shrink/obfuscate
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        getByName("debug") {
            // Keep default debug signing or point at release for quick internal tests
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

/* ---- Point Flutter at project root ---- */
flutter { source = "../.." }
