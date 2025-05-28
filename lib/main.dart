import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:resume_master/theme/app_theme.dart';
import 'package:resume_master/screens/splash.dart';
import 'package:resume_master/screens/home.dart';
import 'package:resume_master/screens/profile_page.dart';
import 'package:resume_master/screens/resume_score_screen.dart';
import 'package:resume_master/screens/startup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resume Master',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const Splash(),
        '/home': (context) => const Home(),
        '/profile': (context) => const ProfilePage(),
        '/scores': (context) => const ResumeScoreScreen(),
        '/startup': (context) => const Startup(),
      },
    );
  }
}
