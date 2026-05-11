allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

layout.buildDirectory.fileValue(
    rootProject.layout.projectDirectory.dir("../build").asFile
)

subprojects {
    val newBuildDir = rootProject.layout.buildDirectory.dir(project.name).get().asFile
    project.layout.buildDirectory.fileValue(newBuildDir)
}

subprojects {
    if (project.name != "app") {
        project.evaluationDependsOn(":app")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}