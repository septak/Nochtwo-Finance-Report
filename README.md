# Finance (Chat-style) - Minimal Flutter skeleton

What this archive contains:
- `lib/main.dart` — a single-file Flutter app that implements a chat UI, parses Indonesian commands:
  - `masuk <amount> cash|atm` — add income
  - `keluar <amount> cash|atm` — add expense
  - `saldo` — show balances as an info message
- `pubspec.yaml` — lists dependencies (sqflite, path_provider)
- `.github/workflows/build.yml` — GitHub Actions workflow to produce an APK artifact
- `assets/icon.png` — placeholder app icon (replace with your provided icon image)

## How to build (recommended) — GitHub Actions (CI)

1. Create a new repository on GitHub and push the contents of this archive to it.
2. In the repo go to Actions tab — the workflow will run on push to `main`.
3. After the workflow finishes, download the artifact named `finance-apk`.

The workflow will:
- set up Flutter
- run `flutter pub get`
- run `flutter create .` (to generate android folder if missing)
- build a release APK
- upload the APK as an artifact

(Full workflow provided in `.github/workflows/build.yml`.)

## Alternative — build locally (if you can install Flutter SDK)

1. Install Flutter on your machine (https://flutter.dev/docs/get-started/install)
2. From the project root:
   - `flutter pub get`
   - `flutter create .`
   - `flutter build apk --release`
   - Output APK: `build/app/outputs/flutter-apk/app-release.apk`

## Replacing the app icon

I included `assets/icon.png` as a placeholder. To set the actual Android launcher icon:
- Use `flutter_launcher_icons` package (recommended), or
- Replace Android `mipmap-*` files after running `flutter create .`.

## Notes & limitations
- This is a minimal offline demo skeleton — no user authentication, no backups.
- Data is stored locally using `sqflite`.
- The UI is intentionally simple; you can extend message types, editing, categories, export/import later.

