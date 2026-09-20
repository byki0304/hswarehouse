import 'package:flutter/material.dart';

import 'package:hswarehouse/app/theme/app_theme.dart';

class BranchIFrame extends StatelessWidget {
  const BranchIFrame({
    super.key,
    required this.url,
    required this.viewType,
  });

  final String url;
  final String viewType;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          '이 플랫폼에서는 iframe을 지원하지 않습니다.\n$url',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}
