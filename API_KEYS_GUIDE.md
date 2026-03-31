# API Keys & Secrets Management Guide

## How This Project Protects API Keys

This project uses the **`envied`** package to safeguard API keys. Here's how it works:

```
.env (GITIGNORED)          -->  envied (build_runner)  -->  env.g.dart (OBFUSCATED)
Contains plain-text keys        Reads .env at build         Generates Dart code with
Never committed to git          time during codegen         XOR-encrypted key arrays
```

### Three Layers of Protection

| Layer | What It Does | Protects Against |
|-------|-------------|-----------------|
| **`.gitignore`** | Excludes `.env`, `google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart` from git | Keys leaking into version control / GitHub |
| **`envied` with `obfuscate: true`** | XOR-encrypts keys in generated Dart code — keys are never plain strings in the binary | Reverse engineering / decompiling the APK/IPA |
| **Firebase Security Rules** | Server-side validation of who can read/write data | Unauthorized API usage even if keys are found |

---

## Project File Structure

```
.env                          # Real keys (GITIGNORED - never committed)
.env.example                  # Template with placeholder values (committed)
lib/core/config/env.dart      # Envied class definition (committed)
lib/core/config/env.g.dart    # Generated obfuscated keys (GITIGNORED via *.g.dart)
lib/firebase_options.dart     # Uses Env class, no hardcoded keys (GITIGNORED)
android/app/google-services.json   # Firebase Android config (GITIGNORED)
ios/Runner/GoogleService-Info.plist # Firebase iOS config (GITIGNORED)
```

---

## How to Add a New API Key

### Step 1: Add the key to `.env`

```bash
# .env
SOME_SERVICE_API_KEY=your_actual_key_here
```

### Step 2: Add the same key name (with placeholder) to `.env.example`

```bash
# .env.example
SOME_SERVICE_API_KEY=your_key_here
```

### Step 3: Add the field to `lib/core/config/env.dart`

```dart
@EnviedField(varName: 'SOME_SERVICE_API_KEY')
static final String someServiceApiKey = _Env.someServiceApiKey;
```

### Step 4: Run code generation

```bash
make gen
# or
dart run build_runner build --delete-conflicting-outputs
```

### Step 5: Use the key in your code

```dart
import 'package:track/core/config/env.dart';

final apiKey = Env.someServiceApiKey;
```

That's it. The key is now:
- Read from `.env` (not in git)
- Obfuscated in the generated `env.g.dart`
- Accessible via `Env.someServiceApiKey` anywhere in the app

---

## Setting Up on a New Machine / After Cloning

After cloning the repository, the `.env` file won't exist. To get the app running:

1. Copy the template:
   ```bash
   cp .env.example .env
   ```

2. Fill in the real values in `.env` (get them from your secrets manager, Firebase Console, etc.)

3. Run code generation:
   ```bash
   make gen
   ```

4. For Firebase specifically, you also need:
   - Run `flutterfire configure` to regenerate platform-specific files
   - Or manually place `google-services.json` and `GoogleService-Info.plist`

---

## CI/CD: Injecting Keys in GitHub Actions

In CI/CD pipelines, keys are stored as **GitHub Actions Secrets** and injected at build time.

### Setup

1. Go to your repo: **Settings > Secrets and variables > Actions**
2. Add each key from `.env` as a separate secret

### Workflow Example

```yaml
# .github/workflows/ci.yml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.29.3'

      - name: Create .env file from secrets
        run: |
          cat <<EOF > .env
          FIREBASE_ANDROID_API_KEY=${{ secrets.FIREBASE_ANDROID_API_KEY }}
          FIREBASE_ANDROID_APP_ID=${{ secrets.FIREBASE_ANDROID_APP_ID }}
          FIREBASE_ANDROID_MESSAGING_SENDER_ID=${{ secrets.FIREBASE_ANDROID_MESSAGING_SENDER_ID }}
          FIREBASE_ANDROID_PROJECT_ID=${{ secrets.FIREBASE_ANDROID_PROJECT_ID }}
          FIREBASE_ANDROID_STORAGE_BUCKET=${{ secrets.FIREBASE_ANDROID_STORAGE_BUCKET }}
          FIREBASE_IOS_API_KEY=${{ secrets.FIREBASE_IOS_API_KEY }}
          FIREBASE_IOS_APP_ID=${{ secrets.FIREBASE_IOS_APP_ID }}
          FIREBASE_IOS_MESSAGING_SENDER_ID=${{ secrets.FIREBASE_IOS_MESSAGING_SENDER_ID }}
          FIREBASE_IOS_PROJECT_ID=${{ secrets.FIREBASE_IOS_PROJECT_ID }}
          FIREBASE_IOS_STORAGE_BUCKET=${{ secrets.FIREBASE_IOS_STORAGE_BUCKET }}
          FIREBASE_IOS_BUNDLE_ID=${{ secrets.FIREBASE_IOS_BUNDLE_ID }}
          EOF

      - name: Create google-services.json from secret
        run: echo '${{ secrets.GOOGLE_SERVICES_JSON }}' > android/app/google-services.json

      - name: Create GoogleService-Info.plist from secret
        run: echo '${{ secrets.GOOGLE_SERVICE_INFO_PLIST }}' > ios/Runner/GoogleService-Info.plist

      - name: Install dependencies
        run: flutter pub get

      - name: Run code generation
        run: dart run build_runner build --delete-conflicting-outputs

      - name: Build
        run: flutter build apk --dart-define=ENV=prod
```

