# SotraGO - Historique complet du Développement (A - Z)

Ce document retrace l'ensemble des tâches, corrections de bugs, améliorations UI/UX et décisions architecturales effectuées sur le projet **SotraGO** (Frontend Flutter & Backend Node.js).

---

## 1. Résolution des Bugs de Routage (Service d'Itinéraire)
- **Le Problème** : Suite à un changement d'IP du serveur (`192.168.11.105`), l'API backend (pgRouting) renvoyait parfois des itinéraires vides ou contenant uniquement de la marche à pied (sans bus). Cela faisait crasher ou bloquait l'affichage sur la carte.
- **La Solution (Fallback Local)** : Implémentation d'un système de secours dans `routing_service.dart`. Si l'API renvoie 0 segment de bus, l'application bascule automatiquement sur un algorithme local (utilisant la formule de Haversine) pour trouver l'arrêt de départ et l'arrêt d'arrivée les plus proches géographiquement.

## 2. Améliorations UI/UX de la Carte (`MapScreen`)
- **Correction des marqueurs superposés** : L'arrêt final affichait simultanément un point rouge de localisation ET un marqueur de bus rouge, ce qui surchargeait l'écran. Le marqueur redondant a été supprimé.
- **Optimisation des lignes piétonnes** : Si la destination de l'utilisateur correspondait exactement à l'arrêt final du bus (distance < 10 mètres), un drapeau bleu et une ligne en pointillés inutile s'affichaient. Une condition de distance a été ajoutée pour masquer ces éléments quand ils ne sont pas pertinents.
- **Vue Satellite dynamique** : Ajout d'un bouton (icône *satellite_alt*) en bas à gauche de la carte permettant de basculer instantanément (`_isSatelliteView`) entre le fond de carte standard en mode sombre/clair et une imagerie satellite haute résolution (Esri World Imagery).
- **Réorganisation des boutons flottants (FABs)** : Les boutons de localisation et d'information de la carte étaient trop haut. Ils ont été abaissés (propriété `bottom` ajustée de 120 à 90, puis 80) pour réduire l'écart avec la barre de navigation (BottomNavigationBar) et aérer l'écran.
- **Simplification du bouton "Détails"** : Lorsqu'une ligne est sélectionnée, l'énorme bouton "Détails" a été remplacé par un bouton rond minimaliste contenant uniquement l'icône `Icons.info_outline`.

