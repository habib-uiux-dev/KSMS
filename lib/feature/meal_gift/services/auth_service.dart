import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firebase/app_firestore.dart';
import '../../../core/utils/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore get _firestore => appFirestore;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleReady = false;

  Future<void> initGoogleSignIn() async {
    if (_googleReady) return;
    try {
      await _googleSignIn.initialize(
        serverClientId: Constants.googleServerClientId,
      );
      _googleReady = true;
    } catch (e) {
      log('Google Sign-In initialize failed: $e');
    }
  }

  /// Sign in with Google (Mandatory) and automatically sync profile to Firestore
  Future<UserCredential?> signInWithGoogle() async {
    try {
      await initGoogleSignIn();

      if (!_googleSignIn.supportsAuthenticate()) {
        throw Exception('Google sign-in is not supported on this device');
      }

      final account = await _googleSignIn.authenticate(
        scopeHint: const ['email'],
      );

      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw Exception('Could not get a Google token');
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        await _saveUserToFirestore(user);
      }

      return userCredential;
    } catch (e) {
      debugPrint('Google Sign In Error: $e');
      rethrow;
    }
  }

  Future<void> _saveUserToFirestore(User user) async {
    try {
      final name = user.displayName?.isNotEmpty == true ? user.displayName! : 'Google User';
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': user.email,
        'photo_url': user.photoURL,
        'last_login_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving user profile to Firestore: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
