import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart' as ul;

import 'package:hswarehouse/app/theme/app_theme.dart';
import 'branch_iframe_stub.dart'
    if (dart.library.html) 'branch_iframe_web.dart';

class BranchAppViewerScreen extends StatelessWidget {
  const BranchAppViewerScreen({
    super.key,
    required this.appId,
    required this.title,
    required this.launchUrl,
  });

  final String appId;
  final String title;
  final String launchUrl;

  Future<void> _openExternal() async {
    final uri = Uri.tryParse(launchUrl);
    if (uri == null) return;
    await ul.launchUrl(uri, mode: ul.LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/'),
              ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Open externally',
                onPressed: _openExternal,
                icon: const Icon(Icons.open_in_new),
              ),
            ],
          ),
        ),
        Expanded(
          child: launchUrl.isEmpty
              ? const Center(
                  child: Text(
                    '실행 URL이 없습니다.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              : kIsWeb
                  ? BranchIFrame(
                      url: launchUrl,
                      viewType: 'branch-app-$appId',
                    )
                  : _MobileFallback(
                      launchUrl: launchUrl,
                      onOpen: _openExternal,
                    ),
        ),
      ],
    );
  }
}

class _MobileFallback extends StatelessWidget {
  const _MobileFallback({
    required this.launchUrl,
    required this.onOpen,
  });

  final String launchUrl;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.rocket_launch, size: 48, color: AppTheme.neon),
            const SizedBox(height: 16),
            const Text(
              '모바일에서는 외부 브라우저로 브랜치앱을 실행합니다.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            Text(
              launchUrl,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.neonAlt, fontSize: 12),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new),
              label: const Text('지금 실행'),
            ),
          ],
        ),
      ),
    );
  }
}
