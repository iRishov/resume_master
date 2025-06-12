import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:resume_master/screens/job_seeker/home.dart';
import 'package:resume_master/services/auth_service.dart' as auth;
import 'package:resume_master/services/database.dart';
import 'package:resume_master/services/firebase_service.dart';
import 'package:vibration/vibration.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Custom exception class for auth errors
class AuthException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AuthException(this.message, {this.code, this.originalError});

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
      // Enhanced input validation
      if (email.trim().isEmpty) {
        throw AuthException('Email is required', code: 'missing-email');
      }

      if (password.trim().isEmpty) {
        throw AuthException('Password is required', code: 'missing-password');
      }

      if (name.trim().isEmpty) {
        throw AuthException('Name is required', code: 'missing-name');
      }

      if (phone.trim().isEmpty) {
        throw AuthException('Phone number is required', code: 'missing-phone');
      }

      // Email format validation
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw AuthException(
          'Please enter a valid email address',
          code: 'invalid-email-format',
        );
      }

      // Password strength validation
      if (password.length < 6) {
        throw AuthException(
          'Password must be at least 6 characters long',
          code: 'password-too-short',
        );
      }

      if (!RegExp(r'[A-Z]').hasMatch(password)) {
        throw AuthException(
          'Password must contain at least one uppercase letter',
          code: 'password-no-uppercase',
        );
      }

      if (!RegExp(r'[a-z]').hasMatch(password)) {
        throw AuthException(
          'Password must contain at least one lowercase letter',
          code: 'password-no-lowercase',
        );
      }

      if (!RegExp(r'[0-9]').hasMatch(password)) {
        throw AuthException(
          'Password must contain at least one number',
          code: 'password-no-number',
        );
      }

      // Name validation
      if (name.trim().length < 2) {
        throw AuthException(
          'Name must be at least 2 characters long',
          code: 'invalid-name',
        );
      }

      if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
        throw AuthException(
          'Name can only contain letters and spaces',
          code: 'invalid-name-format',
        );
      }

      // Phone number validation
      if (!RegExp(r'^\+?[\d\s-]{10,}$').hasMatch(phone)) {
        throw AuthException(
          'Please enter a valid phone number (minimum 10 digits)',
          code: 'invalid-phone',
        );
      }

      // Role-specific validation
      if (role == 'recruiter') {
        if (company == null || company.trim().isEmpty) {
          throw AuthException(
            'Company name is required for recruiters',
            code: 'missing-company',
          );
        }

        if (company.trim().length < 2) {
          throw AuthException(
            'Company name must be at least 2 characters long',
            code: 'invalid-company',
          );
        }

        if (position == null || position.trim().isEmpty) {
          throw AuthException(
            'Position is required for recruiters',
            code: 'missing-position',
          );
        }

        if (position.trim().length < 2) {
          throw AuthException(
            'Position must be at least 2 characters long',
            code: 'invalid-position',
          );
        }
      }

      // Check if email already exists
      try {
        final methods = await _auth.fetchSignInMethodsForEmail(email);
        if (methods.isNotEmpty) {
          throw AuthException(
            'An account already exists with this email. Please use the login page instead.',
            code: 'email-already-in-use',
          );
        }
      } catch (e) {
        if (e is AuthException) rethrow;
        // Ignore other errors and proceed with signup
      }

      showMessage('Creating your account...', true);

      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw AuthException(
          'Failed to create account. Please try again.',
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

      // Provide haptic feedback for successful signup
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 50);
      }

      showMessage('Account created successfully! Welcome aboard!', true);
      onSuccess();
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      String code = e.code;

      switch (e.code) {
        case 'weak-password':
          message =
              'The password is too weak. Please use a stronger password with uppercase, lowercase, and numbers.';
          break;
        case 'email-already-in-use':
          message =
              'An account already exists with this email. Please use the login page instead.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'operation-not-allowed':
          message =
              'Email/password accounts are not enabled. Please contact support.';
          break;
        case 'network-request-failed':
          message =
              'Network error. Please check your internet connection and try again.';
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
      final message = 'An unexpected error occurred. Please try again.';
      showMessage(message, false);
      throw AuthException(message);
    }
  }

  Future<void> loginUser({
    required String email,
    required String password,
    required Function(String, bool) showMessage,
    required VoidCallback onSuccess,
    String? expectedRole,
  }) async {
    try {
      // Enhanced input validation
      if (email.trim().isEmpty) {
        throw AuthException('Email is required', code: 'missing-email');
      }

      if (password.trim().isEmpty) {
        throw AuthException('Password is required', code: 'missing-password');
      }

      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw AuthException(
          'Please enter a valid email address',
          code: 'invalid-email-format',
        );
      }

      if (password.length < 6) {
        throw AuthException(
          'Password must be at least 6 characters long',
          code: 'password-too-short',
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
          throw AuthException(
            'Account not found. Please sign up first.',
            code: 'user-not-found',
          );
        }

        final role = userData.data()?['role'];
        if (role == null) {
          await _auth.signOut();
          throw AuthException(
            'Invalid account type. Please contact support.',
            code: 'invalid-role',
          );
        }

        // Check if user is trying to login with correct role
        if (expectedRole != null && role != expectedRole) {
          await _auth.signOut();
          throw AuthException(
            role == 'recruiter'
                ? 'This is a recruiter account. Please use the recruiter login page.'
                : 'This is a job seeker account. Please use the job seeker login page.',
            code: 'wrong-role',
          );
        }

        // Provide haptic feedback for successful login
        if (await Vibration.hasVibrator()) {
          Vibration.vibrate(duration: 50);
        }

        showMessage('Welcome back! Logging you in...', true);
        onSuccess();
      } on FirebaseAuthException catch (e) {
        String message;
        switch (e.code) {
          case 'user-not-found':
            message =
                'No account found with this email. Please check your email or sign up.';
            break;
          case 'wrong-password':
            message =
                'Incorrect password. Please try again or use "Forgot Password" if you need help.';
            break;
          case 'invalid-email':
            message = 'Please enter a valid email address.';
            break;
          case 'user-disabled':
            message =
                'This account has been disabled. Please contact support for assistance.';
            break;
          case 'too-many-requests':
            message =
                'Too many login attempts. Please try again in a few minutes or reset your password.';
            break;
          case 'network-request-failed':
            message =
                'Network error. Please check your internet connection and try again.';
            break;
          default:
            message = 'Login failed: ${e.message}';
        }
        showMessage(message, false);
        throw AuthException(message, code: e.code, originalError: e);
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      final message = 'An unexpected error occurred. Please try again.';
      showMessage(message, false);
      throw AuthException(message);
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

  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        throw AuthException('Google sign in was cancelled');
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
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw AuthException('Failed to sign in with Google');
      }

      // Check if user exists in Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // Show dialog to collect additional required information
        final context = navigatorKey.currentContext;
        if (context == null) {
          throw AuthException('Context not available');
        }

        // Create controllers for the form
        final nameController = TextEditingController(
          text: user.displayName ?? '',
        );
        final phoneController = TextEditingController();

        // Show dialog to collect required information
        final result = await showDialog<Map<String, String>>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Complete Your Profile'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'Enter your full name',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: 'Enter your phone number',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (nameController.text.trim().isNotEmpty &&
                        phoneController.text.trim().isNotEmpty) {
                      Navigator.of(context).pop({
                        'name': nameController.text.trim(),
                        'phone': phoneController.text.trim(),
                      });
                    }
                  },
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );

        if (result == null) {
          await _auth.signOut();
          throw AuthException('Profile completion cancelled');
        }

        // Create new user document with job_seeker role and collected information
        await _firestore.collection('users').doc(user.uid).set({
          'name': result['name'],
          'email': user.email,
          'phone': result['phone'],
          'role': 'job_seeker',
          'photoUrl': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Check if existing user is a job seeker
        final userData = userDoc.data();
        if (userData == null || userData['role'] != 'job_seeker') {
          // Sign out if not a job seeker
          await _auth.signOut();
          throw AuthException(
            'Google sign in is only available for job seekers. Please use email/password login for recruiters.',
          );
        }
      }

      // Provide haptic feedback for successful Google sign-in
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 50);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          message =
              'An account already exists with the same email address but different sign-in credentials. Please sign in using the original method.';
          break;
        case 'invalid-credential':
          message = 'The credential is invalid or has expired.';
          break;
        case 'operation-not-allowed':
          message = 'Google sign in is not enabled. Please contact support.';
          break;
        case 'user-disabled':
          message = 'This user account has been disabled.';
          break;
        case 'user-not-found':
          message = 'No user found with this email.';
          break;
        case 'wrong-password':
          message = 'Wrong password provided.';
          break;
        case 'invalid-verification-code':
          message = 'The verification code is invalid.';
          break;
        case 'invalid-verification-id':
          message = 'The verification ID is invalid.';
          break;
        default:
          message =
              'An error occurred during Google sign in. Please try again.';
      }
      throw AuthException(message);
    } catch (e) {
      throw AuthException(
        'An unexpected error occurred during Google sign in: ${e.toString()}',
      );
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
