// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resume_master/screens/login.dart';
import 'package:intl/intl.dart';
import 'package:resume_master/screens/resume_form_page.dart';
import 'package:resume_master/services/auth_service.dart';
import 'package:resume_master/screens/resume_preview.dart';
import 'package:resume_master/widgets/bottom_nav_bar.dart';
import 'package:resume_master/screens/resume_score_screen.dart';
import 'package:resume_master/screens/profile_page.dart';
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
  List<Map<String, dynamic>> _resumes = [];
  bool _isLoading = true;
  String? _error;
  late AnimationController _animationController;
  late AnimationController _userNameTypingController;
  late AnimationController _greetingTypingController;
  String _animatedUserName = '';
  String _animatedGreeting = '';
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = 0;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
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
      _loadResumes();
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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _userNameTypingController.dispose();
    _greetingTypingController.dispose();
    _scrollController.dispose();
    super.dispose();
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
    final user = _authService.getCurrentUser();
    if (user != null) {
      String? name;
      try {
        // Attempt to fetch name from Firestore first
        final userData =
            await _firestore.collection('users').doc(user.uid).get();
        if (userData.exists && userData.data()?['name'] != null) {
          name = userData.data()?['name'];
        } else {
          // Fallback to Firebase displayName
          name = user.displayName;
          if (name == null || name.isEmpty) {
            // Final fallback to email prefix
            name = user.email?.split('@')[0] ?? 'User';
          }
        }
      } catch (e) {
        debugPrint('Error fetching name from Firestore: $e');
        // Fallback to Firebase displayName if Firestore fetch fails
        name = user.displayName;
        if (name == null || name.isEmpty) {
          // Final fallback to email prefix
          name = user.email?.split('@')[0] ?? 'User';
        }
      }

      if (mounted) {
        setState(() {
          userName = name;
          // Restart typing animation when userName is updated
          _animatedUserName = ''; // Clear previous text
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
      _error = null;
      _resumes = [];
    });

    final user = _authService.getCurrentUser();
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'User not authenticated';
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
        _error = 'Error loading resumes: ${e.toString()}';
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

  Future<void> _deleteResume(String resumeId) async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);
      await _firestore.collection('resumes').doc(resumeId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resume deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadResumes();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete resume: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('Error deleting resume: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 0) {
      // Stay on Home
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        fadePageRouteBuilder(const ResumeScoreScreen()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        fadePageRouteBuilder(const ProfilePage()),
      );
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

  Widget _buildResumeCard(Map<String, dynamic> resumeMap) {
    final createdAt =
        resumeMap['createdAt'] != null
            ? DateFormat(
              'MMM dd, yyyy HH:mm',
            ).format((resumeMap['createdAt'] as Timestamp).toDate())
            : 'Unknown';
    final updatedAt =
        resumeMap['updatedAt'] != null
            ? DateFormat(
              'MMM dd, yyyy HH:mm',
            ).format((resumeMap['updatedAt'] as Timestamp).toDate())
            : 'Never';

    final resume = Resume.fromMap(resumeMap, id: resumeMap['id']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(35),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResumeForm(resumeData: resumeMap),
              ),
            ).then((_) => _loadResumes());
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resume.title.isNotEmpty
                                ? resume.title
                                : 'Untitled Resume',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 12,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Created: $createdAt',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.update,
                                size: 12,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Updated: $updatedAt',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () => _downloadResumePDF(resume),
                      tooltip: 'Download PDF',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ResumePreview(resume: resume),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('Preview'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ResumeForm(resumeData: resumeMap),
                          ),
                        ).then((_) => _loadResumes());
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () async {
                        final shouldDelete = await showDialog<bool>(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('Delete Resume'),
                                content: const Text(
                                  'Are you sure you want to delete this resume? This action cannot be undone.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, true),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                        );

                        if (shouldDelete == true && mounted) {
                          try {
                            await _firestore
                                .collection('resumes')
                                .doc(resumeMap['id'])
                                .delete();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Resume deleted successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadResumes();
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error deleting resume: ${e.toString()}',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton:
          _resumes.isNotEmpty
              ? FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ResumeForm()),
                  ).then((_) => _loadResumes());
                },
                backgroundColor: Theme.of(context).colorScheme.primary,
                tooltip: 'Create New Resume',
                child: const Icon(Icons.add, color: Colors.white),
              )
              : null,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _loadResumes,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      AnimatedBuilder(
                        animation: _greetingTypingController,
                        builder: (BuildContext context, Widget? child) {
                          return Text(
                            _animatedGreeting,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                              fontFamily: 'CrimsonText',
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      AnimatedBuilder(
                        animation: _userNameTypingController,
                        builder: (BuildContext context, Widget? child) {
                          final textToAnimate =
                              userName != null
                                  ? '${_getFirstName(userName!)}!'
                                  : 'Guest!';
                          final int charactersToShow =
                              (textToAnimate.length *
                                      _userNameTypingController.value)
                                  .round();
                          _animatedUserName = textToAnimate.substring(
                            0,
                            charactersToShow,
                          );
                          return Text(
                            _animatedUserName,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontFamily: 'CrimsonText',
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 10.0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Build an ATS-Friendly Resume',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Create your professional resume with our easy-to-use tool.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        flex: 1,
                        child: Image.asset(
                          width: 300,
                          'assets/images/job.jpg',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Card(
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          initiallyExpanded: false,
                          maintainState: true,
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          childrenPadding: const EdgeInsets.all(16.0),
                          title: Container(
                            constraints: const BoxConstraints(
                              maxWidth: double.infinity,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    'Resume Guidelines',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildGuidelineSection('ATS Optimization', [
                                    'Use standard section headings (Experience, Education, Skills)',
                                    'Include relevant keywords from the job description',
                                    'Avoid tables, images, and complex formatting',
                                    'Use standard fonts (Arial, Calibri, Times New Roman)',
                                    'Keep file format as PDF or DOCX',
                                  ]),
                                  const SizedBox(height: 16),
                                  _buildGuidelineSection('Content Structure', [
                                    'Start with a compelling summary or objective',
                                    'List experience in reverse chronological order',
                                    'Use bullet points for achievements and responsibilities',
                                    'Quantify achievements with numbers and metrics',
                                    'Keep descriptions concise and action-oriented',
                                  ]),
                                  const SizedBox(height: 16),
                                  _buildGuidelineSection('For Fresh Graduates', [
                                    'Highlight relevant coursework and projects',
                                    'Include internships, volunteer work, and extracurricular activities',
                                    'Emphasize transferable skills and soft skills',
                                    'Showcase academic achievements and certifications',
                                    'Include relevant technical skills and tools',
                                  ]),
                                  const SizedBox(height: 16),
                                  _buildGuidelineSection(
                                    'For Experienced Professionals',
                                    [
                                      'Focus on recent and relevant experience',
                                      'Highlight leadership and management skills',
                                      'Showcase industry-specific achievements',
                                      'Include professional certifications and training',
                                      'Demonstrate career progression and growth',
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildGuidelineSection('General Tips', [
                                    'Keep resume length to 1-2 pages',
                                    'Proofread for spelling and grammar errors',
                                    'Use consistent formatting throughout',
                                    'Customize resume for each job application',
                                    'Include relevant contact information',
                                  ]),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Your Resumes',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontFamily: 'CrimsonText',
                            ),
                          ),
                          if (_resumes.isNotEmpty)
                            Text(
                              '${_resumes.length} ${_resumes.length == 1 ? 'Resume' : 'Resumes'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (_error != null)
                        FadeTransition(
                          opacity: _animationController,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.red[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _error!,
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _loadResumes,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Try Again'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (_resumes.isEmpty)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Welcome to Resume Master!',
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Create your first professional resume\nand start your career journey',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ResumeForm(),
                                    ),
                                  ).then((_) => _loadResumes());
                                },
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Create Your First Resume',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(35),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        AnimationLimiter(
                          child: Column(
                            children: AnimationConfiguration.toStaggeredList(
                              duration: const Duration(milliseconds: 375),
                              childAnimationBuilder:
                                  (widget) => SlideAnimation(
                                    horizontalOffset: 50.0,
                                    child: FadeInAnimation(child: widget),
                                  ),
                              children:
                                  _resumes
                                      .map((resume) => _buildResumeCard(resume))
                                      .toList(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildGuidelineSection(String title, List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ...points
            .map(
              (point) => Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        point,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ],
    );
  }
}
