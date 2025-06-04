// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:resume_master/screens/login.dart';
import 'package:resume_master/screens/signup.dart';
import 'package:resume_master/theme/app_theme.dart';

class Startup extends StatefulWidget {
  const Startup({super.key});

  @override
  State<Startup> createState() => _StartupState();
}

class _StartupState extends State<Startup> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<int> _typingAnimation;
  final String _subtitleText =
      'Your professional journey starts here'; // New subtitle text

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // Animation duration
    );

    _typingAnimation = IntTween(begin: 0, end: _subtitleText.length).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(
          0.5,
          1.0,
          curve: Curves.linear,
        ), // Start typing halfway
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Theme.of(context).colorScheme.surface, // Use theme surface color
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
            ), // Adjusted padding
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Center content horizontally
              children: [
                // Logo
                Center(
                  child: Image.asset(
                    'assets/images/logo.png', // Use your logo
                    height: 150, // Adjusted size
                    width: 150,
                  ),
                ),
                const SizedBox(height: 40), // Increased spacing
                // Title
                Text(
                  'Resume Master',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ), // Use theme style
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12), // Spacing
                // Subtitle with Typing Animation
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Text(
                      _subtitleText.substring(
                        0,
                        _typingAnimation.value,
                      ), // Typing effect
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.8),
                        fontSize: 20, // Increased font size
                      ), // Use theme style
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                const SizedBox(height: 60), // Increased spacing before buttons
                // Buttons
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Login(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(
                              context,
                            ).colorScheme.primary, // Theme primary color
                        foregroundColor:
                            Theme.of(
                              context,
                            ).colorScheme.onPrimary, // Theme onPrimary color
                        minimumSize: const Size(
                          double.infinity,
                          50,
                        ), // Full width
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            30,
                          ), // Theme roundedness
                        ),
                        elevation: 4, // Subtle elevation
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ), // Fixed style for button text
                      ),
                    ),
                    const SizedBox(height: 20), // Spacing between buttons
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUp(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            Theme.of(context)
                                .colorScheme
                                .primary, // Theme primary color for text
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1.5,
                        ), // Theme primary color for border
                        minimumSize: const Size(
                          double.infinity,
                          50,
                        ), // Full width
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            30,
                          ), // Theme roundedness
                        ),
                        elevation: 0, // No elevation for outlined button
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ), // Fixed style for button text
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
