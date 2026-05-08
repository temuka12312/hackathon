# hackathon

This repository now contains:

- `frontend/`: Flutter client
- `backend/`: Express API

## Run backend

```bash
cd backend
npm install
npm run dev
```

Default port is `3000`.

## Run frontend

```bash
cd frontend
flutter pub get
flutter run
```

The Flutter app calls the backend health endpoint:

- Android emulator: `http://10.0.2.2:3000/api/health`
- iOS simulator / macOS / Windows / Linux: `http://localhost:3000/api/health`
- Web: `http://localhost:3000/api/health`
