import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hswarehouse/app/theme/app_theme.dart';
import 'package:hswarehouse/processes/data/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _smsController = TextEditingController();

  bool _busy = false;
  bool _isRegister = false;
  String? _verificationId;
  String? _message;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _smsController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
      if (mounted) context.go('/');
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final size = MediaQuery.sizeOf(context);
    final maxWidth = size.width > 560 ? 440.0 : size.width;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Card(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    children: [
                      const Text(
                        '팀원 인증',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '회원만 브랜치앱을 업로드할 수 있습니다.\n'
                        '비회원도 승인된 앱은 실행할 수 있습니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TabBar(
                        controller: _tabController,
                        labelColor: AppTheme.neon,
                        unselectedLabelColor: AppTheme.textSecondary,
                        indicatorColor: AppTheme.neon,
                        tabs: const [
                          Tab(text: 'Google'),
                          Tab(text: 'Email'),
                          Tab(text: 'Phone'),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _GoogleTab(
                        busy: _busy,
                        onSignIn: () => _run(auth.signInWithGoogle),
                      ),
                      _EmailTab(
                        busy: _busy,
                        isRegister: _isRegister,
                        emailController: _emailController,
                        passwordController: _passwordController,
                        nameController: _nameController,
                        onToggleMode: () {
                          setState(() => _isRegister = !_isRegister);
                        },
                        onSubmit: () {
                          final email = _emailController.text.trim();
                          final password = _passwordController.text;
                          if (_isRegister) {
                            _run(
                              () => auth.registerWithEmail(
                                email: email,
                                password: password,
                                displayName: _nameController.text,
                              ),
                            );
                            return;
                          }
                          _run(
                            () => auth.signInWithEmail(
                              email: email,
                              password: password,
                            ),
                          );
                        },
                      ),
                      _PhoneTab(
                        busy: _busy,
                        phoneController: _phoneController,
                        smsController: _smsController,
                        verificationId: _verificationId,
                        onSendCode: () async {
                          setState(() {
                            _busy = true;
                            _message = null;
                          });
                          try {
                            await auth.sendPhoneCode(
                              phoneNumber: _phoneController.text.trim(),
                              onCodeSent: (id) {
                                setState(() {
                                  _verificationId = id;
                                  _message = '인증번호를 전송했습니다.';
                                });
                              },
                              onFailed: (error) {
                                setState(() => _message = error.message);
                              },
                            );
                          } catch (e) {
                            setState(() => _message = e.toString());
                          } finally {
                            if (mounted) {
                              setState(() => _busy = false);
                            }
                          }
                        },
                        onVerify: () {
                          final id = _verificationId;
                          if (id == null) return;
                          _run(
                            () => auth.verifyPhoneSmsCode(
                              verificationId: id,
                              smsCode: _smsController.text.trim(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                if (_message != null || _busy)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Column(
                      children: [
                        if (_message != null)
                          Text(
                            _message!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _message!.contains('전송')
                                  ? AppTheme.neon
                                  : AppTheme.danger,
                              fontSize: 12,
                            ),
                          ),
                        if (_busy) ...[
                          const SizedBox(height: 10),
                          const LinearProgressIndicator(),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleTab extends StatelessWidget {
  const _GoogleTab({required this.busy, required this.onSignIn});

  final bool busy;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          const Icon(Icons.g_mobiledata, size: 56, color: AppTheme.neonAlt),
          const SizedBox(height: 10),
          const Text(
            'Google 계정으로 빠르게 로그인하세요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: busy ? null : onSignIn,
              icon: const Icon(Icons.login),
              label: const Text('Continue with Google'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailTab extends StatelessWidget {
  const _EmailTab({
    required this.busy,
    required this.isRegister,
    required this.emailController,
    required this.passwordController,
    required this.nameController,
    required this.onToggleMode,
    required this.onSubmit,
  });

  final bool busy;
  final bool isRegister;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController nameController;
  final VoidCallback onToggleMode;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        if (isRegister) ...[
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: '이름 / 팀명'),
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: busy ? null : onSubmit,
            child: Text(isRegister ? '회원가입' : '이메일 로그인'),
          ),
        ),
        TextButton(
          onPressed: busy ? null : onToggleMode,
          child: Text(
            isRegister ? '이미 계정이 있나요? 로그인' : '계정이 없나요? 회원가입',
          ),
        ),
      ],
    );
  }
}

class _PhoneTab extends StatelessWidget {
  const _PhoneTab({
    required this.busy,
    required this.phoneController,
    required this.smsController,
    required this.verificationId,
    required this.onSendCode,
    required this.onVerify,
  });

  final bool busy;
  final TextEditingController phoneController;
  final TextEditingController smsController;
  final String? verificationId;
  final VoidCallback onSendCode;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: '휴대폰 번호',
            hintText: '+821012345678',
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: busy ? null : onSendCode,
            child: const Text('인증번호 전송'),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: smsController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'SMS 인증번호'),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: busy || verificationId == null ? null : onVerify,
            child: const Text('휴대폰 인증 완료'),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '번호 형식 예: +821012345678',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
