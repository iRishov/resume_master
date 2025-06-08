// ignore_for_file: unused_import

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:resume_master/screens/user/home.dart';
import 'package:resume_master/screens/recruiter/recruiter_home.dart';
import 'package:resume_master/screens/startup.dart';
import 'package:resume_master/services/auth_service.dart';
import 'package:resume_master/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:lottie/lottie.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Widget> _getNextScreen() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        return const Startup();
      }

      // Check user role
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        return const Startup();
      }

      final role = userDoc.data()?['role'] as String?;
      if (role == 'recruiter') {
        return const RecruiterHomePage();
      } else {
        return const Home();
      }
    } catch (e) {
      return const Startup();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Center(
        child: Lottie.asset(
          'assets/images/animation.json',
          width: 300,
          height: 300,
        ),
      ),
      nextScreen: FutureBuilder<Widget>(
        future: _getNextScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Startup(); // Fallback while loading
          }
          return snapshot.data ?? const Startup();
        },
      ),
      splashIconSize: 500,
      backgroundColor: Colors.white,
      duration: 2000,
      splashTransition: SplashTransition.fadeTransition,
      animationDuration: const Duration(milliseconds: 2000),
      curve: Curves.easeInOut,
    );
  }
}
