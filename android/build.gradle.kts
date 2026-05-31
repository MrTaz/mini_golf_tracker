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

subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        val android = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        val javaVersion = android?.compileOptions?.targetCompatibility
        if (javaVersion != null) {
            val targetStr = javaVersion.toString()
            val jvmTargetValue = when (targetStr) {
                "1.8" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8
                "11" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
                "17" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
                "21" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21
                else -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8
            }
            compilerOptions {
                jvmTarget.set(jvmTargetValue)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}