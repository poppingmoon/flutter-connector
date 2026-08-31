rootProject.name = "unifiedpush_android"

pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    // This is the AGP version
    id("com.android.library") version "9.3.1" apply false
}