class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.isAdmin = false,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool isAdmin;

  AppUser copyWith({bool? isAdmin}) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }
}
