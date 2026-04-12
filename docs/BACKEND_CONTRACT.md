# Backend Contract (Android-first)

## 1) Auth Sync
- Method: `POST`
- Path: `BACKEND_AUTH_PATH` (default `/api/users/sync`)
- Header:
  - `Authorization: Bearer <firebase-id-token>`
  - `Content-Type: application/json`
- Body:
  - `nickname` (optional string)

Example:
```json
{
  "nickname": "honggildong"
}
```

Accepted response examples:
```json
{
  "status": "success",
  "user": {
    "id": 1,
    "firebaseUid": "uid",
    "email": "user@example.com",
    "provider": "google",
    "nickname": "honggildong",
    "isNewUser": true,
    "profileImageUrl": "https://..."
  }
}
```

```json
{
  "status": "success",
  "isNewUser": false,
  "user": {
    "nickname": "honggildong"
  }
}
```

## 2) Profile Update
- Method: `PATCH`
- Path: `BACKEND_PROFILE_PATH` (default `/api/users/me`)
- Header:
  - `Authorization: Bearer <firebase-id-token>`
  - `Content-Type: application/json`
- Body:
  - `nickname` (required string)
  - `profileImageUrl` (optional string)
  - `profileImageDataUrl` (optional string, Data URL)
  - `profileImageBase64` (optional string, Data URL)

Image field notes:
- Current frontend sends compatibility payload for mock/real transition.
- If backend only supports one field, `profileImageDataUrl` or `profileImageUrl` 둘 중 하나만 읽어도 동작하도록 구현 권장.

## 3) Android Local Run
```bash
flutter run --dart-define=BACKEND_BASE_URL=http://10.0.2.2:3000
```

Optional:
```bash
flutter run --dart-define=BACKEND_BASE_URL=http://10.0.2.2:3000 --dart-define=BACKEND_AUTH_PATH=/api/users/sync --dart-define=BACKEND_PROFILE_PATH=/api/users/me
```

## 4) Timeout Config
- `BACKEND_CONNECT_TIMEOUT_SEC` (default `10`)
- `BACKEND_SEND_TIMEOUT_SEC` (default `15`)
- `BACKEND_RECEIVE_TIMEOUT_SEC` (default `15`)

These values are already wired in frontend `Dio` options.
