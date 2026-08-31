import com.android.build.api.dsl.LibraryExtension
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.dsl.KotlinVersion

allprojects {
    repositories {
        google()
        mavenCentral()
        // mavenLocal()
        maven { url = uri("https://jitpack.io") }
    }
}

plugins {
    id("com.android.library")
}

configure<LibraryExtension> {
    namespace = "org.unifiedpush.flutter.connector"
    compileSdk = 36

    compileOptions{
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    defaultConfig {
        minSdk = 16

        aarMetadata {
            minCompileSdk = minSdk
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_1_8)
        // languageVersion provides source compatibility with the specified version of Kotlin
        // By default it uses $kotlinVersion (2.2)
        // We set it to the lowest non-deprecated value
        languageVersion.set(KotlinVersion.KOTLIN_2_0)
    }
}

dependencies {
    api("com.github.poppingmoon:android-connector:d8deb58367")
    // stick with 2.6.1 for now,
    // 2.7.x minSdk=19
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.6.1")
    //implementation(files("../../../flutter/bin/cache/artifacts/engine/android-x64/flutter.jar"))
}
