import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hswarehouse/app/theme/app_theme.dart';
import 'package:hswarehouse/processes/data/auth_service.dart';
import 'package:hswarehouse/shared/config/breakpoints.dart';
import 'package:hswarehouse/shared/ui/hs_warehouse_logo.dart';
import 'package:hswarehouse/shared/ui/neon_background.dart';

/// Shared responsive shell:
/// - Desktop (>=769): dense sidebar + luminous main
/// - Mobile (<=768): top horizontal nav + main content
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const double sidebarWidth = 280;

  Future<void> _confirmLogout(BuildContext context, AuthService auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.hairline),
          ),
          title: Text('로그아웃', style: AppTheme.display(18)),
          content: Text(
            '로그아웃 하시겠어요?',
            style: AppTheme.body(14, color: AppTheme.textSecondary),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(dialogContext, true),
                icon: const Icon(Icons.logout),
                label: const Text('로그아웃'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('취소'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    await auth.signOut();
    if (!context.mounted) return;
    context.go('/');
  }

  double _viewportWidth(BuildContext context, BoxConstraints constraints) {
    final mediaWidth = MediaQuery.sizeOf(context).width;
    final maxW = constraints.maxWidth;
    if (!maxW.isFinite) return mediaWidth;
    return maxW < mediaWidth ? maxW : mediaWidth;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final location = GoRouterState.of(context).uri.path;

    return NeonBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final width = _viewportWidth(context, constraints);
            final desktop = Breakpoints.isDesktop(width);

            if (desktop) {
              return Row(
                children: [
                  _Sidebar(
                    auth: auth,
                    onLogout: () => _confirmLogout(context, auth),
                  ),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppTheme.mainPanel.withValues(alpha: 0.42),
                        border: const Border(
                          left: BorderSide(color: AppTheme.hairline, width: 1),
                        ),
                      ),
                      child: Column(
                        children: [
                          _DesktopTopBar(location: location, auth: auth),
                          Expanded(child: child),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MobileNavBar(
                  auth: auth,
                  location: location,
                  onLogout: () => _confirmLogout(context, auth),
                ),
                Expanded(child: child),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.auth, required this.onLogout});

  final AuthService auth;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppShell.sidebarWidth,
      decoration: const BoxDecoration(
        color: AppTheme.sidebar,
        border: Border(
          right: BorderSide(color: AppTheme.hairline),
        ),
      ),
      child: Stack(
        children: [
          // Dense panel texture — different from open main field
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.neon.withValues(alpha: 0.06),
                    AppTheme.sidebar,
                    AppTheme.sidebar,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 32, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const HsWarehouseLogo(),
                  const SizedBox(height: 10),
                  Text(
                    'AI PROJECTS ARCHIVE',
                    textAlign: TextAlign.center,
                    style: AppTheme.body(
                      10,
                      weight: FontWeight.w700,
                      color: AppTheme.steel,
                    ).copyWith(letterSpacing: 2.2),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    height: 1,
                    color: AppTheme.hairline,
                  ),
                  const SizedBox(height: 24),
                  _AuthButton(auth: auth, onLogout: onLogout),
                  const Spacer(),
                  Text(
                    'Curated branch apps\nbuilt with Cursor & AI',
                    textAlign: TextAlign.center,
                    style: AppTheme.body(
                      11,
                      color: AppTheme.textSecondary.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileNavBar extends StatelessWidget {
  const _MobileNavBar({
    required this.auth,
    required this.location,
    required this.onLogout,
  });

  final AuthService auth;
  final String location;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final homeSelected = location == '/'
        ? 0
        : location == '/new'
            ? 1
            : location == '/popular'
                ? 2
                : -1;

    return Material(
      color: AppTheme.sidebar,
      child: SafeArea(
        bottom: false,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppTheme.hairline),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 10, 6),
                child: Row(
                  children: [
                    const Expanded(
                      child: HsWarehouseLogo(compact: true),
                    ),
                    const SizedBox(width: 8),
                    _AuthButton(
                      auth: auth,
                      onLogout: onLogout,
                      compact: true,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  children: [
                    _NavChip(
                      label: '개요',
                      selected: homeSelected == 0,
                      onTap: () => context.go('/'),
                    ),
                    _NavChip(
                      label: '신규 프로젝트',
                      selected: homeSelected == 1,
                      onTap: () => context.go('/new'),
                    ),
                    _NavChip(
                      label: '인기 프로젝트',
                      selected: homeSelected == 2,
                      onTap: () => context.go('/popular'),
                    ),
                    const SizedBox(width: 4),
                    _NavIcon(
                      tooltip: 'Developer Guidelines',
                      icon: Icons.menu_book_outlined,
                      selected: location == '/guidelines',
                      onTap: () => context.go('/guidelines'),
                    ),
                    _NavIcon(
                      tooltip: 'Upload',
                      icon: Icons.cloud_upload_outlined,
                      selected: location == '/upload',
                      onTap: () {
                        if (!auth.isSignedIn) {
                          context.go('/login');
                          return;
                        }
                        context.go('/upload');
                      },
                    ),
                    _NavIcon(
                      tooltip: 'Admin Panel',
                      icon: Icons.admin_panel_settings,
                      selected: location == '/admin',
                      accent: auth.isAdmin,
                      onTap: () {
                        if (!auth.isSignedIn) {
                          context.go('/login');
                          return;
                        }
                        context.go('/admin');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({
    required this.location,
    required this.auth,
  });

  final String location;
  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    final homeSelected = location == '/'
        ? 0
        : location == '/new'
            ? 1
            : location == '/popular'
                ? 2
                : -1;

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.mainPanel.withValues(alpha: 0.55),
        border: const Border(
          bottom: BorderSide(color: AppTheme.hairline),
        ),
      ),
      child: Row(
        children: [
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _NavChip(
                    label: '개요',
                    selected: homeSelected == 0,
                    onTap: () => context.go('/'),
                  ),
                  _NavChip(
                    label: '신규 프로젝트',
                    selected: homeSelected == 1,
                    onTap: () => context.go('/new'),
                  ),
                  _NavChip(
                    label: '인기 프로젝트',
                    selected: homeSelected == 2,
                    onTap: () => context.go('/popular'),
                  ),
                ],
              ),
            ),
          ),
          _NavIcon(
            tooltip: 'Developer Guidelines',
            icon: Icons.menu_book_outlined,
            selected: location == '/guidelines',
            onTap: () => context.go('/guidelines'),
          ),
          _NavIcon(
            tooltip: 'Upload',
            icon: Icons.cloud_upload_outlined,
            selected: location == '/upload',
            onTap: () {
              if (!auth.isSignedIn) {
                context.go('/login');
                return;
              }
              context.go('/upload');
            },
          ),
          _NavIcon(
            tooltip: 'Admin Panel',
            icon: Icons.admin_panel_settings,
            selected: location == '/admin',
            accent: auth.isAdmin,
            onTap: () {
              if (!auth.isSignedIn) {
                context.go('/login');
                return;
              }
              context.go('/admin');
            },
          ),
        ],
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.auth,
    required this.onLogout,
    this.compact = false,
  });

  final AuthService auth;
  final VoidCallback onLogout;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (auth.isSignedIn) {
      return OutlinedButton.icon(
        onPressed: onLogout,
        icon: const Icon(Icons.logout, size: 16),
        label: const Text('로그아웃'),
        style: OutlinedButton.styleFrom(
          visualDensity: compact ? VisualDensity.compact : null,
        ),
      );
    }
    return ElevatedButton(
      onPressed: () => context.go('/login'),
      style: ElevatedButton.styleFrom(
        visualDensity: compact ? VisualDensity.compact : null,
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : null,
      ),
      child: Text(compact ? '로그인' : '로그인 / 회원가입'),
    );
  }
}

class _NavChip extends StatelessWidget {
  const _NavChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor:
              selected ? AppTheme.neon : AppTheme.textSecondary,
          backgroundColor: selected
              ? AppTheme.neon.withValues(alpha: 0.1)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: selected
                  ? AppTheme.neon.withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
          ),
        ),
        child: Text(
          label,
          style: AppTheme.body(
            13,
            weight: selected ? FontWeight.w800 : FontWeight.w500,
            color: selected ? AppTheme.neon : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.accent = false,
  });

  final String tooltip;
  final IconData icon;
  final bool selected;
  final bool accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppTheme.neon
        : (accent ? AppTheme.neonAlt : AppTheme.textPrimary);

    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, color: color),
    );
  }
}
