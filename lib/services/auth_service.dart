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
  final FirebaseService _firebaseService = FirebaseService();

  User? getCurrentUser() => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signOut() async {
    try {
      // First sign out from Google
      await _googleSignIn.signOut();
      // Then sign out from Firebase
      await _auth.signOut();
      // Clear any cached Google sign-in state
      await _googleSignIn.disconnect();
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'Firebase Auth Error during sign out: ${e.code} - ${e.message}',
      );
      rethrow;
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
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Please enter a valid email address',
        );
      }

      if (password.length < 6) {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: 'Password should be at least 6 characters long',
        );
      }

      if (name.trim().isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-name',
          message: 'Name cannot be empty',
        );
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        await userCredential.user?.updateDisplayName(name);
        await _firebaseService.addUserToDatabase(userCredential.user!);
      }

      showMessage('User Created Successfully', true);
      onSuccess();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      String message = switch (e.code) {
        'weak-password' => 'The password provided is too weak.',
        'email-already-in-use' => 'This email is already registered.',
        'invalid-email' => 'Please enter a valid email address.',
        'invalid-name' => 'Please enter a valid name.',
        _ => 'Registration failed. Please try again.',
      };

      showMessage(message, false);
      rethrow;
    } catch (e) {
      showMessage('An unexpected error occurred. Please try again.', false);
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
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Please enter a valid email address',
        );
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        // Check if user document exists, if not create it
        final userDoc = await _firebaseService.getUserData(
          userCredential.user!.uid,
        );
        if (!userDoc.exists) {
          await _firebaseService.addUserToDatabase(userCredential.user!);
        } else {
          // Update last sign in time
          await _firebaseService.updateUserField(userCredential.user!.uid, {
            'lastSignInTime': DateTime.now(),
          });
        }
      }

      showMessage('Login Successful', true);
      onSuccess();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      String message = switch (e.code) {
        'user-not-found' => 'No user found with this email.',
        'wrong-password' => 'Wrong password provided.',
        'invalid-credential' => 'Invalid email or password.',
        'invalid-email' => 'Please enter a valid email address.',
        'user-disabled' => 'This account has been disabled.',
        _ => 'Login failed. Please try again.',
      };

      showMessage(message, false);
      rethrow;
    } catch (e) {
      showMessage('An unexpected error occurred. Please try again.', false);
      rethrow;
    }
  }

  Future<void> resetPassword({
    required String email,
    required Function(String, bool) showMessage,
  }) async {
    try {
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Please enter a valid email address',
        );
      }

      await _auth.sendPasswordResetEmail(email: email.trim());
      showMessage('Password reset email sent!', true);
    } on FirebaseAuthException catch (e) {
      String message = switch (e.code) {
        'user-not-found' => 'No user found with this email.',
        'invalid-email' => 'Please enter a valid email address.',
        'user-disabled' => 'This account has been disabled.',
        _ => 'Password reset failed. Please try again.',
      };
      showMessage(message, false);
    } catch (e) {
      showMessage('An unexpected error occurred. Please try again.', false);
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      // First sign out from any existing Google sign-in
      await _googleSignIn.signOut();

      // Configure Google Sign In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('Google sign in was aborted by user');
        return null;
      }

      debugPrint('Getting Google auth details...');

      // Get auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to get user from Google sign in');
      }

      // Update user profile if needed
      if (user.displayName == null || user.displayName!.isEmpty) {
        await user.updateDisplayName(googleUser.displayName);
      }
      if (user.photoURL == null || user.photoURL!.isEmpty) {
        await user.updatePhotoURL(googleUser.photoUrl);
      }

      // Check if user document exists, if not create it
      final userDoc = await _firebaseService.getUserData(user.uid);
      if (!userDoc.exists) {
        await _firebaseService.addUserToDatabase(user);
      } else {
        // Update last sign in time
        await _firebaseService.updateUserField(user.uid, {
          'lastSignInTime': DateTime.now(),
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'Firebase Auth Error during Google sign in: ${e.code} - ${e.message}',
      );
      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw Exception(
            'An account already exists with the same email address but different sign-in credentials.',
          );
        case 'invalid-credential':
          throw Exception('The credential is invalid or has expired.');
        case 'operation-not-allowed':
          throw Exception('Google sign-in is not enabled.');
        case 'user-disabled':
          throw Exception('This user account has been disabled.');
        case 'user-not-found':
          throw Exception('No user found with this email.');
        case 'wrong-password':
          throw Exception('Wrong password provided.');
        case 'invalid-verification-code':
          throw Exception('The verification code is invalid.');
        case 'invalid-verification-id':
          throw Exception('The verification ID is invalid.');
        default:
          throw Exception(
            'An error occurred during Google sign in: ${e.message}',
          );
      }
    } on Exception catch (e) {
      debugPrint('Error during Google sign in: $e');
      rethrow;
    }
  }
}
