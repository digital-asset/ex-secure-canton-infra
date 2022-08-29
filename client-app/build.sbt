ThisBuild / scalaVersion := "2.13.8"

//resolvers += "Local Maven Repository" at "file://"+Path.userHome.absolutePath+"/.m2/repository"
val silencerVersion = "1.7.1"
lazy val demo = (project in file("."))
  .settings(
    name := "demo",
    version := "0.1",
    libraryDependencies += "com.daml" %% "bindings-akka" % "2.3.2",
    libraryDependencies += "org.scalatest" %% "scalatest" % "3.2.13" % Test,
    resolvers += Resolver.mavenLocal,
    assembly / mainClass  := Some("app.ClientApp"),
    assembly / assemblyMergeStrategy := {
      case PathList("META-INF", xs @ _*) =>
        (xs map { _.toLowerCase }) match {
          case ("manifest.mf" :: Nil) | ("index.list" :: Nil) |
              ("dependencies" :: Nil) =>
            MergeStrategy.discard
          case _ => MergeStrategy.last
        }
      case PathList("reference.conf") => MergeStrategy.concat
      case _                          => MergeStrategy.first
    },
    assembly / assemblyJarName := "client.jar"
  )