## 3. Retouches de l'Écran d'Accueil et Navigation
- **Mise à jour des tarifs** : Dans la section des "Lignes favorites / populaires" de l'accueil, le prix affiché était erroné (150 F). Il a été remplacé de manière dynamique par **200 F**.
- **Refonte de la fenêtre d'information (?)** : La boîte de dialogue expliquant le *Mode Éclaireur* et le fonctionnement de SotraGO a été modernisée :
  - Le texte a été épuré (suppression des emojis superflus).
  - Les sous-titres (*Fonctionnement*, *Mode Éclaireur*, *Confidentialité*) ont reçu un fond vert semi-transparent avec des bordures arrondies.
  - Le bouton déclencheur (en bas à droite de l'accueil) a été remonté et coloré en rouge (`Colors.red`) pour attirer l'attention.
- **Correction de l'état de la Carte (Map Reset)** : Auparavant, si l'utilisateur consultait une ligne spécifique et retournait à l'accueil, la carte restait bloquée sur cette ligne unique lors du prochain accès. Ajout de la méthode `resetToAllLines()` appelée via une **GlobalKey** depuis `main_screen.dart` lors du clic sur l'onglet Carte, forçant l'affichage natif de *Toutes les lignes colorées*.

## 4. Gestion du Backend et Versioning
- Initialisation du suivi des versions (Git) pour le répertoire `/backend/sorre-backend`.
- Validation et Commit local ("Update backend logic") de l'intégralité du code serveur (Node.js/Socket.io).
- Sauvegarde et Push de l'intégralité des retouches UI du frontend vers le dépôt distant GitHub `sotraGo`.

## 5. Perspectives DevOps et Architecture de Déploiement (Recommandations)

Afin de préparer l'application à supporter la charge des futurs utilisateurs urbains (pics d'utilisation liés aux WebSockets et aux calculs d'itinéraires PostgreSQL/pgRouting), la stratégie DevOps suivante a été établie :


### Étape Actuelle : Notre Infrastructure à Disposition

Actuellement, l'ensemble du système repose sur une architecture solide, déjà dockerisée et fonctionnelle, répartie ainsi :

- **Application Mobile (Frontend)** :
  - Développée en **Flutter** (Android/iOS), avec une UI fluide et un système de "Native Splash Screen" perfectionné.
  - Communique avec le backend via des appels REST (API) et des **WebSockets** (Socket.io) pour le suivi en temps réel des bus.

- **Backend (API & Temps Réel)** :
  - Construit en **Node.js** avec Express.
  - Gère les connexions **Socket.io** pour diffuser les coordonnées GPS (Mode Éclaireur / Bus) aux utilisateurs connectés.
  - Conteneurisé avec **Docker** (le `Dockerfile` et le `docker-compose.yml` sont prêts), ce qui permet de le lancer sur n'importe quel serveur (VPS, cloud) avec un simple `docker-compose up -d`.

- **Base de Données et Routage (PostgreSQL + PostGIS + pgRouting)** :
  - Un conteneur **PostgreSQL** dédié, dopé avec l'extension spatiale **PostGIS** et le moteur de graphes **pgRouting**.
  - C'est ce composant massif qui stocke les lignes de bus, les arrêts, le réseau routier et qui calcule les itinéraires intelligents en fonction des coordonnées GPS.
  - Hébergé de manière persistante (volumes Docker) pour ne pas perdre les données géographiques au redémarrage.

- **Cache & Scalabilité (Redis)** :
  - Un conteneur **Redis** est présent dans notre stack Docker.
  - Il joue un double rôle vital : 
    1. Il sert d'**Adapter Pub/Sub** pour Socket.io (permettant à plusieurs serveurs Node.js de discuter entre eux si on scale l'application).
    2. Il agit comme un cache ultra-rapide pour éviter de solliciter PostgreSQL sur les requêtes fréquentes ou statiques.

- **Gestion et Orchestration Locale (Docker Compose)** :
  - L'intégralité de cet environnement (Node.js, PostgreSQL/pgRouting, Redis) est orchestrée localement via **Docker Compose**.
  - Un seul fichier lie ensemble la base de données, le cache et l'application serveur, gérant automatiquement la création du réseau interne (networks), l'ordre de démarrage (depends_on), et la persistance des données (volumes).

### A. Scalabilité des WebSockets (Backend Node.js)
- **Le problème** : Un utilisateur connecté au Serveur A ne peut pas recevoir la position d'un bus envoyée au Serveur B s'ils ne communiquent pas entre eux.
- **La solution** : 
  - **Scaling horizontal** (ajouter plusieurs serveurs/instances Node.js).
  - Implémentation d'un **Adapter Redis** (`@socket.io/redis-adapter`) qui agit comme un pont ultra-rapide entre toutes les instances Node.js.
  - Utilisation d'un **Load Balancer** (Répartiteur de charge) avec activation des **Sticky Sessions** pour maintenir correctement chaque connexion client.

