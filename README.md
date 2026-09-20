# hswarehouse

The 1st Projects Warehouse — Flutter 메인앱으로 수백 개의 브랜치앱(미니 프로젝트)을 전시하고 연결합니다.

## Stack

- Flutter (Web / Android / iOS)
- Firebase Auth · Firestore · Storage · Analytics
- GitHub → Netlify CI/CD (웹 배포)

## Architecture (Feature-Sliced Design)

```
lib/
  app/           # app bootstrap, router, theme
  entities/      # BranchApp, AppUser
  features/      # home, auth, upload, admin, guidelines, viewer
  processes/     # auth_service, firestore_service
  shared/        # config, breakpoints, AppShell, cards
  main.dart
  firebase_options.dart
```

## Responsive layout

| Breakpoint | Layout |
|---|---|
| **≥ 769px** (desktop) | 왼쪽 사이드바 + 오른쪽 메인(상단 탭) |
| **≤ 768px** (mobile) | 상단 가로 네비 + 아래 메인 콘텐츠 |

`Breakpoints.desktop = 769` — `LayoutBuilder` / `MediaQuery`로 자동 전환합니다.

## Screens

| Feature | 역할 |
|---|---|
| Home | 승인된 브랜치앱 카드 그리드, 검색, 실행 |
| Login | Google / Email / Phone |
| Upload | 회원 전용 업로드 → `pending` |
| Admin | 승인/거절 → `approved` / `rejected` |
| Guidelines | DB 인덱스 · 코딩 규칙 · 체크리스트 |
| Viewer | 브랜치앱 iframe / 외부 실행 |

## Quick start

```bash
flutter pub get
flutter run -d chrome
```

## Firebase

- Project ID: `hswarehouse`
- Collections:
  - `branchApps` — 브랜치앱 메타데이터 (`status`, `createdAt` 필수)
  - `users` — 회원 프로필
  - `admins/{uid}` — `role` = `superadmin`

## Auth

Firebase Console → Authentication:

- Email/Password ✅
- Google ✅
- Phone (웹 reCAPTCHA)

## Deploy (GitHub → Netlify)

`netlify.toml`이 Flutter SDK를 설치하고 `flutter build web`을 실행합니다.

1. GitHub repo를 Netlify에 연결
2. Netlify 환경변수에 Firebase / `.env` 키 설정 (`GEMINI_API_KEY`, OAuth client id 등)
3. `main` 병합 또는 PR 브랜치 push 시 자동 빌드

로컬 / Firebase Hosting:

```bash
flutter build web --release
npx firebase-tools deploy --only hosting --project hswarehouse
```

## Upload flow

1. Github branch에 미니프로젝트 push  
2. Upload에서 메타데이터 입력 (+ 가능하면 Netlify 실행 URL)  
3. `pending` → Admin 승인 → `approved` → Home 노출  

## Environment

`.env.local`은 gitignore됩니다. 키는 `AppEnv.*`로 호출합니다.

```dart
AppEnv.geminiApiKey;
AppEnv.oauthClientId;
AppEnv.googleDriveWebAppUrl;
```
