# Three Degrees of Doubt Frontend

사기 예방 시뮬레이터(Flutter) 프론트엔드 프로젝트입니다.  
현재는 로그인 UI와 기본 라우팅 흐름, 홈/프로필의 `준비중` 화면까지 구현된 상태입니다.

## 현재 구현 범위
- 다크 테마 기반 로그인 화면 (`ScamShield`)
- 이메일/비밀번호 입력, 비밀번호 표시 토글
- 로그인 버튼 활성화 조건(이메일/비밀번호 입력 여부)
- 이메일 로그인/Google 로그인 Mock 처리
- 로그인 성공 시 홈 화면(`/main`) 이동
- 홈 화면에서 프로필 화면(`/profile`) 이동
- 홈/프로필 화면 `준비중입니다` UI

## 라우트
- `/login`: 로그인 화면
- `/main`: 홈 화면(준비중)
- `/profile`: 프로필 화면(준비중)

## 프로젝트 구조
```text
three_degress_of_doubt_frontend
├─ lib
│  ├─ app
│  ├─ core
│  │  ├─ theme
│  │  ├─ utils
│  │  └─ widgets
│  ├─ features
│  │  ├─ auth
│  │  │  ├─ application
│  │  │  ├─ data
│  │  │  └─ presentation
│  │  │     └─ screens
│  │  │        └─ login_screen.dart
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
│  │  │        └─ profile_screen.dart
│  │  └─ chat
│  │     ├─ data
│  │     ├─ domain
│  │     └─ presentation
│  │        ├─ screens
│  │        └─ widgets
│  └─ main.dart
├─ pubspec.yaml
└─ README.md
```

## 실행 방법
1. Flutter SDK 설치 확인
2. 의존성 설치
```bash
flutter pub get
```
3. 앱 실행
```bash
flutter run
```

## 현재 동작 시나리오
1. 앱 시작 시 `/login` 진입
2. 이메일/비밀번호 입력 후 `로그인` 클릭
3. 1초 로딩 후 `/main` 이동
4. 홈에서 프로필 아이콘 또는 `프로필로 이동` 버튼 클릭 시 `/profile` 이동

## 참고
- 현재 로그인/Google 로그인은 API 연동 전 임시 Mock 동작입니다.
- `회원가입`, 실제 인증, 채팅/스테이지 기능은 이후 구현 예정입니다.
