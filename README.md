# TechFlow

Application Flutter de swipe d’articles tech, avec backend **Supabase**.

## Pré-requis

- Flutter (SDK installé) : `flutter --version`
- Dart (fourni avec Flutter)
- (Optionnel) Xcode (macOS/iOS) / Android Studio (Android) selon ta plateforme

## Configuration

1) Créer le fichier `.env` à la racine du projet.

Tu peux partir de `.env.example` (ou copier/coller) et renseigner tes valeurs Supabase :

```dotenv
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
```

2) Installer les dépendances :

```bash
flutter pub get
```

## Lancer l’application

Depuis la racine du projet :

```bash
flutter run
```

### Lancer sur une plateforme spécifique (exemples)

- **macOS** :

```bash
flutter run -d macos
```

- **iOS** (avec simulateur ouvert) :

```bash
flutter run -d ios
```

- **Android** (avec émulateur ou device branché) :

```bash
flutter run -d android
```

## Commandes utiles

- Lister les devices disponibles :

```bash
flutter devices
```

- Nettoyer et relancer (si build bloqué) :

```bash
flutter clean && flutter pub get
```

## (Optionnel) Lancer n8n et importer le workflow

Ce projet inclut un export de workflow n8n : `n8n/n8n-worflows.json`.

### Démarrer n8n

1) Crée/complète ton fichier `.env` à la racine (pour n8n) :

```dotenv
N8N_HOST=localhost
N8N_USER=admin
N8N_PASSWORD=change_me
```

2) Lance n8n :

```bash
docker compose up -d
```

3) Ouvre n8n : `http://localhost:5678` puis connecte-toi (basic auth).

### Importer le workflow (manuel)

1) Dans n8n, va dans **Workflows**.
2) Clique **Import** (ou **Add workflow → Import from file** selon la version).
3) Sélectionne le fichier : `n8n/n8n-worflows.json`.
4) Sauvegarde le workflow (et active-le si besoin).

### Ce que fait le workflow

- Déclenchement **planifié** (Schedule Trigger) à une heure fixe.
- Lecture de flux RSS Dev.to par tag (ex. `php`, `js`, `python`, `ia`).
- Mapping des données (url, title, snippet, published_at, tags, content, source_name, author).
- Envoi vers Supabase via **HTTP Request** sur l’endpoint REST `articles`.

### Credentials / configuration à faire après import

Après import, vérifie le node **HTTP Request** :

- **Supabase URL** : doit pointer vers *ton* projet (ex. `https://<project-ref>.supabase.co`).
- **Clé API / Bearer** :
  - Le workflow utilise l’API REST Supabase et nécessite une clé (souvent **Service Role** pour écrire).
  - Recommandation : **ne pas laisser de clé en dur dans le JSON**. Remplace les headers par des variables et configure-les chez toi.

Exemple recommandé (à adapter) :

- Ajouter dans `.env` (à la racine) :

```dotenv
SUPABASE_URL=...
SUPABASE_SERVICE_ROLE_KEY=...
```

- Dans n8n, dans le node **HTTP Request**, mets :
  - URL : `{{$env.SUPABASE_URL}}/rest/v1/articles`
  - Header `apikey` : `{{$env.SUPABASE_SERVICE_ROLE_KEY}}`
  - Header `Authorization` : `Bearer {{$env.SUPABASE_SERVICE_ROLE_KEY}}`
ou alors changer directement les valeurs dans le fichier ./n8n/n8n-workflows.json avant de l'importer dans n8n

Ensuite :
- Recrée/associe les credentials nécessaires si certains nodes en demandent (ici, principalement Supabase via headers).
- Si ton Supabase a des règles RLS, assure-toi que la clé utilisée a le droit d’écrire dans `articles`.

## Notes

- Les variables d’environnement sont chargées via `flutter_dotenv` (asset `.env`).
- Les dates utilisent `intl` et sont initialisées au démarrage (`initializeDateFormatting('fr_FR')`).

## Reste à faire

- Page de connexion + table Supabase
- Page listant les articles likés
- Page pour lire les articles
- Fonctionnalité pour générer un résumé avec l’IA
- Page de résumé de l’article via l’IA
- swagger 