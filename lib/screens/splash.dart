// ignore_for_file: unused_import

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:resume_master/screens/home.dart';
import 'package:resume_master/screens/startup.dart';
import 'package:resume_master/services/auth_service.dart';
import 'package:resume_master/theme/app_theme.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<int> _sloganTypingAnimation;
  final String _sloganText = 'Land your dream job!';
  final AuthService _authService = AuthService();
  StreamSubscription<User?>? _authSubscription;
  bool _isNavigating = false;

  void _navigateToScreen(String route) {
    if (_isNavigating) return;
    _isNavigating = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, route);
    });
  }

  void _handleAuthState(User? user) {
    if (!mounted || _isNavigating) return;
    _navigateToScreen(user != null ? '/home' : '/startup');
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _sloganTypingAnimation = IntTween(
      begin: 0,
      end: _sloganText.length,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.linear),
      ),
    );

    _animationController.forward();

    Future.delayed(const Duration(seconds: 4, milliseconds: 500), () {
      if (!mounted) return;
      try {
        final user = _authService.getCurrentUser();
        _handleAuthState(user);
      } catch (e) {
        debugPrint('Error checking auth state: $e');
        if (mounted && !_isNavigating) {
          _navigateToScreen('/startup');
        }
      }
    });

    _authSubscription = _authService.authStateChanges.listen(
      _handleAuthState,
      onError: (error) {
        debugPrint('Auth state error: $error');
        if (mounted && !_isNavigating) {
          _navigateToScreen('/startup');
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
      body: Container(
        color: Colors.black,
        child: Stack(
          children: [
            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Slogan with typing animation
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _logoFadeAnimation.value > 0 ? 0.0 : 1.0,
                        child: Text(
                          _sloganText.substring(
                            0,
                            _sloganTypingAnimation.value,
                          ),
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            letterSpacing: 1.0,
                            fontStyle: FontStyle.italic,
                            fontFamily: 'CrimsonText',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  // Logo container with animations
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _logoFadeAnimation,
                        child: Transform.scale(
                          scale: _logoScaleAnimation.value,
                          child: Container(
                            height: 150,
                            width: 150,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
