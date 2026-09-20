# HS Warehouse — 재개 가이드

마지막 저장: **2026-09-21** · Git commit `9acdca7` · branch `main`  
코드·DB·배포는 **종료하지 않음**. Firebase / Netlify는 그대로 실시간 테스트 가능.

---

## 현재 상태 (건드리지 말 것)

| 항목 | 값 | 상태 |
|---|---|---|
| GitHub | https://github.com/byki0304/hswarehouse | `main` = `9acdca7` synced |
| 라이브 사이트 | https://hswarehouse.netlify.app/ | 운영 중 (GitHub `main` push → 자동 빌드) |
| Firebase 프로젝트 | `hswarehouse` (`584793321765`) | ACTIVE |
| Auth | Email / Google / Phone | 유지 |
| Firestore | `branchApps`, `users`, `admins` | 유지 |
| Storage | Firebase Storage rules 배포됨 | 유지 |
| Authorized domain | `hswarehouse.netlify.app` 포함 | 유지 |

**하지 말 것:** Firebase 프로젝트 삭제/일시중지, Netlify 사이트 삭제, Firestore 데이터 삭제, Auth 사용자 일괄 삭제, Netlify env 비우기.

---

## 계정 / 권한

- GitHub 작업 계정: **byki0304** (`byki0304/hswarehouse`)
- Superadmin Firestore `admins/{uid}`:
  - `byki0304` → UID `6Kg29HzU3fewHvuLTZkrHb2fidW2` · `role: superadmin`
  - (기존) `byki6768` 관련 admin도 있을 수 있음 — 삭제하지 말 것

---

## 로컬에서 다시 시작할 때

```bash
cd "C:\Users\HS Kim\Desktop\MyProject\hswarehouse"
git pull origin main
flutter pub get
```

1. `.env.local`이 없으면 `.env.example`을 복사해 채운다 (gitignore — **커밋 금지**).
2. 로컬 실행:
   ```bash
   flutter run -d chrome
   ```
3. 배포 반영: `main`에 push하면 Netlify가 자동 빌드.  
   배포 확인: Netlify dashboard 또는 https://hswarehouse.netlify.app/

### 필수 Netlify 환경변수 (비우지 말 것)

- `GEMINI_API_KEY`
- `OAUTH_CLIENT_ID` (및 `netlify.toml`이 `web/index.html`의 `__OAUTH_CLIENT_ID__`에 주입)
- Firebase 관련 키 (필요 시 `.env.local` 주입용 — `netlify.toml` 참고)

로컬 시크릿은 `.env.local`만 사용. 저장소에는 `.env.example`만 둔다.

---

## 아키텍처 요약 (FSD)

```
lib/
  app/           # bootstrap, router, theme
  entities/      # BranchApp, AppUser
  features/      # home, auth, upload, admin, guidelines, viewer
  processes/     # auth_service, firestore_service, branch_icon_generator
  shared/        # AppShell, breakpoints(769), neon UI, cards
  main.dart
```

- Desktop ≥ **769px**: 사이드바 + 메인  
- Mobile ≤ **768px**: 상단 네비 + 세로 리스트(최신순)

---

## 최근 수정 (재개 시 참고)

1. Netlify 빌드 시 env → `.env.local` 주입 (`netlify.toml`)
2. Google 로그인: `hswarehouse.netlify.app` authorized domain + web popup 인증
3. 로그아웃: 확인 다이얼로그 클릭 관통 방지 + Google 자동 재로그인 차단 (`9acdca7`)

재개 후 권장 스모크 테스트:

- [ ] 홈 로드 / 브랜치앱 목록
- [ ] Google 로그인
- [ ] 로그아웃 확인창 → 취소 / 확정 후 로그인 유지 안 됨
- [ ] Upload → Admin 승인 흐름
- [ ] 모바일(≤768) / 데스크톱(≥769) 레이아웃

---

## Cursor에서 이어서 말하기 예시

> HS Warehouse 이어서. RESUME.md 기준으로 진행. Firebase/Netlify는 유지한 채 …
>
> (원하는 작업: 예) 브랜치앱 업로드 UX 개선 / Admin 필터 / 아이콘 생성 품질 …

이전 대화 컨텍스트가 없으면 이 파일 + README.md + commit `9acdca7`부터 보면 된다.
