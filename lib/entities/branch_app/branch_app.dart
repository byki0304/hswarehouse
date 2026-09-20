import 'package:cloud_firestore/cloud_firestore.dart';

enum BranchAppStatus { pending, approved, rejected }

extension BranchAppStatusX on BranchAppStatus {
  String get value => name;

  static BranchAppStatus fromString(String? raw) {
    switch (raw) {
      case 'approved':
        return BranchAppStatus.approved;
      case 'rejected':
        return BranchAppStatus.rejected;
      case 'pending':
      default:
        return BranchAppStatus.pending;
    }
  }
}

class BranchApp {
  const BranchApp({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.githubBranchUrl,
    required this.creator,
    required this.uploaderId,
    required this.uploaderEmail,
    required this.status,
    required this.createdAt,
    this.launchUrl,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final String githubBranchUrl;
  final String creator;
  final String uploaderId;
  final String uploaderEmail;
  final BranchAppStatus status;
  final DateTime createdAt;
  final String? launchUrl;
  final DateTime? updatedAt;

  /// Prefer hosted launch URL; GitHub raw pages are usually not iframe-friendly.
  String get effectiveLaunchUrl {
    final candidate = (launchUrl ?? '').trim();
    if (candidate.isNotEmpty) return candidate;
    return githubBranchUrl;
  }

  bool get canEmbedInIFrame {
    final url = effectiveLaunchUrl.toLowerCase();
    if (url.isEmpty) return false;
    if (url.contains('github.com') || url.contains('raw.githubusercontent.com')) {
      return false;
    }
    return true;
  }

  factory BranchApp.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return BranchApp.fromMap(doc.id, data);
  }

  factory BranchApp.fromMap(String id, Map<String, dynamic> data) {
    DateTime readTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    return BranchApp(
      id: id,
      name: (data['name'] as String?)?.trim() ?? 'Untitled',
      description: (data['description'] as String?)?.trim() ?? '',
      iconUrl: (data['iconUrl'] as String?)?.trim() ?? '',
      githubBranchUrl: (data['githubBranchUrl'] as String?)?.trim() ?? '',
      creator: (data['creator'] as String?)?.trim() ?? 'Unknown',
      uploaderId: (data['uploaderId'] as String?) ?? '',
      uploaderEmail: (data['uploaderEmail'] as String?) ?? '',
      status: BranchAppStatusX.fromString(data['status'] as String?),
      createdAt: readTime(data['createdAt']),
      launchUrl: (data['launchUrl'] as String?)?.trim(),
      updatedAt: data['updatedAt'] == null ? null : readTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'githubBranchUrl': githubBranchUrl,
      'creator': creator,
      'uploaderId': uploaderId,
      'uploaderEmail': uploaderEmail,
      'status': status.value,
      'createdAt': FieldValue.serverTimestamp(),
      if (launchUrl != null && launchUrl!.isNotEmpty) 'launchUrl': launchUrl,
    };
  }
}
