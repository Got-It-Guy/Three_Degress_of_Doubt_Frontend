# Three Degrees of Doubt Frontend

사기 예방 시뮬레이터(Flutter) 프론트엔드 프로젝트입니다.

## 현재 구현 범위
- Firebase 이메일 로그인/회원가입
- Google 로그인(Firebase Credential 연동)
- Firebase ID 토큰 기반 백엔드 동기화(`/api/users/sync`)
- 신규 유저 분기: `/profile-setup` 진입
- 초기 프로필 설정(닉네임 + 갤러리 이미지 선택)
- 프로필 저장 API 호출(`/api/users/me`)
- 로그아웃 시 Firebase `signOut()` 실제 호출

## 라우트
- `/login`: 로그인
- `/signup`: 회원가입
- `/profile-setup`: 신규 사용자 초기 프로필 설정
- `/main`: 홈
- `/profile`: 프로필

## 프로젝트 구조
```text
three_degress_of_doubt_frontend
├─ lib
│  ├─ app
│  ├─ core
│  │  ├─ config
│  │  │  └─ backend_config.dart
│  │  ├─ di
│  │  │  └─ app_dependencies.dart
│  │  ├─ theme
│  │  ├─ utils
│  │  └─ widgets
│  ├─ features
│  │  ├─ auth
│  │  │  ├─ application
│  │  │  ├─ data
│  │  │  │  └─ auth_repository.dart
│  │  │  └─ presentation
│  │  │     └─ screens
│  │  │        ├─ login_screen.dart
│  │  │        └─ signup_screen.dart
│  │  ├─ home
│  │  │  ├─ data
│  │  │  ├─ domain
│  │  │  └─ presentation
│  │  │     └─ screens
│  │  │        └─ home_screen.dart
│  │  ├─ profile
│  │  │  ├─ application
│  │  │  ├─ data
│  │  │  ├─ domain
│  │  │  └─ presentation
│  │  │     └─ screens
│  │  │        ├─ profile_screen.dart
│  │  │        └─ profile_setup_screen.dart
│  │  └─ chat
│  │     ├─ data
│  │     ├─ domain
│  │     └─ presentation
│  │        ├─ screens
│  │        └─ widgets
│  ├─ firebase_options.dart
│  └─ main.dart
├─ docs
│  ├─ BACKEND_CONTRACT.md
│  └─ FIREBASE_AUTH_ROADMAP.md
├─ test
│  └─ smoke_test.dart
├─ pubspec.yaml
└─ README.md
```

## Android 실행
1. 의존성 설치
```bash
flutter pub get
```
2. 안드로이드 에뮬레이터/디바이스 실행
3. 앱 실행
```bash
flutter run
```


## 문서
- `docs/BACKEND_CONTRACT.md`: 백엔드 요청/응답 계약, 목서버 호환 필드, Android 실행 예시
