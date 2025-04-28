import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:resume_master/screens/home.dart';
import 'package:resume_master/services/database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<void> registerUser({
    required String email,
    required String password,
    required String name,
    required Function(String, bool) showMessage,
    required Function() onSuccess,
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      // Store user data in Firestore
      if (userCredential.user != null) {
        try {
          Map<String, dynamic> userInfoMap = {
            'name': name,
            'email': email.trim(),
            'imgUrl': '', // Default empty image URL
            'uid': userCredential.user!.uid,
            'datePublished': DateTime.now(),
          };

          await DatabaseMethods().addUser(
            userCredential.user!.uid,
            userInfoMap,
          );

          // Send email verification
          await userCredential.user!.sendEmailVerification();

          showMessage(
            'User Created Successfully. Please verify your email.',
            true,
          );
          onSuccess();
        } catch (e) {
          // Firestore operation failed - roll back by deleting the user
          await userCredential.user!.delete();
          showMessage('Failed to save user data. Please try again.', false);
          return;
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = switch (e.code) {
        'weak-password' => 'The password provided is too weak.',
        'email-already-in-use' => 'This email is already registered.',
        _ => 'Registration failed. Please try again.',
      };
      showMessage(message, false);
    } catch (e) {
      showMessage('An unexpected error occurred. Please try again.', false);
    }
  }

  Future<void> loginUser({
    required String email,
    required String password,
    required Function(String, bool) showMessage,
    required Function() onSuccess,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      showMessage('Login Successful', true);
      onSuccess();
    } on FirebaseAuthException catch (e) {
      String message = switch (e.code) {
        'user-not-found' => 'No user found with this email.',
        'wrong-password' => 'Invalid password.',
        'invalid-email' => 'Invalid email format.',
        'user-disabled' => 'This account has been disabled.',
        _ => 'Login failed. Please try again.',
      };
      showMessage(message, false);
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

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();

      if (googleSignInAccount == null) {
        // User canceled the Google Sign-In process
        return;
      }

      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? userDetails = result.user;

      if (userDetails != null) {
        Map<String, dynamic> userInfoMap = {
          'name': userDetails.displayName,
          'email': userDetails.email,
          'imgUrl': userDetails.photoURL,
          'uid': userDetails.uid,
        };

        await DatabaseMethods().addUser(userDetails.uid, userInfoMap);

        // Ensure the widget is still mounted before using the context
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Home()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Google Sign-In failed: ${e.message}',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'An unexpected error occurred. Please try again.',
              style: TextStyle(color: Colors.red),
            ),
          ),
        );
      }
    }
  }
}
