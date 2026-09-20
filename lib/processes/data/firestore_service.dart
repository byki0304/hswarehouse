import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import 'package:hswarehouse/entities/branch_app/branch_app.dart';
import 'package:hswarehouse/processes/data/branch_icon_generator.dart';
import 'package:hswarehouse/shared/config/app_constants.dart';

/// Firebase Firestore / Storage data layer (FSD processes/data).
class FirestoreService {
  FirestoreService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _branchApps =>
      _db.collection(AppConstants.branchAppsCollection);

  /// Template-compatible upload helper.
  Future<void> uploadBranchApp(Map<String, dynamic> data) async {
    await _branchApps.add({
      ...data,
      'status': data['status'] ?? AppConstants.statusPending,
      'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
    });
  }

  /// Template-compatible approved stream (raw snapshots).
  Stream<QuerySnapshot<Map<String, dynamic>>> getApprovedApps() {
    return _branchApps
        .where('status', isEqualTo: AppConstants.statusApproved)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<List<BranchApp>> watchApprovedApps() {
    return getApprovedApps()
        .map((snap) => snap.docs.map(BranchApp.fromDoc).toList());
  }

  Stream<List<BranchApp>> watchAppsByStatus(BranchAppStatus status) {
    return _branchApps
        .where('status', isEqualTo: status.value)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(BranchApp.fromDoc).toList());
  }

  Stream<List<BranchApp>> watchAllForAdmin() {
    return _branchApps
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(BranchApp.fromDoc).toList());
  }

  Future<bool> isAdmin(String uid) async {
    final doc =
        await _db.collection(AppConstants.adminsCollection).doc(uid).get();
    if (!doc.exists) return false;
    final role = (doc.data()?['role'] as String?)?.trim().toLowerCase();
    return role == null ||
        role.isEmpty ||
        role == 'superadmin' ||
        role == 'admin';
  }

  Future<void> updateAppStatus(String appId, String status) async {
    await _branchApps.doc(appId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateStatus({
    required String appId,
    required BranchAppStatus status,
  }) =>
      updateAppStatus(appId, status.value);

  Future<String> resolveIconUrl({
    required String uploaderId,
    required String iconUrlInput,
    required String name,
    required String description,
    Uint8List? bytes,
    String? contentType,
    String? fileName,
  }) async {
    final trimmed = iconUrlInput.trim();

    // Prefer explicit file upload when provided.
    if (bytes != null && bytes.isNotEmpty) {
      try {
        return await uploadIcon(
          uploaderId: uploaderId,
          bytes: bytes,
          contentType: contentType ?? 'image/png',
          fileName: fileName,
        ).timeout(const Duration(seconds: 12));
      } catch (_) {
        if (bytes.lengthInBytes > 350 * 1024) {
          throw StateError(
            '아이콘 업로드가 타임아웃되었습니다. '
            'Firebase Storage를 활성화하거나, 아이콘 URL을 비워 자동 생성하세요.',
          );
        }
        final mime = contentType ?? 'image/png';
        return 'data:$mime;base64,${base64Encode(bytes)}';
      }
    }

    // Optional URL — if blank, auto-generate a tiny SVG icon for Firestore.
    if (trimmed.isNotEmpty) return trimmed;

    return BranchIconGenerator.toDataUrl(
      name: name,
      description: description,
    );
  }

  Future<String> uploadIcon({
    required String uploaderId,
    required Uint8List bytes,
    required String contentType,
    String? fileName,
  }) async {
    final safeName = fileName ?? '${_uuid.v4()}.png';
    final ref = _storage.ref().child('branch_icons/$uploaderId/$safeName');
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }

  Future<String> createPendingApp({
    required String name,
    required String description,
    required String iconUrl,
    required String githubBranchUrl,
    required String creator,
    required String uploaderId,
    required String uploaderEmail,
    String? launchUrl,
  }) async {
    final trimmedDescription = description.trim();
    if (trimmedDescription.length > AppConstants.descriptionMaxLength) {
      throw ArgumentError(
        'Description must be ${AppConstants.descriptionMaxLength} characters or fewer.',
      );
    }

    final doc = _branchApps.doc();
    final app = BranchApp(
      id: doc.id,
      name: name.trim(),
      description: trimmedDescription,
      iconUrl: iconUrl.trim(),
      githubBranchUrl: githubBranchUrl.trim(),
      creator: creator.trim(),
      uploaderId: uploaderId,
      uploaderEmail: uploaderEmail,
      status: BranchAppStatus.pending,
      createdAt: DateTime.now(),
      launchUrl: launchUrl?.trim(),
    );

    await doc.set(app.toCreateMap()).timeout(const Duration(seconds: 15));
    return doc.id;
  }
}

/// Backward-compatible alias used by existing UI during FSD migration.
typedef BranchAppService = FirestoreService;
