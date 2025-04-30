import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:resume_master/screens/home.dart';
import 'package:resume_master/services/auth_service.dart' as auth;
import 'package:resume_master/services/database.dart';
import 'package:resume_master/services/firebase_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? getCurrentUser() => _auth.currentUser;

  Future<void> signOut() async {
    try {
      await Future.wait([_googleSignIn.signOut(), _auth.signOut()]);
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  Future<UserCredential> registerUser({
    required String email,
    required String password,
    required String name,
    required Function(String, bool) showMessage,
    required Function() onSuccess,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update user display name
      await userCredential.user?.updateDisplayName(name);

      showMessage('User Created Successfully', true);
      onSuccess();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      String message = switch (e.code) {
        'weak-password' => 'The password provided is too weak.',
        'email-already-in-use' => 'This email is already registered.',
        _ => 'Registration failed. Please try again.',
      };

      showMessage(message, false);
      rethrow;
    }
  }

  Future<UserCredential> loginUser({
    required String email,
    required String password,
    required Function(String, bool) showMessage,
    required Function() onSuccess,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      showMessage('Login Successful', true);
      onSuccess();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      String message = switch (e.code) {
        'user-not-found' => 'No user found with this email.',
        'wrong-password' => 'Wrong password provided.',
        'invalid-credential' => 'Invalid email or password.',
        _ => 'Login failed. Please try again.',
      };

      showMessage(message, false);
      rethrow;
    }
  }

  Future<void> resetPassword({
    required String email,
    required Function(String, bool) showMessage,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      showMessage('Password reset email sent!', true);
    } on FirebaseAuthException catch (e) {
      String message = switch (e.code) {
        'user-not-found' => 'No user found with this email.',
        'invalid-email' => 'Invalid email format.',
        _ => 'Password reset failed. Please try again.',
      };
      showMessage(message, false);
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Google sign in was aborted by user');
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      if (user != null) {
        // Update user profile if needed
        if (user.displayName == null || user.displayName!.isEmpty) {
          await user.updateDisplayName(googleUser.displayName);
        }
        if (user.photoURL == null || user.photoURL!.isEmpty) {
          await user.updatePhotoURL(googleUser.photoUrl);
        }

        // Create or update user profile in Firestore
        await FirebaseService().addUserToDatabase(user);
      }

      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'Firebase Auth Error during Google sign in: ${e.code} - ${e.message}',
      );
      rethrow;
    } on Exception catch (e) {
      debugPrint('Error during Google sign in: $e');
      rethrow;
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
