allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Sets the root build directory to a path outside the android folder
layout.buildDirectory.fileValue(rootProject.layout.projectDirectory.dir("../build").asFile)

subprojects {
    // Dynamically sets each subproject's build directory
    val newSubprojectBuildDir = rootProject.layout.buildDirectory.dir(project.name).get().asFile
    project.layout.buildDirectory.fileValue(newSubprojectBuildDir)
}

subprojects {
    // Ensures sub-projects are configured after the app project to access extensions
    if (project.name != "app") {
        project.evaluationDependsOn(":app")
    }
}

// Fix for 'app_links', 'jni', and other sub-project dependency validation crashes
subprojects {
    project.beforeEvaluate {
        if (project.name != "app") {
            // 1. Inject the flutter object
            project.extra.set("flutter", rootProject.extra.get("flutter"))
            
            // 2. FORCE fallback NDK configurations for AGP 9.2+ compilation compliance
            project.extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.apply {
                ndkVersion = "26.1.10909125" // Sets a stable baseline NDK version
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
