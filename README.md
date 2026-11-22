# Collector

Scan a coin or banknote, let Claude identify it, and keep your own notes on every piece.

**Web app:** https://eyadoraby.github.io/collector/ · **Android:** [latest APK](https://github.com/EyadOraby/collector/releases/tag/android)

## What it does

- **Scan** with the camera or pick a photo
- **Identify** the country, denomination, currency, year or era, material and what the piece shows, using Claude (`claude-opus-5-5`) with a JSON schema, so the answer always comes back as clean fields
- **Check and edit** every field, then add your own notes: where it came from, its condition, the story
- **Browse** coins and banknotes in a cabinet-style grid, with counts by kind and country
- **Export** the collection as `collection.json` with small photos, for the Coins and banknotes page on my portfolio

## Your key stays on your device

Identification needs an Anthropic API key, entered in Settings. It is stored on the device only (IndexedDB on the web) and sent only to `api.anthropic.com`. There is no server in between. Without a key, the app still works and you fill in the details yourself.

## How it is built

- Flutter for Android and the web; Hive for entries and photos on the device
- `lib/data/identifier.dart`: one Messages API call with the photo, structured output, a fallback model if the request is declined, and plain-language errors
- `lib/data/store.dart`: the collection, the key and the export with JPEG thumbnails
- Tests cover the request shape and error handling (with a mocked client), storage and export, and the scan-to-save flow
- CI checks formatting, analysis and tests on every pull request, then deploys the web app and builds the APK from `main`

## Run it

```sh
flutter pub get
flutter run -d chrome
```

MIT licence.
