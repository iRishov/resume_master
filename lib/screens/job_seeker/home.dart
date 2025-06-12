// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resume_master/screens/job_seeker/login.dart';
import 'package:intl/intl.dart';
import 'package:resume_master/screens/job_seeker/resume_form.dart';
import 'package:resume_master/screens/job_seeker/jobs_page.dart';
import 'package:resume_master/services/auth_service.dart';
import 'package:resume_master/screens/job_seeker/resume_preview.dart';
import 'package:resume_master/widgets/bottom_nav_bar.dart';
import 'package:resume_master/screens/job_seeker/resume_score.dart';
import 'package:resume_master/screens/job_seeker/profile_page.dart';
import 'package:resume_master/theme/page_transitions.dart';
import 'package:resume_master/services/pdf_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:resume_master/models/resume.dart';
import 'package:resume_master/services/resume_scoring_service.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String greeting = '';
  String? userName;
  String? userEmail;
  String? userPhoto;
  List<Map<String, dynamic>> _resumes = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late AnimationController _userNameTypingController;
  late AnimationController _greetingTypingController;
  String _animatedGreeting = '';
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadResumes();
    _startGreetingAnimation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _userNameTypingController.dispose();
    _greetingTypingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startGreetingAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _userNameTypingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // Adjust speed as needed
    );

    // Start fetching data and animations after the initial frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserName();
      _animationController.forward();
      _setGreeting(); // Set initial greeting and start its animation
    });

    _greetingTypingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Adjust speed as needed
    );

    _greetingTypingController.addListener(() {
      setState(() {
        final text = greeting; // Use the current greeting
        final int charactersToShow =
            (text.length * _greetingTypingController.value).round();
        _animatedGreeting = text.substring(0, charactersToShow);
      });
    });

    _checkAuth();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            userName = userData['name'] ?? 'User';
            userEmail = userData['email'] ?? '';
            userPhoto = userData['photoUrl'];
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    setState(() {
      if (hour < 12) {
        greeting = 'Good Morning';
      } else if (hour < 17) {
        greeting = 'Good Afternoon';
      } else {
        greeting = 'Good Evening';
      }
      // Restart typing animation for greeting when it changes
      _animatedGreeting = ''; // Clear previous text
      _greetingTypingController.value = 0; // Reset animation
      _greetingTypingController.forward();
    });
  }

  Future<void> _fetchUserName() async {
    final user = _authService.currentUser;
    if (user != null) {
      String? name;
      try {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          name = userDoc.data()?['name'] as String?;
        }
      } catch (e) {
        debugPrint('Error fetching user name: $e');
      }

      if (mounted) {
        setState(() {
          userName = name ?? 'User';
          // Restart typing animation when userName is updated
          // Clear previous text
          _userNameTypingController.value = 0; // Reset animation
          _userNameTypingController.forward();
        });
      }
    }
  }

  Future<void> _loadResumes() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _resumes = [];
    });

    final user = _authService.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _resumes = [];
      });
      return;
    }

    try {
      final snapshot =
          await _firestore
              .collection('resumes')
              .where('userId', isEqualTo: user.uid)
              .get();

      if (!mounted) return;

      if (snapshot.docs.isNotEmpty) {
        final resumes =
            snapshot.docs.map((doc) {
                final data = doc.data();
                return {'id': doc.id, ...data};
              }).toList()
              ..sort((a, b) {
                final aDate = a['updatedAt'] as Timestamp?;
                final bDate = b['updatedAt'] as Timestamp?;
                if (aDate == null && bDate == null) return 0;
                if (aDate == null) return 1;
                if (bDate == null) return -1;
                return bDate.compareTo(aDate);
              });

        if (resumes.isNotEmpty) {
          final latestResumeData = resumes.first;
          final scoringService = ResumeScoringService();
          final inferredFields = scoringService.inferUserField(
            latestResumeData,
          );
          scoringService.getPersonalizedMissingAtsKeywords(
            latestResumeData,
            inferredFields,
          );
          setState(() {
            _resumes = resumes;
          });
        } else {
          setState(() {
            _resumes = [];
          });
        }
      } else {
        setState(() {
          _resumes = [];
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resumes = [];
      });
      debugPrint('Error loading resumes: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'No date';
    if (date is Timestamp) {
      return DateFormat('MMM dd, yyyy').format(date.toDate());
    }
    return 'Invalid date';
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return const Color(0xFF1B5E20); // Dark Green
    if (score >= 80) return const Color(0xFF2E7D32); // Green
    if (score >= 70) return const Color(0xFF43A047); // Light Green
    if (score >= 60) return const Color(0xFFF57F17); // Amber
    if (score >= 50) return const Color(0xFFE65100); // Orange
    if (score >= 40) return const Color(0xFFD84315); // Deep Orange
    return const Color(0xFFB71C1C); // Red
  }

  IconData _getScoreIcon(int score) {
    if (score >= 90) return Icons.workspace_premium;
    if (score >= 80) return Icons.star;
    if (score >= 70) return Icons.emoji_events;
    if (score >= 60) return Icons.school;
    if (score >= 50) return Icons.flag;
    if (score >= 40) return Icons.rocket_launch;
    return Icons.auto_awesome;
  }

  Future<void> _deleteResume(Map<String, dynamic> resume) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Resume'),
            content: const Text(
              'Are you sure you want to delete this resume? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('resumes')
            .doc(resume['id'])
            .delete();
        _loadResumes();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting resume: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  String _getFirstName(String? fullName) {
    if (fullName == null || fullName.isEmpty) {
      return 'User';
    }
    final names = fullName.trim().split(' ');
    return names.isNotEmpty ? names.first : 'User';
  }

  Future<void> _downloadResumePDF(Resume resume) async {
    try {
      final pdfBytes = await PDFService.generateResumePDFModel(resume);
      final firstName = _getFirstName(
        resume.personalInfo['fullName'] as String?,
      );
      final filename = '${firstName.toLowerCase()}_resume.pdf';
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(pdfBytes as List<int>, flush: true);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My Resume',
        subject: 'Resume PDF',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onNavItemTapped(int index) {
    if (_currentIndex == index)
      return; // Don't do anything if same page is tapped

    setState(() {
      _currentIndex = index;
    });

    // Handle navigation based on index
    switch (index) {
      case 0: // Home
        // Already on home, do nothing
        break;
      case 1: // Scores
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ResumeScore(),
            settings: const RouteSettings(name: '/scores'),
          ),
        );
        break;
      case 2: // Jobs
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const JobsPage(),
            settings: const RouteSettings(name: '/jobs'),
          ),
        );
        break;
      case 3: // Profile
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfilePage(),
            settings: const RouteSettings(name: '/profile'),
          ),
        );
        break;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update current index based on route
    final route = ModalRoute.of(context)?.settings.name;
    if (route != null) {
      switch (route) {
        case '/home':
          _currentIndex = 0;
          break;
        case '/scores':
          _currentIndex = 1;
          break;
        case '/jobs':
          _currentIndex = 2;
          break;
        case '/profile':
          _currentIndex = 3;
          break;
      }
    }
  }

  void _showKeywordSuggestion(String keyword) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Keyword Suggestion: $keyword'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text(
                  'This keyword is important for ATS (Applicant Tracking Systems).',
                ),
                const SizedBox(height: 12),
                const Text('Consider adding it to the following sections:'),
                const SizedBox(height: 8),
                const Text('- Summary/Objective'),
                const Text('- Work Experience (in descriptions)'),
                const Text('- Skills Section'),
                const Text('- Projects (in descriptions)'),
                const SizedBox(height: 16),
                const Text(
                  'Would you like to edit your latest resume to add this keyword?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Maybe Later'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Edit Resume'),
              onPressed: () {
                Navigator.of(context).pop();
                if (_resumes.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ResumeForm(resumeData: _resumes.first),
                    ),
                  ).then((_) => _loadResumes());
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No resume to edit. Create one first!'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // If we're on the home page and it's the root, show exit dialog
        if (!Navigator.of(context).canPop()) {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Exit App'),
                  content: const Text('Are you sure you want to exit?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Yes'),
                    ),
                  ],
                ),
          );
          return shouldExit ?? false;
        }
        return true;
      },
      child: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          body: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                expandedHeight: 140.0,
                backgroundColor: Theme.of(context).colorScheme.primary,
                floating: true,
                pinned: false,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                  title: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _animatedGreeting,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 4),
                      Text(
                        userName ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                elevation: 0,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.help_outline),
                    onPressed: _showResumeGuidelines,
                    tooltip: 'Resume Guidelines',
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadResumes,
                    tooltip: 'Refresh',
                  ),
                ],
              ),

              // Resume Creation Guide Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: _showResumeCreationGuide,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Theme.of(context).colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Resume Creation Guide',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Learn how to create a professional resume',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // App Features Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: _showAppFeatures,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.rocket_launch,
                                  color: Colors.blue,
                                  size: 28,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'App Features',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Discover all the powerful features',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildFeatureChip('Job Search', Icons.work),
                                _buildFeatureChip(
                                  'Resume Builder',
                                  Icons.edit_document,
                                ),
                                _buildFeatureChip(
                                  'Career Tips',
                                  Icons.lightbulb,
                                ),
                                _buildFeatureChip(
                                  'Progress Tracking',
                                  Icons.trending_up,
                                ),
                                _buildFeatureChip(
                                  'Export Options',
                                  Icons.download,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Create Resume Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCreateResumeButton(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Resume List Section
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: _buildResumeList(),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: _currentIndex,
            onTap: _onNavItemTapped,
          ),
        ),
      ),
    );
  }

  Widget _buildResumeList() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_resumes.isEmpty) {
      return SliverFillRemaining(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No resumes yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first resume to get started',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final resume = _resumes[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () => _viewResume(resume),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                resume['title'] ?? 'Untitled Resume',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Last updated: ${_formatDate(resume['updatedAt'])}',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (resume['score'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getScoreColor(
                                resume['score'],
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getScoreIcon(resume['score']),
                                  size: 16,
                                  color: _getScoreColor(resume['score']),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${resume['score']}%',
                                  style: TextStyle(
                                    color: _getScoreColor(resume['score']),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              TextButton.icon(
                                onPressed: () => _viewResume(resume),
                                icon: const Icon(Icons.visibility_outlined),
                                label: const Text('Preview'),
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _editResume(resume),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit'),
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              TextButton.icon(
                                onPressed: () => _shareResume(resume),
                                icon: const Icon(Icons.share_outlined),
                                label: const Text('Share'),
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _deleteResume(resume),
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Delete'),
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
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
      }, childCount: _resumes.length),
    );
  }

  Widget _buildCreateResumeButton() {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width / 2,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ResumeForm()),
            );
          },
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Create New Resume',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkAuth() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/startup');
        }
        return;
      }

      // Verify user role
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists || userDoc.data()?['role'] == 'recruiter') {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/startup');
        }
        return;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {});
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/startup');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareResume(Map<String, dynamic> resume) async {
    try {
      // Show loading indicator only for the share operation
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final resumeObj = Resume.fromMap(resume);
      final pdfBytes = await PDFService.generateResumePDFModel(resumeObj);

      // Create filename based on first name
      final firstName = _getFirstName(
        resumeObj.personalInfo['fullName'] as String?,
      );
      final filename = '${firstName.toLowerCase()}_resume.pdf';

      // Write to a temp file for sharing
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(pdfBytes, flush: true);

      // Close the loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Share the file
      await Share.shareXFiles([XFile(file.path)], text: 'Check out my resume!');
    } catch (e) {
      // Close the loading dialog if it's still showing
      if (mounted) {
        Navigator.pop(context);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing resume: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showResumeGuidelines() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (context, scrollController) => Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.workspace_premium,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Resume Badges Guide',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Content
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            _buildBadgeInfo(
                              'Resume Champion',
                              'Score: 90-100%',
                              Icons.workspace_premium,
                              const Color(0xFF1B5E20),
                              'Perfect resume with exceptional content and formatting',
                            ),
                            const SizedBox(height: 12),
                            _buildBadgeInfo(
                              'Resume Star',
                              'Score: 80-89%',
                              Icons.star,
                              const Color(0xFF2E7D32),
                              'Excellent resume with strong content and good formatting',
                            ),
                            const SizedBox(height: 12),
                            _buildBadgeInfo(
                              'Resume Builder',
                              'Score: 70-79%',
                              Icons.emoji_events,
                              const Color(0xFF43A047),
                              'Professional resume with good content and formatting',
                            ),
                            const SizedBox(height: 12),
                            _buildBadgeInfo(
                              'Resume Learner',
                              'Score: 60-69%',
                              Icons.school,
                              const Color(0xFFF57F17),
                              'Good resume with room for improvement',
                            ),
                            const SizedBox(height: 12),
                            _buildBadgeInfo(
                              'Resume Starter',
                              'Score: 50-59%',
                              Icons.flag,
                              const Color(0xFFE65100),
                              'Basic resume that needs significant improvements',
                            ),
                            const SizedBox(height: 12),
                            _buildBadgeInfo(
                              'Getting Started',
                              'Score: 40-49%',
                              Icons.rocket_launch,
                              const Color(0xFFD84315),
                              'Initial resume that needs major improvements',
                            ),
                            const SizedBox(height: 12),
                            _buildBadgeInfo(
                              'Begin Your Journey',
                              'Score: Below 40%',
                              Icons.auto_awesome,
                              const Color(0xFFB71C1C),
                              'Resume requires complete revision',
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildBadgeInfo(
    String title,
    String score,
    IconData icon,
    Color color,
    String description,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  score,
                  style: TextStyle(color: color.withOpacity(0.8), fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editResume(Map<String, dynamic> resume) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ResumeForm(resumeData: resume)),
    );
  }

  void _viewResume(Map<String, dynamic> resume) {
    final resumeObj = Resume.fromMap(resume);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ResumePreview(resume: resumeObj)),
    );
  }

  void _showResumeCreationGuide() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder:
                (context, scrollController) => SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Theme.of(context).colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Resume Creation Guide',
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildGuideSection(
                          '1. Contact Information',
                          'Include your full name, phone number, email address, and LinkedIn profile (if available).',
                          Icons.contact_mail,
                        ),
                        _buildGuideSection(
                          '2. Professional Summary',
                          'Write a compelling summary that highlights your key qualifications and career objectives.',
                          Icons.description,
                        ),
                        _buildGuideSection(
                          '3. Work Experience',
                          'List your work history in reverse chronological order. Include company name, job title, dates, and key achievements.',
                          Icons.work,
                        ),
                        _buildGuideSection(
                          '4. Education',
                          'Include your highest degree, major, university name, graduation date, and relevant coursework.',
                          Icons.school,
                        ),
                        _buildGuideSection(
                          '5. Skills',
                          'List both technical and soft skills relevant to your target position.',
                          Icons.psychology,
                        ),
                        _buildGuideSection(
                          '6. Achievements',
                          'Highlight significant accomplishments, awards, or certifications.',
                          Icons.emoji_events,
                        ),
                        _buildGuideSection(
                          '7. Formatting Tips',
                          'Use consistent formatting, clear headings, and bullet points for better readability.',
                          Icons.format_list_bulleted,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Pro Tips:',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildProTip(
                          'Keep your resume concise and focused on relevant experience',
                        ),
                        _buildProTip(
                          'Use action verbs to describe your achievements',
                        ),
                        _buildProTip(
                          'Customize your resume for each job application',
                        ),
                        _buildProTip(
                          'Proofread carefully to avoid typos and grammatical errors',
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  Widget _buildGuideSection(String title, String content, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showAppFeatures() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder:
                (context, scrollController) => SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.rocket_launch,
                              color: Colors.blue,
                              size: 28,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'App Features',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Discover all the powerful features',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.blue,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildFeatureSection(
                          ' Resume Analysis',
                          'Get instant feedback and suggestions to improve your resume with our advanced technology.',
                          Icons.psychology,
                          [
                            'Content analysis and optimization',
                            'Grammar and spelling checks',
                            'Keyword optimization for ATS',
                            'Professional tone suggestions',
                          ],
                        ),
                        _buildFeatureSection(
                          'Smart Resume Builder',
                          'Create professional resumes with our easy-to-use builder and templates.',
                          Icons.edit_document,
                          [
                            'Multiple professional templates',
                            'Real-time formatting',
                            'Section-by-section guidance',
                            'Easy content organization',
                          ],
                        ),
                        _buildFeatureSection(
                          'Job Search Integration',
                          'Find and apply to jobs directly through the app.',
                          Icons.work,
                          [
                            'Browse job listings',
                            'One-click applications',
                            'Job tracking',
                            'Application status updates',
                          ],
                        ),
                        _buildFeatureSection(
                          'Career Development',
                          'Access resources to advance your career.',
                          Icons.trending_up,
                          [
                            'Career tips and advice',
                            'Industry insights',
                            'Skill development guides',
                            'Interview preparation',
                          ],
                        ),
                        _buildFeatureSection(
                          'Progress Tracking',
                          'Monitor your resume improvement journey.',
                          Icons.analytics,
                          [
                            'Resume score tracking',
                            'Improvement suggestions',
                            'Achievement badges',
                            'Progress history',
                          ],
                        ),
                        _buildFeatureSection(
                          'Export & Share',
                          'Share your resume in multiple formats.',
                          Icons.share,
                          [
                            'PDF export',
                            'Direct sharing options',
                            'Multiple format support',
                            'Cloud backup',
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  Widget _buildFeatureSection(
    String title,
    String description,
    IconData icon,
    List<String> features,
  ) {
    // Define different colors for different features
    Color iconColor;
    switch (title) {
      case 'Resume Scoring':
        iconColor = Colors.blue;
        break;
      case 'Smart Resume Builder':
        iconColor = Colors.purple;
        break;
      case 'Job Search Integration':
        iconColor = Colors.orange;
        break;
      case 'Career Development':
        iconColor = Colors.green;
        break;
      case 'Progress Tracking':
        iconColor = Colors.red;
        break;
      case 'Export & Share':
        iconColor = Colors.teal;
        break;
      default:
        iconColor = Theme.of(context).colorScheme.primary;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, color: iconColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feature,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
