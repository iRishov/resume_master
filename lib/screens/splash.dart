// ignore_for_file: unused_import

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:resume_master/screens/home.dart';
import 'package:resume_master/screens/startup.dart';
import 'package:resume_master/services/auth_service.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final AuthService _authService = AuthService();
  StreamSubscription<User?>? _authSubscription;
  bool _isNavigating = false;

  void _navigateToScreen(Widget screen) {
    if (_isNavigating) return;
    _isNavigating = true;

    // Ensure we're not in a build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => screen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  void _handleAuthState(User? user) {
    if (!mounted || _isNavigating) return;
    _navigateToScreen(user != null ? const Home() : const Startup());
  }

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Start animation
    _animationController.forward();

    // Check initial auth state after animation
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      try {
        final user = _authService.getCurrentUser();
        _handleAuthState(user);
      } catch (e) {
        debugPrint('Error checking auth state: $e');
        if (mounted && !_isNavigating) {
          _navigateToScreen(const Startup());
        }
      }
    });

    // Listen to auth state changes
    _authSubscription = _authService.authStateChanges.listen(
      _handleAuthState,
      onError: (error) {
        debugPrint('Auth state error: $error');
        if (mounted && !_isNavigating) {
          _navigateToScreen(const Startup());
        }
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 150,
                  height: 150,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                Text(
                  'Resume Master',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black.withAlpha(128),
                        offset: const Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
