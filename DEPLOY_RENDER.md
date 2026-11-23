# Deploy Playora API + Admin to Render

## What gets deployed

| Service | Type | URL pattern |
|---|---|---|
| `playora-api` | Web (Node) | `https://playora-api.onrender.com` |
| `playora-admin` | Static (Flutter web) | `https://playora-admin.onrender.com` |

Admin publishes catalog changes into **MongoDB** (so they survive Render restarts).

## Prerequisites

1. **GitHub/GitLab/Bitbucket repo** with this project pushed (Render needs a Git remote).
2. **MongoDB Atlas** free cluster (Render does not host Mongo).
   - Create a cluster → Database Access user → Network Access `0.0.0.0/0` (or Render IPs)
   - Copy connection string as `MONGODB_URI`
3. Render account connected to your Git provider.

## Steps

1. Commit and push `render.yaml` (and latest code) to your default branch.
2. Open Blueprint deeplink (replace with your HTTPS repo URL):

   ```
   https://dashboard.render.com/blueprint/new?repo=https://github.com/<YOU>/<REPO>
   ```

3. Fill secrets when prompted:
   - `MONGODB_URI` — Atlas connection string
   - `ADMIN_EMAIL` / `ADMIN_PASSWORD` — admin login
   - `JWT_SECRET` / `ADMIN_JWT_SECRET` — can use generated values
4. Click **Apply** and wait for both services to go live.
5. Open Admin → sign in → confirm Overview loads.
6. Point the **player app** at the live API:

   ```bash
   cd frontend
   flutter run -d chrome --dart-define=API_BASE=https://playora-api.onrender.com
   # APK:
   flutter build apk --dart-define=API_BASE=https://playora-api.onrender.com
   ```

## Notes

- First Admin build installs Flutter on Render and can take 10–20+ minutes.
- Free/starter web services may spin down when idle; first request can be slow.
- Keep local Admin/API for development; production uses the Render URLs above.
