import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:resume_master/screens/user/home.dart';
import 'package:resume_master/services/auth_service.dart' as auth;
import 'package:resume_master/services/database.dart';
import 'package:resume_master/services/firebase_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Custom exception class for auth errors
class AuthException implements Exception {
  final String message;
  final String code;
  final dynamic originalError;

  AuthException(this.message, {this.code = 'unknown', this.originalError});

  @override
  String toString() => message;
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> getUserRole() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final userData =
            await _firestore.collection('users').doc(user.uid).get();
        if (!userData.exists) {
          throw AuthException('User data not found', code: 'user-not-found');
        }
        return userData.data()?['role'];
      } on FirebaseException catch (e) {
        throw AuthException(
          'Error getting user role: ${e.message}',
          code: e.code,
          originalError: e,
        );
      } catch (e) {
        throw AuthException('Unexpected error getting user role: $e');
      }
    }
    return null;
  }

  Future<void> signOut() async {
    try {
      await Future.wait([_googleSignIn.signOut(), _auth.signOut()]);
    } on FirebaseException catch (e) {
      throw AuthException(
        'Error signing out: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw AuthException('Unexpected error signing out: $e');
    }
  }

  Future<void> signUpUser({
    required String email,
    required String password,
    required String name,
    String? company,
    required String role,
    required String phone,
    String? position,
    required Function(String, bool) showMessage,
    required VoidCallback onSuccess,
  }) async {
    try {
      // Input validation
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw AuthException(
          'Please enter a valid email address',
          code: 'invalid-email',
        );
      }

      if (password.length < 6) {
        throw AuthException(
          'Password must be at least 6 characters long',
          code: 'weak-password',
        );
      }

      if (name.trim().length < 2) {
        throw AuthException(
          'Name must be at least 2 characters long',
          code: 'invalid-name',
        );
      }

      if (phone.trim().isEmpty) {
        throw AuthException('Phone number is required', code: 'missing-phone');
      }
      if (!RegExp(r'^\+?[\d\s-]{10,}$').hasMatch(phone)) {
        throw AuthException(
          'Please enter a valid phone number',
          code: 'invalid-phone',
        );
      }

      if (role == 'recruiter') {
        if (company == null || company.trim().isEmpty) {
          throw AuthException(
            'Company name is required for recruiters',
            code: 'missing-company',
          );
        }
        if (position == null || position.trim().isEmpty) {
          throw AuthException(
            'Position is required for recruiters',
            code: 'missing-position',
          );
        }
      }

      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw AuthException(
          'Failed to create user account',
          code: 'user-creation-failed',
        );
      }

      // Update user profile
      await userCredential.user?.updateDisplayName(name);

      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'role': role,
        'company': company,
        'phone': phone,
        'position': position,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      showMessage('Account created successfully!', true);
      onSuccess();
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      String code = e.code;

      switch (e.code) {
        case 'weak-password':
          message =
              'The password provided is too weak. Please use a stronger password.';
          break;
        case 'email-already-in-use':
          message =
              'An account already exists for that email. Please use a different email or try logging in.';
          break;
        case 'invalid-email':
          message =
              'The email address is not valid. Please check and try again.';
          break;
        case 'operation-not-allowed':
          message =
              'Email/password accounts are not enabled. Please contact support.';
          break;
        default:
          message = 'An error occurred during sign up: ${e.message}';
      }

      showMessage(message, false);
      throw AuthException(message, code: code, originalError: e);
    } on FirebaseException catch (e) {
      final message = 'Database error: ${e.message}';
      showMessage(message, false);
      throw AuthException(message, code: e.code, originalError: e);
    } on AuthException {
      rethrow;
    } catch (e) {
      final message = 'Unexpected error: $e';
      showMessage(message, false);
      throw AuthException(message);
    }
  }

  Future<void> loginUser({
    required String email,
    required String password,
    required Function(String, bool) showMessage,
    required VoidCallback onSuccess,
  }) async {
    try {
      if (email.trim().isEmpty || password.trim().isEmpty) {
        throw AuthException(
          'Email and password are required',
          code: 'missing-credentials',
        );
      }

      // First try to sign in
      try {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (userCredential.user == null) {
          throw AuthException('Login failed', code: 'login-failed');
        }

        final userData =
            await _firestore
                .collection('users')
                .doc(userCredential.user!.uid)
                .get();

        if (!userData.exists) {
          await _auth.signOut();
          throw AuthException('User data not found', code: 'user-not-found');
        }

        final role = userData.data()?['role'];
        if (role == null) {
          await _auth.signOut();
          throw AuthException('Invalid account type', code: 'invalid-role');
        }

        showMessage('Logged in successfully!', true);
        onSuccess();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'too-many-requests') {
          // Handle rate limiting
          throw AuthException(
            'Too many login attempts. Please try again later.',
            code: e.code,
            originalError: e,
          );
        } else if (e.code == 'network-request-failed') {
          // Handle network issues
          throw AuthException(
            'Network error. Please check your internet connection.',
            code: e.code,
            originalError: e,
          );
        } else {
          // Handle other auth errors
          String message = 'An error occurred';
          switch (e.code) {
            case 'user-not-found':
              message =
                  'No user found for that email. Please check your email or sign up.';
              break;
            case 'wrong-password':
              message = 'Wrong password. Please try again.';
              break;
            case 'invalid-email':
              message = 'The email address is not valid.';
              break;
            case 'user-disabled':
              message =
                  'This account has been disabled. Please contact support.';
              break;
            default:
              message = 'An error occurred during login: ${e.message}';
          }
          throw AuthException(message, code: e.code, originalError: e);
        }
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Unexpected error during login: $e');
    }
  }

  Future<void> resetPassword({
    required String email,
    required Function(String, bool) showMessage,
  }) async {
    try {
      if (email.trim().isEmpty) {
        throw AuthException('Email is required', code: 'missing-email');
      }

      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw AuthException(
          'Please enter a valid email address',
          code: 'invalid-email',
        );
      }

      await _auth.sendPasswordResetEmail(email: email.trim());
      showMessage('Password reset email sent! Check your inbox.', true);
    } on FirebaseAuthException catch (e) {
      String message = switch (e.code) {
        'user-not-found' =>
          'No user found with this email. Please check your email or sign up.',
        'invalid-email' => 'Please enter a valid email address.',
        'user-disabled' =>
          'This account has been disabled. Please contact support.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        _ => 'Password reset failed: ${e.message}',
      };
      showMessage(message, false);
      throw AuthException(message, code: e.code, originalError: e);
    } on AuthException {
      rethrow;
    } catch (e) {
      final message = 'Unexpected error: $e';
      showMessage(message, false);
      throw AuthException(message);
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthException('Google sign in was cancelled', code: 'cancelled');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user == null) {
        throw AuthException(
          'Failed to sign in with Google',
          code: 'sign-in-failed',
        );
      }

      final userDoc =
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();

      if (!userDoc.exists) {
        // Create new user document with job seeker role
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': userCredential.user!.displayName ?? 'User',
          'email': userCredential.user!.email,
          'role': 'job_seeker',
          'phone': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'photoURL': userCredential.user!.photoURL,
        });
      } else {
        // Check if existing user is a job seeker
        final role = userDoc.data()?['role'];
        if (role != 'job_seeker') {
          await _auth.signOut();
          throw AuthException(
            'Please use the recruiter login',
            code: 'invalid-role',
          );
        }
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        'Google sign in failed: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } on FirebaseException catch (e) {
      throw AuthException(
        'Database error: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Unexpected error during Google sign in: $e');
    }
  }

  Future<String?> _showRoleSelectionDialog() async {
    final context = navigatorKey.currentContext;
    if (context == null) return null;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        String? selectedRole;
        return AlertDialog(
          title: const Text('Select Account Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Job Seeker'),
                value: 'user',
                groupValue: selectedRole,
                onChanged: (value) {
                  selectedRole = value;
                  Navigator.of(context).pop(value);
                },
              ),
              RadioListTile<String>(
                title: const Text('Recruiter'),
                value: 'recruiter',
                groupValue: selectedRole,
                onChanged: (value) {
                  selectedRole = value;
                  Navigator.of(context).pop(value);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, String>?> _showCompanyInfoDialog() async {
    final context = navigatorKey.currentContext;
    if (context == null) return null;

    final companyController = TextEditingController();
    final positionController = TextEditingController();

    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Company Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: companyController,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  hintText: 'Enter your company name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: positionController,
                decoration: const InputDecoration(
                  labelText: 'Position',
                  hintText: 'Enter your position',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (companyController.text.isNotEmpty &&
                    positionController.text.isNotEmpty) {
                  Navigator.of(context).pop({
                    'company': companyController.text,
                    'position': positionController.text,
                  });
                }
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> checkAuthAndRole(
    BuildContext context,
    String requiredRole,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        Navigator.pushReplacementNamed(context, '/startup');
        return false;
      }

      final userData = await _firestore.collection('users').doc(user.uid).get();
      final role = userData.data()?['role'];

      if (role != requiredRole) {
        await signOut();
        Navigator.pushReplacementNamed(context, '/startup');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error checking auth and role: $e');
      await signOut();
      Navigator.pushReplacementNamed(context, '/startup');
      return false;
    }
  }
}
