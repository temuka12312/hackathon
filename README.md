# hackathon

This repository contains:

- `frontend/`: Flutter client
- `backend/`: Express API

## Run backend

```bash
cd backend
npm install
npm run dev
```

Default host is `0.0.0.0` and default port is `3030` when `backend/.env` is used.

If your backend needs MongoDB, make sure `MONGO_URL` is set before starting it.

## Run frontend

```bash
cd frontend
flutter pub get
flutter run
```

The Flutter app uses these backend URLs by default:

- Android emulator: `http://10.0.2.2:3030/api/health`
- iOS simulator / macOS / Windows / Linux: `http://localhost:3030/api/health`
- Web: `http://localhost:3030/api/health`

For a real iPhone, pass your computer's LAN IP with `--dart-define`:

```bash
cd frontend
flutter run -d <ios-device-id> --dart-define=API_BASE_URL=http://192.168.1.10:3030
```

Replace `192.168.1.10` with the `Device access` IP printed by the backend.

## iOS notes

- iOS location permission is already configured in `Info.plist`.
- iOS development builds are allowed to call the local HTTP backend.
- Your Mac and iPhone must be on the same Wi-Fi when using a real device.
- If you use a physical iPhone, keep the backend running on your computer.

## User registration

Backend now exposes:

- `POST /api/auth/register`

Request n:

```json
{
  "name": "Temuuka",
  "email": "temuuka@example.com",
  "password": "secret123"
}
```

The Flutter app includes a simple registration form for creating users through
this endpoint.
