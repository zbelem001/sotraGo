# Résolution du problème de compilation Java (Flutter Run)

## Le Problème
Lors de l'exécution de la commande `flutter run`, l'erreur suivante est apparue :
> `Toolchain installation '/usr/lib/jvm/java-21-openjdk-amd64' does not provide the required capabilities: [JAVA_COMPILER]`

**Cause :** 
Gradle tentait d'utiliser la version de Java 21 par défaut du système. Cependant, seul l'environnement d'exécution (JRE) de Java 21 était installé sur la machine, et non le kit de développement complet (JDK). Il manquait donc le compilateur `javac` pour Java 21.

## La Solution
Le système disposait déjà du JDK complet pour **Java 17** (`openjdk-17-jdk`), qui est la version parfaitement compatible et d'ailleurs configurée dans les fichiers `build.gradle.kts` du projet Android.

Pour résoudre le problème sans avoir besoin des droits administrateur (`sudo`), les étapes suivantes ont été appliquées pour forcer Flutter et Gradle à utiliser Java 17 :

### 1. Configuration de Flutter
Nous avons indiqué à Flutter d'utiliser explicitement le dossier du JDK 17 avec la commande suivante :
```bash
flutter config --jdk-dir /usr/lib/jvm/java-17-openjdk-amd64
```

### 2. Configuration de Gradle
Nous avons forcé Gradle à utiliser ce même JDK pour la compilation locale en ajoutant la propriété `org.gradle.java.home` au fichier `android/gradle.properties` :
```bash
echo "org.gradle.java.home=/usr/lib/jvm/java-17-openjdk-amd64" >> android/gradle.properties
```

## Résultat
Avec ces  deux configurations, Gradle trouve bien le compilateur Java 17 et accomplit l'étape d'assemblage (task `assembleDebug`) avec succès. L'application se lance désormais correctement via `flutter run`.