### Storing Multi-line Files as Secrets

For `google-services.json` and `GoogleService-Info.plist`, base64 encode them:

```bash
# Encode
base64 -i android/app/google-services.json | pbcopy
# Paste into GitHub Secret: GOOGLE_SERVICES_JSON_B64

# In CI, decode
echo '${{ secrets.GOOGLE_SERVICES_JSON_B64 }}' | base64 --decode > android/app/google-services.json
```

---

## Common API Keys You Might Add Later

| Service | Env Variable Name | Where to Get It |
|---------|------------------|----------------|
| Google Maps | `GOOGLE_MAPS_API_KEY` | Google Cloud Console |
| RevenueCat | `REVENUECAT_API_KEY` | RevenueCat Dashboard |
| Sentry | `SENTRY_DSN` | Sentry Project Settings |
| Mixpanel | `MIXPANEL_TOKEN` | Mixpanel Project Settings |
| OpenAI | `OPENAI_API_KEY` | OpenAI Platform |
| Stripe | `STRIPE_PUBLISHABLE_KEY` | Stripe Dashboard |
| Algolia | `ALGOLIA_APP_ID` / `ALGOLIA_API_KEY` | Algolia Dashboard |

For each, follow the same 5-step process above.

---

## Security Checklist

Before every commit, verify:

- [ ] `.env` is in `.gitignore` and NOT staged (`git status`)
- [ ] `google-services.json` is NOT staged
- [ ] `GoogleService-Info.plist` is NOT staged
- [ ] `firebase_options.dart` is NOT staged
- [ ] No API keys appear in any committed `.dart` file (except `env.g.dart` which is obfuscated and gitignored)
- [ ] `.env.example` has placeholder values only (no real keys)

### Quick Check Command

```bash
# Search for potential leaked keys in staged files
git diff --cached --name-only | xargs grep -l "AIza\|sk_live\|pk_live\|ghp_" 2>/dev/null
```

If this returns any files, you have a leak. Unstage those files immediately.

---

## If Keys Are Accidentally Committed

If you accidentally commit a key to git:

1. **Immediately rotate the key** in the service's dashboard (Firebase Console, etc.)
2. Remove the file from git history:
   ```bash
   # Install git-filter-repo (brew install git-filter-repo)
   git filter-repo --path .env --invert-paths
   ```
3. Force push (if already pushed):
   ```bash
   git push --force-with-lease
   ```
4. Update the new key in your `.env` file
5. Run `make gen` to regenerate with the new key

---

## Firebase-Specific Security Notes

Firebase API keys are **not traditional server secrets**. They are client identifiers — similar to a public key. However, you should still protect them because:

1. **Quota abuse** — Someone could use your key to make API calls on your billing account
2. **Spam/abuse** — Unauthenticated access to Firebase services
3. **Enumeration** — Revealing project structure

**The real security** comes from:
- **Firebase Security Rules** (Firestore, Storage, Realtime Database)
- **App Check** — Verifies requests come from your genuine app
- **Auth providers** — Only authenticated users can access data

Even with `envied` protecting your keys, **always configure Firebase Security Rules** as if the keys were public.

---

## Quick Reference

| Action | Command |
|--------|---------|
| Add new key | Edit `.env` + `env.dart`, run `make gen` |
| Regenerate after .env change | `make gen` |
| Check for leaked keys | `git diff --cached \| xargs grep "AIza"` |
| Setup on new machine | `cp .env.example .env`, fill values, `make gen` |
| CI/CD setup | Store keys in GitHub Secrets, generate `.env` in workflow |