### B. Pipeline CI/CD (Automatisation)
- **Backend (Node.js)** :
  - **Dockerisation** (Création d'un `Dockerfile`) pour packager complètement l'application indépendamment du système.
  - Pipeline GitHub Actions qui se déclenche à chaque `git push main` (Build de l'image Docker -> Push vers Docker Hub/ECR -> Déploiement auto via SSH ou webhook).
- **Frontend (Flutter)** :
  - Intégration de **Fastlane** couplé à GitHub Actions ou GitLab CI pour packager automatiquement les formats de production (APK/AAB/IPA) et les publier (TestFlight et Google Play Console).

### C. Choix d'Infrastructure (Hébergement)
- **Phase de Lancement (Niveau 1)** :
  - **Platform-as-a-Service (PaaS)** : Services comme Render ou DigitalOcean App Platform pour héberger facilement l'image Docker avec un point terminal gérant TLS, scaling et WebSockets.
  - **Base de données Managée** : DigitalOcean Managed Database (PostgreSQL) / AWS RDS / Supabase pour garantir des sauvegardes automatiques pour l'imposante architecture pgRouting.
  - **Redis** : Instance gérée légère (ex: Upstash).
- **Phase de Croissance (Niveau 2)** :
  - Migration vers Google Kubernetes Engine (GKE) ou AWS ECS (Fargate).
  - Ajout de **PgBouncer** devant PostgreSQL : outil indispensable de "Connection Pooling" (mise en file d'attente des connexions) pour empêcher la base de données de saturer lors de milliers de requêtes pgRouting simultanées.

### D. Observabilité et Monitoring
- **Sur l'Application (Flutter)** : Intégration de **Firebase Crashlytics** ou **Sentry** de manière obligatoire pour capturer et alerter silencieusement l'équipe lors des bugs rencontrés par les utilisateurs en production, par modèle d'appareil.
- **Sur le Backend (Serveur)** : Installation de PM2 (sur VM native), Grafana ou Datadog avec définition d'un seuil d'alerte (Envoi d'un message Discord/Slack si la consommation de requêtes paralyse le CPU à plus de 80%).

---
*Date de mise à jour : 5 Avril 2026*



ctuellement, votre base de données, votre serveur Redis et votre backend NestJS tournent sur votre ordinateur local. Si vous générez un APK maintenant, il cherchera à se connecter à votre réseau local (ex: localhost ou 192.168.x.x), ce qui ne marchera pas sur le téléphone de vos camarades une fois rentrés chez eux.

Voici les 4 étapes incontournables pour un vrai déploiement :

1. Louer un Serveur en ligne (VPS)
Puisque vous utilisez PostgreSQL avec pgRouting (une configuration Docker très spécifique pour les cartes avec les scripts OSM) et Redis, le plus simple et le moins cher est de louer un VPS (un petit serveur virtuel sous Linux).

Où louer ? OVH, Contabo, Hostinger ou DigitalOcean. (Un VPS avec 4Go à 8Go de RAM est recommandé car l'import cartographique PostgreSQL consomme de la mémoire). Ça coûte entre 5€ et 10€ / mois.
Ce qu'on y fera : On installera Docker, on copiera votre code Backend, et on lancera votre docker-compose.yml et votre import_osm.sh exactement comme on l'a fait sur votre machine.
2. Déployer et exposer le Backend NestJS
Une fois la base de données prête sur le VPS :

Il faudra lancer le serveur NestJS en continu (avec Node.js et un outil comme PM2, ou mieux : le mettre aussi dans un conteneur Docker).
Si le VPS a l'adresse IP 194.56.xx.xx, votre backend sera joignable mondialement via http://194.56.xx.xx:3000. (On pourra même mettre un nom de domaine et du HTTPS plus tard).
3. Modifier l'URL dans l'application Flutter
Avant de générer l'APK, vous devrez aller dans le code source de Frontend (Flutter) et remplacer toutes les occurrences de votre IP locale par l'adresse IP de votre nouveau serveur VPS.

Les requêtes API devront pointer vers http://IP_DU_VPS:3000/api/...
Les connexions Socket.io devront pointer sur ce même serveur.
4. Générer l'APK de production
Une fois le backend en ligne et le frontend mis à jour avec la bonne IP, vous pourrez compiler l'application de façon optimisée :
Je lancerai pour vous la commande :


flutter build apk --release
Cela créera le fichier final app-release.apk que vous pourrez envoyer à vos camarades par WhatsApp, Télégram ou Google Drive.

💡 Alternative Gratuite et Temporaire (Pour tester demain à l'école)
Si c'est juste pour une démonstration demain et que vous ne voulez pas payer de serveur ce soir :

Vous gardez votre PC allumé avec tout qui tourne (Backend + Base de données).
Vous utilisez un outil gratuit comme Ngrok (qui va créer une URL publique sécurisée comme https://78df-89-12.eu.ngrok.io qui redirige vers votre PC).
On met cette URL temporaire dans le code Flutter.
On build l'APK et vous l'envoyez.
Inconvénient : Dès que vous fermez votre PC ou Ngrok, l'application de vos camarades cesse de fonctionner.
Voulez-vous qu'on mette en place la solution temporaire (Ngrok), ou prévoyez-vous de prendre un petit serveur VPS pour faire les choses professionnellement ?