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

// Fix for 'app_links' and other sub-project dependency issues
subprojects {
    project.beforeEvaluate {
        if (project.name != "app") {
            // In Kotlin DSL, use 'extra' to manage dynamic project properties
            project.extra.set("flutter", rootProject.extra.get("flutter"))
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
