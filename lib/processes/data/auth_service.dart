import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:hswarehouse/shared/config/app_env.dart';
import 'package:hswarehouse/shared/config/app_constants.dart';
import 'package:hswarehouse/entities/user/app_user.dart';

class AuthService extends ChangeNotifier {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance {
    _subscription = _auth.authStateChanges().listen(_onAuthChanged);
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  StreamSubscription<User?>? _subscription;
  AppUser? _currentUser;
  bool _loading = true;
  String? _error;
  bool _googleInitialized = false;

  AppUser? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get loading => _loading;
  String? get error => _error;
  User? get firebaseUser => _auth.currentUser;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized || kIsWeb) return;
    final serverClientId = AppEnv.oauthClientId;
    await _googleSignIn.initialize(
      serverClientId: serverClientId.isEmpty ? null : serverClientId,
    );
    _googleInitialized = true;
  }

  Future<void> _onAuthChanged(User? user) async {
    _loading = true;
    notifyListeners();

    if (user == null) {
      _currentUser = null;
      _loading = false;
      notifyListeners();
      return;
    }

    final isAdmin = await _checkAdmin(user.uid);
    _currentUser = AppUser(
      uid: user.uid,
      email: user.email ?? user.phoneNumber ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isAdmin: isAdmin,
    );
    await _upsertUserProfile(_currentUser!);
    _loading = false;
    notifyListeners();
  }

  Future<bool> _checkAdmin(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.adminsCollection)
          .doc(uid)
          .get(const GetOptions(source: Source.server));
      if (!doc.exists) return false;
      final data = doc.data();
      if (data == null) return false;
      final role = (data['role'] as String?)?.trim().toLowerCase();
      // role 이 superadmin 이거나, role 필드 없이 문서만 있는 경우도 관리자로 인정
      return role == null || role.isEmpty || role == 'superadmin' || role == 'admin';
    } catch (_) {
      // 권한/네트워크 오류 시 캐시로 한 번 더 시도
      try {
        final cached = await _firestore
            .collection(AppConstants.adminsCollection)
            .doc(uid)
            .get(const GetOptions(source: Source.cache));
        if (!cached.exists) return false;
        final role =
            (cached.data()?['role'] as String?)?.trim().toLowerCase();
        return role == null ||
            role.isEmpty ||
            role == 'superadmin' ||
            role == 'admin';
      } catch (_) {
        return false;
      }
    }
  }

  /// Re-read admins/{uid} after Firestore role updates (e.g. superadmin).
  Future<void> refreshAdminStatus() async {
    final user = _auth.currentUser;
    if (user == null || _currentUser == null) return;
    final isAdmin = await _checkAdmin(user.uid);
    _currentUser = _currentUser!.copyWith(isAdmin: isAdmin);
    notifyListeners();
  }

  Future<void> _upsertUserProfile(AppUser user) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(user.toFirestoreMap(), SetOptions(merge: true));
  }

  Future<void> signInWithGoogle() async {
    _error = null;
    try {
      if (kIsWeb) {
        await _auth.signInWithPopup(GoogleAuthProvider());
        return;
      }

      await _ensureGoogleInitialized();
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw FirebaseAuthException(
          code: 'missing-id-token',
          message: 'Google ID token is missing.',
        );
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await _auth.signInWithCredential(credential);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _error = null;
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _error = null;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (displayName != null && displayName.trim().isNotEmpty) {
        await credential.user?.updateDisplayName(displayName.trim());
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> sendPhoneCode({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(FirebaseAuthException error) onFailed,
    void Function(PhoneAuthCredential credential)? onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (credential) async {
        if (onAutoVerified != null) {
          onAutoVerified(credential);
        } else {
          await _auth.signInWithCredential(credential);
        }
      },
      verificationFailed: onFailed,
      codeSent: (verificationId, _) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
      timeout: const Duration(seconds: 60),
    );
  }

  Future<void> verifyPhoneSmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    // UI를 즉시 비회원 상태로 전환
    _currentUser = null;
    _error = null;
    _loading = false;
    notifyListeners();

    try {
      if (!kIsWeb) {
        await _ensureGoogleInitialized();
        await _googleSignIn.signOut();
        try {
          await _googleSignIn.disconnect();
        } catch (_) {}
      }
    } catch (_) {}

    try {
      await _auth.signOut();
    } catch (_) {}

    // authStateChanges 가 다시 유저를 올려도 최종적으로 비우기
    if (_auth.currentUser != null) {
      try {
        await _auth.signOut();
      } catch (_) {}
    }
    _currentUser = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
