import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:hswarehouse/shared/config/app_constants.dart';
import 'package:hswarehouse/app/theme/app_theme.dart';
import 'package:hswarehouse/entities/branch_app/branch_app.dart';
import 'package:hswarehouse/processes/data/auth_service.dart';
import 'package:hswarehouse/processes/data/firestore_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _checking = true;
  bool _isAdmin = false;
  BranchAppStatus? _filter = BranchAppStatus.pending;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  /// Firestore: admins/{uid} 문서 + role == 'superadmin'
  Future<void> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _checking = false;
        _isAdmin = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.adminsCollection)
          .doc(user.uid)
          .get();
      final data = doc.data();
      final role = (data?['role'] as String?)?.trim().toLowerCase();
      setState(() {
        _isAdmin = doc.exists &&
            (role == null ||
                role.isEmpty ||
                role == 'superadmin' ||
                role == 'admin');
        _checking = false;
      });
    } catch (_) {
      setState(() {
        _isAdmin = false;
        _checking = false;
      });
    }
  }

  Future<void> _setStatus(BranchApp app, BranchAppStatus status) async {
    if (!_isAdmin) return;
    final service = context.read<BranchAppService>();
    try {
      await service.updateStatus(appId: app.id, status: status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${app.name} → ${status.value}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('업데이트 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Admin Panel'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
        ),
        body: _checking
            ? const Center(child: CircularProgressIndicator())
            : !_isAdmin
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        '관리자 권한이 없습니다.\n'
                        'Firestore admins/{UID} 문서에 role = "superadmin" 이 필요합니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  )
                : _AdminBody(
                    filter: _filter,
                    onFilterChanged: (value) => setState(() => _filter = value),
                    onSetStatus: _setStatus,
                    signedInAs: auth.currentUser?.email ?? '',
                  ),
    );
  }
}

class _AdminBody extends StatelessWidget {
  const _AdminBody({
    required this.filter,
    required this.onFilterChanged,
    required this.onSetStatus,
    required this.signedInAs,
  });

  final BranchAppStatus? filter;
  final ValueChanged<BranchAppStatus?> onFilterChanged;
  final Future<void> Function(BranchApp app, BranchAppStatus status) onSetStatus;
  final String signedInAs;

  @override
  Widget build(BuildContext context) {
    final service = context.read<BranchAppService>();
    final stream = filter == null
        ? service.watchAllForAdmin()
        : service.watchAppsByStatus(filter!);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'superadmin · $signedInAs',
              style: const TextStyle(
                color: AppTheme.neon,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Pending'),
                selected: filter == BranchAppStatus.pending,
                onSelected: (_) => onFilterChanged(BranchAppStatus.pending),
              ),
              FilterChip(
                label: const Text('Approved'),
                selected: filter == BranchAppStatus.approved,
                onSelected: (_) => onFilterChanged(BranchAppStatus.approved),
              ),
              FilterChip(
                label: const Text('Rejected'),
                selected: filter == BranchAppStatus.rejected,
                onSelected: (_) => onFilterChanged(BranchAppStatus.rejected),
              ),
              FilterChip(
                label: const Text('All'),
                selected: filter == null,
                onSelected: (_) => onFilterChanged(null),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<BranchApp>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('${snapshot.error}'));
              }
              final apps = snapshot.data ?? const <BranchApp>[];
              if (apps.isEmpty) {
                return const Center(
                  child: Text(
                    '표시할 항목이 없습니다.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: apps.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final app = apps[index];
                  final date =
                      DateFormat('yyyy-MM-dd HH:mm').format(app.createdAt);
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  app.name,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              _StatusBadge(status: app.status),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            app.description,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '제작자: ${app.creator} · 업로더: ${app.uploaderEmail}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'GitHub: ${app.githubBranchUrl}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.neonAlt,
                            ),
                          ),
                          Text(
                            '등록: $date',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // 승인/거절 버튼 — superadmin만 이 화면에 진입 가능
                          Row(
                            children: [
                              IconButton(
                                tooltip: '승인',
                                icon: const Icon(
                                  Icons.check,
                                  color: AppTheme.neon,
                                ),
                                onPressed:
                                    app.status == BranchAppStatus.approved
                                        ? null
                                        : () => onSetStatus(
                                              app,
                                              BranchAppStatus.approved,
                                            ),
                              ),
                              IconButton(
                                tooltip: '거절',
                                icon: const Icon(
                                  Icons.close,
                                  color: AppTheme.danger,
                                ),
                                onPressed:
                                    app.status == BranchAppStatus.rejected
                                        ? null
                                        : () => onSetStatus(
                                              app,
                                              BranchAppStatus.rejected,
                                            ),
                              ),
                              TextButton(
                                onPressed: app.status == BranchAppStatus.pending
                                    ? null
                                    : () => onSetStatus(
                                          app,
                                          BranchAppStatus.pending,
                                        ),
                                child: const Text('Pending로'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final BranchAppStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      BranchAppStatus.approved => AppTheme.neon,
      BranchAppStatus.rejected => AppTheme.danger,
      BranchAppStatus.pending => AppTheme.warning,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        status.value,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
