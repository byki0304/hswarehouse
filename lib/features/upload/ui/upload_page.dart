import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:hswarehouse/app/theme/app_theme.dart';
import 'package:hswarehouse/processes/data/auth_service.dart';
import 'package:hswarehouse/processes/data/firestore_service.dart';
import 'package:hswarehouse/shared/config/app_constants.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _iconUrlController = TextEditingController();
  final _githubController = TextEditingController();
  final _creatorController = TextEditingController();
  final _launchUrlController = TextEditingController();

  Uint8List? _iconBytes;
  String? _iconContentType;
  String? _iconFileName;
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _iconUrlController.dispose();
    _githubController.dispose();
    _creatorController.dispose();
    _launchUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _iconBytes = bytes;
      _iconFileName = file.name;
      _iconContentType = file.mimeType ?? 'image/png';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthService>();
    final user = auth.currentUser;
    if (user == null) {
      context.go('/login');
      return;
    }

    setState(() => _busy = true);
    try {
      final service = context.read<BranchAppService>();
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();

      final iconUrl = await service.resolveIconUrl(
        uploaderId: user.uid,
        iconUrlInput: _iconUrlController.text,
        name: name,
        description: description,
        bytes: _iconBytes,
        contentType: _iconContentType,
        fileName: _iconFileName,
      );

      await service.createPendingApp(
        name: name,
        description: description,
        iconUrl: iconUrl,
        githubBranchUrl: _githubController.text,
        creator: _creatorController.text,
        uploaderId: user.uid,
        uploaderEmail: user.email,
        launchUrl: _launchUrlController.text.trim().isEmpty
            ? null
            : _launchUrlController.text,
      );

      if (!mounted) return;
      final autoIcon = _iconBytes == null &&
          _iconUrlController.text.trim().isEmpty;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            autoIcon
                ? '업로드 완료! 아이콘은 이름·설명 기반으로 자동 생성되었습니다. (승인 대기)'
                : '업로드 완료! 관리자 승인 후 메인화면에 노출됩니다. (status=pending)',
          ),
        ),
      );
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('업로드 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining =
        AppConstants.descriptionMaxLength - _descriptionController.text.length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '브랜치앱 메타데이터 업로드',
                      style: AppTheme.display(20),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Firebase에 status=pending 으로 저장됩니다.\n'
                      '아이콘 URL을 비우면 이름·설명으로 경량 SVG 아이콘을 자동 생성합니다.',
                      style: AppTheme.body(13, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: '앱 이름 *'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? '필수 항목' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _creatorController,
                      decoration: const InputDecoration(
                        labelText: '제작자 정보 (이름/팀명) *',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? '필수 항목' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      maxLength: AppConstants.descriptionMaxLength,
                      maxLines: 4,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: '설명 * (200자 이내)',
                        helperText: '남은 글자: $remaining',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return '필수 항목';
                        if (v.trim().length >
                            AppConstants.descriptionMaxLength) {
                          return '200자 이내로 작성해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _githubController,
                      decoration: const InputDecoration(
                        labelText: 'Github branch URL *',
                        hintText:
                            'https://github.com/org/repo/tree/feature-branch',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return '필수 항목';
                        final uri = Uri.tryParse(v.trim());
                        if (uri == null || !uri.hasScheme) {
                          return '유효한 URL을 입력하세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _launchUrlController,
                      decoration: const InputDecoration(
                        labelText: '실행 URL (선택, Netlify/Hosting 등)',
                        hintText: '비우면 Github branch URL을 사용합니다',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _iconUrlController,
                      decoration: const InputDecoration(
                        labelText: '아이콘 이미지 URL (선택)',
                        helperText:
                            '비워 두면 앱 이름·설명으로 일러스트 SVG 아이콘을 자동 생성해 DB에 저장합니다.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _pickIcon,
                      icon: const Icon(Icons.image_outlined),
                      label: Text(
                        _iconBytes == null
                            ? '아이콘 이미지 선택 (선택)'
                            : '아이콘 선택됨 (${_iconBytes!.length} bytes)',
                      ),
                    ),
                    const SizedBox(height: 22),
                    ElevatedButton.icon(
                      onPressed: _busy ? null : _submit,
                      icon: const Icon(Icons.cloud_upload),
                      label: Text(_busy ? '업로드 중...' : '업로드 요청'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
