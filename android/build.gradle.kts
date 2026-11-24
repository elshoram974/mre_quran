allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// These plugins still declare Java 8 source/target, which JDK 21 reports as
// obsolete. They have no Kotlin sources, so raising them to 17 like the other
// plugins is safe. Remove an entry once its plugin updates its build.
val javaEightPlugins = setOf("geolocator_android", "printing")
subprojects {
    if (name in javaEightPlugins) {
        plugins.withId("com.android.library") {
            extensions.configure<com.android.build.api.variant.LibraryAndroidComponentsExtension> {
                finalizeDsl { library ->
                    library.compileOptions.sourceCompatibility = JavaVersion.VERSION_17
                    library.compileOptions.targetCompatibility = JavaVersion.VERSION_17
                }
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
