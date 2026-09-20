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
  bool _signingOut = false;

  AppUser? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get loading => _loading;
  String? get error => _error;
  User? get firebaseUser => _auth.currentUser;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    final clientId = AppEnv.oauthClientId;
    await _googleSignIn.initialize(
      clientId: clientId.isEmpty ? null : clientId,
      serverClientId: (!kIsWeb && clientId.isNotEmpty) ? clientId : null,
    );
    _googleInitialized = true;
  }

  Future<void> _onAuthChanged(User? user) async {
    // Ignore transient auth events while a deliberate sign-out is in progress.
    if (_signingOut) {
      if (user != null) {
        try {
          await _auth.signOut();
        } catch (_) {}
      }
      _currentUser = null;
      _loading = false;
      notifyListeners();
      return;
    }

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
      // role ÄÂÂ´ superadmin ÄÂÂ´ÄÄÂ°ĂŤÂÂ, role Ă­ÂÂĂŤÂÂ ÄÂÂÄÂÂ´ ĂŤĹšÂ¸ÄÂÂĂŤÂ§Â ÄÂÂĂŤÂÂ ÄËËÄÂÂ°ĂŤÂÂ ÄÂ´ÂĂŤĹĹšÄÂÂĂŤÄÂ ÄÂÂ¸ÄÂ Â
      return role == null || role.isEmpty || role == 'superadmin' || role == 'admin';
    } catch (_) {
      // ÄĹÂĂ­ÂÂ/ĂŤÂÂ¤Ă­ÂÂ¸ÄÂÂĂ­ÂĹš ÄÂÂ¤ĂŤÄ˝Â ÄÂÂ ÄĹÂÄÂÂĂŤÄÂ Ă­ÂÂ ĂŤËÂ ĂŤÂÂ ÄÂÂĂŤÂÂ
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
        await _auth.signInWithPopup(provider);
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
        'This domain is not in Firebase Authorized domains. '
            'Confirm hswarehouse.netlify.app is registered.',
      'popup-blocked' =>
        'Popup was blocked. Allow popups and try again.',
      'popup-closed-by-user' => 'Google sign-in was closed. Please try again.',
      'network-request-failed' => 'Network error. Check your connection.',
      'operation-not-allowed' =>
        'Enable the Google sign-in provider in Firebase Console.',
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
    _signingOut = true;
    _currentUser = null;
    _error = null;
    _loading = false;
    notifyListeners();

    try {
      try {
        await _ensureGoogleInitialized();
        await _googleSignIn.signOut();
        if (!kIsWeb) {
          try {
            await _googleSignIn.disconnect();
          } catch (_) {}
        }
      } catch (_) {}

      await _auth.signOut();

      // Ensure Firebase session is actually cleared (web can race).
      for (var i = 0; i < 3 && _auth.currentUser != null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await _auth.signOut();
      }
    } finally {
      _currentUser = null;
      _loading = false;
      _signingOut = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
