import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:hswarehouse/app/theme/app_theme.dart';

class DeveloperGuidelinesScreen extends StatelessWidget {
  const DeveloperGuidelinesScreen({super.key});

  static const String guidelines = '''
# Developer Guidelines

`hswarehouse`에 브랜치앱을 업로드하기 전에 아래 규칙을 확인하세요.

## 필수 DB 인덱스 구조

### Firebase Firestore
- 컬렉션: `branchApps`
- 필수 필드: `createdAt`, `status`
- 권장 복합 인덱스: `status ASC` + `createdAt DESC`

### Supabase
- 필수 컬럼: `id`, `created_at`
- 브랜치앱 자체 DB는 제작자가 독립적으로 운영합니다.

## 필수 코딩 규칙

1. 모든 브랜치앱은 최소한 `main.dart` 또는 `index.js` 진입점을 명시합니다.
2. DB 연결 정보는 `.env` / `.env.local` 파일에 저장하고 Git에 커밋하지 않습니다.
3. API endpoint는 `/api` prefix를 사용합니다.
4. 메인앱은 전시/연결만 담당합니다. 운영·장애 대응은 각 브랜치앱 제작자가 직접 관리합니다.

## 업로드 체크리스트

- [ ] Github branch URL이 정상적으로 열리는지 확인
- [ ] 아이콘 이미지 URL이 유효한지 확인 (또는 이미지 파일 업로드)
- [ ] 설명은 **200자 이내**로 요약
- [ ] 제작자 이름/팀명을 기재
- [ ] 실행 URL(Netlify/Hosting 등)을 가능하면 함께 입력

## 업로드 프로세스

1. 미니프로젝트를 Github branch에 push
2. 메인앱 **Upload** 화면에서 메타데이터 입력
3. Firebase 저장 → `status = "pending"`
4. 관리자 승인 → `status = "approved"` → 메인화면 자동 노출

## 운영 원칙

- 비회원도 승인된 브랜치앱을 실행할 수 있습니다.
- 회원만 업로드할 수 있습니다.
- 관리자만 승인/거절할 수 있습니다.
''';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Markdown(
            data: guidelines,
            padding: const EdgeInsets.all(24),
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              h1: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
              h2: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.neon,
              ),
              p: const TextStyle(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
              listBullet: const TextStyle(color: AppTheme.neonAlt),
              code: TextStyle(
                backgroundColor: AppTheme.surface,
                color: AppTheme.neonAlt,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
