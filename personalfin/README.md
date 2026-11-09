# PersonalFin Flutter App

## Local Development

Run the app with its default local API URL:

```powershell
flutter run
```

For an Android emulator or a physical device, pass a host address reachable from that device:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

## Release Build

Release builds require the deployed HTTPS API URL:

```powershell
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.example.com/api/v1
```

Android release signing uses `android/key.properties` and a private keystore. That file and keystore are ignored by Git; never commit them. Configure `storeFile`, `storePassword`, `keyAlias`, and `keyPassword` in the local properties file before creating a release build.

## Deploy the API

The repository includes a Render Blueprint at its root. Push the repository to GitHub, then create a Blueprint in Render using that repository. During setup, provide:

- `MONGODB_URI`: a reachable MongoDB Atlas connection string
- `GEMINI_API_KEY`: the Gemini API key

Render generates the JWT secrets and provides an HTTPS service URL after deployment. The API health check is `/health`, and API routes use `/api/v1`. Use the Render URL as `API_BASE_URL` when building the mobile release.

Browser clients need their HTTPS origin listed in `CORS_ORIGINS`; native mobile clients do not use browser CORS.

The Blueprint uses Render's free web-service plan for initial testing only. Render free services can sleep and are explicitly not recommended for production apps. Also, phone OTP is unavailable in production until a production login provider is configured; development OTP remains disabled there.
