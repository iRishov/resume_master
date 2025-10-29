import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:resume_master/screens/splash.dart';
import 'package:resume_master/screens/startup.dart';
import 'package:resume_master/screens/job_seeker/login.dart';
import 'package:resume_master/screens/job_seeker/signup.dart';
import 'package:resume_master/screens/job_seeker/home.dart';
import 'package:resume_master/screens/job_seeker/resume_score.dart';
import 'package:resume_master/screens/job_seeker/jobs_page.dart';
import 'package:resume_master/screens/job_seeker/profile_page.dart';
import 'package:resume_master/screens/recruiter/recruiter_login.dart';
import 'package:resume_master/screens/recruiter/recruiter_signup.dart';
import 'package:resume_master/screens/recruiter/recruiter_home.dart';
import 'package:resume_master/screens/recruiter/recruiter_profile.dart';
import 'package:resume_master/screens/recruiter/job_posting_page.dart';
import 'package:resume_master/services/auth_service.dart';
import 'package:resume_master/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Web-specific initialization
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCsA7j4ekgqRITTxLkkkcUSV",
        authDomain: "resume-master-61af6.firebaseapp.com",
        projectId: "resume-master-61af6",
        storageBucket: "resume-master-61af6.firebasestorage.app",
        messagingSenderId: "541168145892",
        appId: "1:541168145892:web:024bd92ffcbf48f600e3f1",
      ),
    );
    print('Running on Web platform');
  } else {
    // Mobile/Desktop initialization
    await Firebase.initializeApp();
    print('Running on Mobile platform');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Resume Master',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final width = mediaQuery.size.width;
        final textScaleFactor = mediaQuery.textScaleFactor;
        
        // Calculate responsive text scale based on screen width
        double responsiveScale = 1.0;
        
        if (width < 360) {
          // Small phones
          responsiveScale = 0.85;
        } else if (width < 400) {
          // Regular phones
          responsiveScale = 0.9;
        } else if (width < 768) {
          // Large phones
          responsiveScale = 1.0;
        } else if (width < 1024) {
          // Tablets
          responsiveScale = 1.15;
        } else {
          // Large screens
          responsiveScale = 1.25;
        }
        
        // Combine with accessibility text scale factor
        final scale = (responsiveScale * textScaleFactor).clamp(0.8, 1.5);
        
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaleFactor: scale,
          ),
          child: child!,
        );
      },
      theme: AppTheme.lightTheme,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const Splash(),
        '/startup': (context) => const Startup(),
        '/login': (context) => const Login(),
        '/signup': (context) => const SignUp(),
        '/recruiter-login': (context) => const RecruiterLogin(),
        '/recruiter-signup': (context) => const RecruiterSignUp(),
        '/recruiter-home': (context) => const RecruiterHomePage(),
        '/recruiter-profile': (context) => const RecruiterProfile(),
        '/job-posting': (context) => const JobPostingPage(),
        '/home': (context) => const Home(),
        '/scores': (context) => const ResumeScore(),
        '/jobs': (context) => const JobsPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}
