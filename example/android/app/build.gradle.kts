import com.android.build.api.dsl.ApplicationExtension

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

configure<ApplicationExtension> {
    namespace = "org.unifiedpush.flutter.example"
    compileSdk = flutter.compileSdkVersion

    defaultConfig {
        applicationId = "org.unifiedpush.flutter.example"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

