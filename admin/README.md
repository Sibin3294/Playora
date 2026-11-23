# Playora Admin

Flutter admin console for Playora catalog content. Lives next to `frontend/` and `backend/`.

## Run

1. Start the API (`backend`, port 3100).
2. From this folder:

```bash
flutter pub get
flutter run -d chrome --web-port=8090
```

## Publish folder (Render static)

Render serves the prebuilt `admin/publish/` directory (Flutter is not installed on Render static builds).

```bash
./scripts/build_publish.sh https://playora-api.onrender.com
```

Commit `admin/publish/` after rebuilding whenever Admin UI changes.

Default local login:

- email: `admin@playora.local`
- password: `playora-admin`

Override with env vars on the API:

- `ADMIN_EMAIL`
- `ADMIN_PASSWORD`
- `ADMIN_JWT_SECRET`

Point the admin app at another API:

```bash
flutter run -d chrome --web-port=8090 --dart-define=API_BASE=http://127.0.0.1:3100
```

## What it manages today

- Overview counts
- Sports rosters — national + IPL teams/players (roles, ratings, overseas)
- Face Reveal players (add / edit / delete + publish)
- Hub categories & game metadata (titles, taglines, availability)

Publishing writes JSON under `backend/src/catalog/data/` and refreshes the API cache. The player app reads the same catalog via `GET /api/catalog`.

## Not covered yet

- Uploading puzzle images
- Venue editor UI
- Creating brand-new game *engines* (still needs Flutter screens in `frontend`)
