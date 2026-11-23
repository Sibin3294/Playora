# Playora (GuessGame)

Monorepo for the Playora game hub.

```
GuessGame/
  frontend/   # Flutter player app (Playora)
  admin/      # Flutter admin console (catalog CMS)
  backend/    # Express API (gameplay + catalog + admin)
```

## Frontend (Flutter)

```bash
cd frontend
flutter pub get
flutter run -d chrome --web-port=51889 --dart-define=API_PORT=3100 --dart-define=API_HOST=<your-lan-ip>
```

On the Number Hunter home screen, look for **GUEST SESSION** or **SIGNED IN** (not **OFFLINE PLAY**) to confirm the API is connected.

## Backend (API)

Defaults to port **3100** (matches the Flutter app).

```bash
cd backend
npm install
npm run dev
```

Requires MongoDB at `mongodb://127.0.0.1:27017/number_hunter` (or set `MONGODB_URI`).

**Number Hunter** (auth, players, hunts, history) uses this API. If the API is down, guests can still play offline locally; when the API is up, hunts run on the server.

**Cricket private rooms** (`/api/rooms`) also use this API for create/join/lobby. Exhibition and league cricket stay fully on-device.

## Admin (Flutter)

Manage hub categories and Face Reveal players. Publishes into `backend/src/catalog/data/` for the player app.

```bash
cd admin
flutter pub get
flutter run -d chrome --web-port=8090
```

Default login: `admin@playora.local` / `playora-admin`  
(override with `ADMIN_EMAIL` / `ADMIN_PASSWORD` on the API)

## Deploy (Render)

See [DEPLOY_RENDER.md](DEPLOY_RENDER.md). Blueprint file: `render.yaml` (API + Admin).
Requires a Git remote + MongoDB Atlas `MONGODB_URI`.
