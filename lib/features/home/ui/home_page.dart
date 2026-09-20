import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as ul;

import 'package:hswarehouse/app/theme/app_theme.dart';
import 'package:hswarehouse/entities/branch_app/branch_app.dart';
import 'package:hswarehouse/processes/data/auth_service.dart';
import 'package:hswarehouse/processes/data/firestore_service.dart';
import 'package:hswarehouse/shared/config/breakpoints.dart';
import 'package:hswarehouse/shared/ui/branch_app_card.dart';
import 'package:hswarehouse/shared/ui/neon_background.dart'
    show responsiveGridCount;

enum HomeFeedMode { overview, newest, popular }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.mode = HomeFeedMode.overview});

  final HomeFeedMode mode;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String _query = '';
  bool _adminRefreshScheduled = false;
  late final AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_adminRefreshScheduled) return;
    _adminRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthService>().refreshAdminStatus();
    });
  }

  String get _title => switch (widget.mode) {
        HomeFeedMode.overview => '개요',
        HomeFeedMode.newest => '신규 프로젝트',
        HomeFeedMode.popular => '인기 프로젝트',
      };

  String get _subtitle => switch (widget.mode) {
        HomeFeedMode.overview => '승인된 브랜치앱을 AI 아카이브에서 탐색하세요.',
        HomeFeedMode.newest => '최근 등록·승인된 프로젝트를 확인하세요.',
        HomeFeedMode.popular => '주목받는 브랜치앱을 모았습니다.',
      };

  List<BranchApp> _applyMode(List<BranchApp> apps, {required bool mobile}) {
    final list = [...apps];
    if (mobile) {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }
    switch (widget.mode) {
      case HomeFeedMode.overview:
        return list;
      case HomeFeedMode.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      case HomeFeedMode.popular:
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        return list;
    }
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await ul.launchUrl(uri, mode: ul.LaunchMode.externalApplication);
  }

  Future<void> _openApp(BranchApp app) async {
    final url = app.effectiveLaunchUrl;
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Launch URL이 없습니다.')),
      );
      return;
    }

    if (!app.canEmbedInIFrame) {
      await _openExternal(url);
      return;
    }

    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(app.name, style: AppTheme.display(18)),
                const SizedBox(height: 8),
                Text(
                  app.description.isEmpty ? '설명이 없습니다.' : app.description,
                  style: AppTheme.body(14, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, 'iframe'),
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('앱 실행 (인앱)'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, 'external'),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('외부 링크로 열기'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || choice == null) return;

    if (choice == 'external') {
      await _openExternal(url);
      return;
    }

    final encoded = Uri.encodeComponent(url);
    context.push(
      '/app/${app.id}?title=${Uri.encodeComponent(app.name)}&url=$encoded',
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<BranchAppService>();
    final width = MediaQuery.sizeOf(context).width;
    final mobile = Breakpoints.isMobile(width);
    final pad = mobile ? 16.0 : 28.0;

    return FadeTransition(
      opacity: CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(pad, mobile ? 12 : 20, pad, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.hairline),
                    color: AppTheme.neon.withValues(alpha: 0.08),
                  ),
                  child: Text(
                    'NEURAL ARCHIVE',
                    style: AppTheme.body(
                      10,
                      weight: FontWeight.w700,
                      color: AppTheme.neon,
                    ).copyWith(letterSpacing: 1.8),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _title,
                  style: AppTheme.display(mobile ? 26 : 32),
                ),
                const SizedBox(height: 6),
                Text(
                  _subtitle,
                  style: AppTheme.body(14, color: AppTheme.textSecondary),
                ),
                SizedBox(height: mobile ? 12 : 16),
                TextField(
                  onChanged: (value) => setState(() => _query = value.trim()),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.auto_awesome_outlined),
                    hintText: '브랜치앱 검색 (이름 / 제작자)',
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<BranchApp>>(
              stream: service.watchApprovedApps(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        '브랜치앱을 불러오지 못했습니다.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style:
                            AppTheme.body(14, color: AppTheme.textSecondary),
                      ),
                    ),
                  );
                }

                var apps = _applyMode(
                  snapshot.data ?? const <BranchApp>[],
                  mobile: mobile,
                );
                apps = apps.where((app) {
                  if (_query.isEmpty) return true;
                  final q = _query.toLowerCase();
                  return app.name.toLowerCase().contains(q) ||
                      app.creator.toLowerCase().contains(q) ||
                      app.description.toLowerCase().contains(q);
                }).toList();

                if (apps.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        '표시할 브랜치앱이 없습니다.\nUpload에서 프로젝트를 올려보세요.',
                        textAlign: TextAlign.center,
                        style:
                            AppTheme.body(14, color: AppTheme.textSecondary),
                      ),
                    ),
                  );
                }

                if (mobile) {
                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(pad, 4, pad, 28),
                    itemCount: apps.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final app = apps[index];
                      return SizedBox(
                        height: 168,
                        child: BranchAppCard(
                          app: app,
                          onTap: () => _openApp(app),
                        ),
                      );
                    },
                  );
                }

                final crossAxisCount = responsiveGridCount(width);
                return GridView.builder(
                  padding: EdgeInsets.fromLTRB(pad, 4, pad, 28),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.86,
                  ),
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final app = apps[index];
                    return BranchAppCard(
                      app: app,
                      onTap: () => _openApp(app),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
