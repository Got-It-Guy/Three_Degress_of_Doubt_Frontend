# Firebase Auth Roadmap (Flutter Frontend + Backend Verification)

## 1) Firebase 프로젝트/권한
1. Firebase 콘솔에서 프로젝트 생성
2. `프로젝트 설정 > 사용자 및 권한(IAM)`에서 백엔드 담당자 계정 추가
3. 최소 2명 관리자(Owner) 체제로 운영

## 2) Firebase 콘솔 기본 세팅
1. `Authentication > Sign-in method`에서 `Email/Password` 활성화
2. `Google` 로그인 활성화
3. Android 앱 등록 시 패키지명 입력, SHA-1 등록

## 3) Flutter 연결
```bash
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
flutter pub add firebase_core firebase_auth google_sign_in
```

`main.dart` 초기화 예시:
```dart
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
runApp(const MainApp());
```

## 4) 프론트 인증 구현
1. 이메일 로그인: `signInWithEmailAndPassword`
2. 이메일 회원가입: `createUserWithEmailAndPassword`
3. 구글 로그인: `google_sign_in` + `FirebaseAuth.instance.signInWithCredential`
4. 로그인 후 `getIdToken()`으로 Firebase ID 토큰 획득

## 5) 백엔드 인증 연동
1. 프론트가 ID 토큰을 백엔드로 전달 (권장: `Authorization: Bearer <idToken>`)
2. `nickname`은 요청 body로 전달
3. 백엔드는 Admin SDK로 `verifyIdToken()` 검증
4. `uid/email/provider`로 사용자 upsert 후 결과 반환

예시 응답:
```json
{
  "status": "success",
  "user": {
    "id": 12,
    "firebaseUid": "abc123",
    "email": "abc@abc.com",
    "provider": "google",
    "nickname": "honggildong",
    "isNewUser": false
  }
}
```

## 6) URL 미정 상태 대응
1. `API_BASE_URL`을 `--dart-define` 또는 `.env`로 분리
2. URL 없으면 Mock 모드로 동작
3. URL 확정 시 실제 API 구현만 교체

## 7) 검증 체크리스트
1. 이메일 로그인/회원가입 성공, 실패 케이스
2. 구글 로그인 성공/취소/실패
3. 토큰 전달 및 백엔드 검증 성공
4. `isNewUser` 분기 동작
5. 앱 재시작 시 인증 상태 복원
