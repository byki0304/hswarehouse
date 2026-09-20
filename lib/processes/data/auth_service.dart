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
      // role ě´ superadmin ě´ęą°ë, role íë ěě´ ëŹ¸ěë§ ěë ę˛˝ě°ë ę´ëŚŹěëĄ ě¸ě 
      return role == null || role.isEmpty || role == 'superadmin' || role == 'admin';
    } catch (_) {
      // ęśí/ë¤í¸ěíŹ ě¤ëĽ ě ěşěëĄ í ë˛ ë ěë
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
    notifyListeners();
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..setCustomParameters({'prompt': 'select_account'});
        try {
          await _auth.signInWithPopup(provider);
        } on FirebaseAuthException catch (e) {
          // Popup blocked / closed → redirect flow (more reliable on some browsers)
          if (e.code == 'popup-blocked' ||
              e.code == 'popup-closed-by-user' ||
              e.code == 'cancelled-popup-request') {
            await _auth.signInWithRedirect(provider);
            return;
          }
          _error = _friendlyAuthError(e);
          notifyListeners();
          throw Exception(_error);
        }
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
    } on FirebaseAuthException catch (e) {
      _error = _friendlyAuthError(e);
      notifyListeners();
      throw Exception(_error);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    return switch (e.code) {
      'unauthorized-domain' =>
        '이 도메인이 Firebase Authorized domains에 없습니다. '
            'hswarehouse.netlify.app 등록을 확인하세요.',
      'popup-blocked' =>
        '팝업이 차단되었습니다. 브라우저에서 팝업을 허용하거나 다시 시도하세요.',
      'popup-closed-by-user' => 'Google 로그인 창이 닫혔습니다. 다시 시도하세요.',
      'network-request-failed' => '네트워크 오류입니다. 연결을 확인하세요.',
      'operation-not-allowed' =>
        'Firebase Console에서 Google 로그인 제공자가 활성화되어 있는지 확인하세요.',
      _ => e.message?.isNotEmpty == true
          ? '${e.code}: ${e.message}'
          : e.code,
    };
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
    // UIëĽź ěŚě ëšíě ěíëĄ ě í
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

    // authStateChanges ę° ë¤ě ě ě ëĽź ěŹë ¤ë ěľě˘ě ěźëĄ ëšě°ę¸°
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
