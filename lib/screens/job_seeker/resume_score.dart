import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:resume_master/screens/job_seeker/resume_form.dart';
import 'package:resume_master/widgets/bottom_nav_bar.dart';
import 'package:resume_master/screens/job_seeker/home.dart';
import 'package:resume_master/screens/job_seeker/profile_page.dart';
import 'package:resume_master/screens/job_seeker/jobs_page.dart';
import 'package:resume_master/services/resume_scoring_service.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:resume_master/theme/page_transitions.dart';

class ResumeScore extends StatefulWidget {
  const ResumeScore({super.key});

  @override
  State<ResumeScore> createState() => _ResumeScoreState();
}

class _ResumeScoreState extends State<ResumeScore>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ResumeScoringService _scoringService = ResumeScoringService();
  List<Map<String, dynamic>> _resumes = [];
  bool _isLoading = true;
  int _currentIndex = 1; // Set to 1 for Score tab

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _fetchResumes();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

  Future<void> _fetchResumes() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // First check if the user document exists
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Fetch resumes with a simpler query
      final snapshot =
          await _firestore
              .collection('resumes')
              .where('userId', isEqualTo: user.uid)
              .get();

      if (!mounted) return;

      if (snapshot.docs.isNotEmpty) {
        // Sort the documents in memory instead of using orderBy
        final resumes =
            snapshot.docs.map((doc) {
                final data = doc.data();
                // Ensure all required fields are present
                if (!data.containsKey('personalInfo')) {
                  data['personalInfo'] = {'fullName': 'Untitled Resume'};
                }
                return {'id': doc.id, ...data};
              }).toList()
              ..sort((a, b) {
                final aTime = a['updatedAt'] as Timestamp?;
                final bTime = b['updatedAt'] as Timestamp?;
                if (aTime == null || bTime == null) return 0;
                return bTime.compareTo(aTime); // Sort in descending order
              });

        setState(() {
          _resumes = resumes;
          _isLoading = false;
        });
      } else {
        setState(() {
          _resumes = [];
          _isLoading = false;
        });
      }
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      debugPrint('Firebase error fetching resumes: ${e.code} - ${e.message}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error fetching resumes: $e');
    }
  }

  Color _scoreColor(double score) {
    final scorePercentage = (score * 100).round().clamp(0, 100);
    if (scorePercentage >= 90) return const Color(0xFF2E7D32); // Deep Green
    if (scorePercentage >= 80) return const Color(0xFF43A047); // Green
    if (scorePercentage >= 70) return const Color(0xFF1E88E5); // Blue
    if (scorePercentage >= 60) return const Color(0xFFF57F17); // Amber
    if (scorePercentage >= 50) return const Color(0xFFE65100); // Deep Orange
    if (scorePercentage >= 40) return const Color(0xFFD84315); // Orange
    return const Color(0xFFB71C1C); // Deep Red
  }

  Color _getSectionColor(double score) {
    final scorePercentage = (score * 100).round().clamp(0, 100);
    if (scorePercentage >= 90) return const Color(0xFF2E7D32).withOpacity(0.1);
    if (scorePercentage >= 80) return const Color(0xFF43A047).withOpacity(0.1);
    if (scorePercentage >= 70) return const Color(0xFF1E88E5).withOpacity(0.1);
    if (scorePercentage >= 60) return const Color(0xFFF57F17).withOpacity(0.1);
    if (scorePercentage >= 50) return const Color(0xFFE65100).withOpacity(0.1);
    if (scorePercentage >= 40) return const Color(0xFFD84315).withOpacity(0.1);
    return const Color(0xFFB71C1C).withOpacity(0.1);
  }

  Color _getBorderColor(double score) {
    final scorePercentage = (score * 100).round().clamp(0, 100);
    if (scorePercentage >= 90) return const Color(0xFF2E7D32).withOpacity(0.3);
    if (scorePercentage >= 80) return const Color(0xFF43A047).withOpacity(0.3);
    if (scorePercentage >= 70) return const Color(0xFF1E88E5).withOpacity(0.3);
    if (scorePercentage >= 60) return const Color(0xFFF57F17).withOpacity(0.3);
    if (scorePercentage >= 50) return const Color(0xFFE65100).withOpacity(0.3);
    if (scorePercentage >= 40) return const Color(0xFFD84315).withOpacity(0.3);
    return const Color(0xFFB71C1C).withOpacity(0.3);
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return; // Don't navigate if already on the tab

    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0: // Home
        Navigator.pushReplacement(context, slidePageRouteBuilder(const Home()));
        break;
      case 1: // Scores
        // Already on scores page
        break;
      case 2: // Jobs
        Navigator.pushReplacement(
          context,
          slidePageRouteBuilder(const JobsPage()),
        );
        break;
      case 3: // Profile
        Navigator.pushReplacement(
          context,
          slidePageRouteBuilder(const ProfilePage()),
        );
        break;
    }
  }

  Widget _buildSectionScore(double score, String section) {
    final color = _scoreColor(score);
    final scorePercentage = (score * 100).round().clamp(0, 100);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: _getSectionColor(score),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getBorderColor(score), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getSectionIcon(section), color: color, size: 16),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$scorePercentage%',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSectionIcon(String section) {
    switch (section) {
      case 'personalInfo':
        return Icons.person;
      case 'summary':
        return Icons.description;
      case 'objective':
        return Icons.flag;
      case 'education':
        return Icons.school;
      case 'experience':
        return Icons.work;
      case 'skills':
        return Icons.psychology;
      case 'projects':
        return Icons.code;
      case 'certifications':
        return Icons.card_membership;
      default:
        return Icons.star;
    }
  }

  Widget _buildFeedbackItem(String text, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.4,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackList(List<String> items, {bool isStrengths = false}) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          items.map((item) {
            String emoji = isStrengths ? '✨ ' : '💡 ';
            return _buildFeedbackItem(
              emoji + item,
              isStrengths ? Icons.check_circle : Icons.lightbulb_outline,
              isStrengths ? Colors.green[800]! : Colors.orange[800]!,
            );
          }).toList(),
    );
  }

  Widget _buildBadge(double score) {
    final scorePercentage = (score * 100).round().clamp(0, 100);

    String badgeLabel;
    IconData badgeIcon;
    Color badgeColor;

    if (scorePercentage >= 90) {
      badgeLabel = 'Resume Champion';
      badgeIcon = Icons.workspace_premium;
      badgeColor = const Color(0xFF1B5E20);
    } else if (scorePercentage >= 80) {
      badgeLabel = 'Resume Star';
      badgeIcon = Icons.star;
      badgeColor = const Color(0xFF2E7D32);
    } else if (scorePercentage >= 70) {
      badgeLabel = 'Resume Builder';
      badgeIcon = Icons.emoji_events;
      badgeColor = const Color(0xFF43A047);
    } else if (scorePercentage >= 60) {
      badgeLabel = 'Resume Learner';
      badgeIcon = Icons.school;
      badgeColor = const Color(0xFFF57F17);
    } else if (scorePercentage >= 50) {
      badgeLabel = 'Resume Starter';
      badgeIcon = Icons.flag;
      badgeColor = const Color(0xFFE65100);
    } else if (scorePercentage >= 40) {
      badgeLabel = 'Getting Started';
      badgeIcon = Icons.rocket_launch;
      badgeColor = const Color(0xFFD84315);
    } else {
      badgeLabel = 'Begin Your Journey';
      badgeIcon = Icons.auto_awesome;
      badgeColor = const Color(0xFFB71C1C);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _getSectionColor(score),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getBorderColor(score), width: 2),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, color: badgeColor, size: 20),
          const SizedBox(width: 5),
          Text(
            badgeLabel,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAverageStats(List<Map<String, dynamic>> resumes) {
    if (resumes.isEmpty) return const SizedBox.shrink();

    final stats = _scoringService.calculateAverageScore(resumes);
    final averageScore = stats['averageScore'];
    final highestBadge = stats['highestBadge'];
    final highestBadgeIcon = stats['highestBadgeIcon'];
    final highestBadgeColor = stats['highestBadgeColor'];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.secondary.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 500) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildScoreSection(averageScore),
                    const SizedBox(height: 15),
                    _buildBadgeSection(
                      highestBadge,
                      highestBadgeIcon,
                      highestBadgeColor,
                    ),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildScoreSection(averageScore),
                  _buildBadgeSection(
                    highestBadge,
                    highestBadgeIcon,
                    highestBadgeColor,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Resumes: ${resumes.length}',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ResumeForm()),
                  ).then((_) => _fetchResumes());
                },
                icon: const Icon(Icons.add),
                label: const Text('Create'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSection(double averageScore) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Average Score',
          style: TextStyle(
            fontSize: 20,
            color: Colors.grey[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${averageScore.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: _scoreColor(averageScore / 100),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeSection(
    String highestBadge,
    IconData highestBadgeIcon,
    Color highestBadgeColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: highestBadgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: highestBadgeColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: highestBadgeColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(highestBadgeIcon, color: highestBadgeColor, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              highestBadge,
              style: TextStyle(
                color: highestBadgeColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeCard(Map<String, dynamic> resume) {
    try {
      final scoreResult = _scoringService.calculateScore(resume);
      final sectionScores =
          scoreResult['sectionScores'] as Map<String, dynamic>;
      final suggestions =
          scoreResult['suggestions'] as Map<String, List<String>>;
      final strengths = scoreResult['strengths'] as Map<String, List<String>>;
      final detailedFeedback =
          scoreResult['overallFeedback']['detailedFeedback']
              as Map<String, Map<String, dynamic>>;

      double sectionAverage = 0.0;
      int sectionCount = 0;
      for (final entry in sectionScores.entries) {
        if (entry.key != 'atsCompatibility') {
          sectionAverage += entry.value as double;
          sectionCount++;
        }
      }
      final averageScore =
          sectionCount > 0 ? (sectionAverage / sectionCount) * 100 : 0.0;

      return Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        color: Colors.white,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            collapsedIconColor: Colors.grey[600],
            iconColor: Colors.grey[600],
            tilePadding: const EdgeInsets.all(20),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        resume['title'] ??
                            resume['personalInfo']?['fullName'] ??
                            'Untitled Resume',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _scoreColor(averageScore / 100),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _scoreColor(
                              averageScore / 100,
                            ).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${averageScore.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBadge(averageScore / 100),
                    const SizedBox(height: 10),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      mainAxisSpacing: 5,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.8,
                      children:
                          sectionScores.entries.map((entry) {
                            final score = entry.value as double;
                            return _buildSectionScore(score, entry.key);
                          }).toList(),
                    ),
                  ],
                ),
              ],
            ),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...detailedFeedback.entries.map((entry) {
                        final section = entry.key;
                        final feedback = entry.value;
                        final sectionScore = feedback['score'] as double;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(height: 40),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _getSectionColor(sectionScore),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getSectionIcon(section),
                                    color: _scoreColor(sectionScore),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    section.replaceFirst(
                                      section[0],
                                      section[0].toUpperCase(),
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                _buildSectionScore(sectionScore, section),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (strengths[section]?.isNotEmpty ?? false) ...[
                              Text(
                                'Strengths',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.green[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildFeedbackList(
                                strengths[section]!,
                                isStrengths: true,
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (suggestions[section]?.isNotEmpty ?? false) ...[
                              Text(
                                'Suggestions',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.orange[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildFeedbackList(suggestions[section]!),
                              const SizedBox(height: 16),
                            ],
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error calculating score for resume: $e');
      return Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resume['title'] ??
                    resume['personalInfo']?['fullName'] ??
                    'Untitled Resume',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Error calculating score',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate back to home page
        Navigator.pushReplacement(context, slidePageRouteBuilder(const Home()));
        return false;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          toolbarHeight: 70,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                ],
              ),
            ),
          ),
          title: const Text(
            'Scores',
            style: TextStyle(
              fontFamily: 'CrimsonText',
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 30,
            ),
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _fetchResumes,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _fetchResumes,
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _resumes.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.assignment_outlined,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.analytics_outlined,
                                      size: 24,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No Resumes Found',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Create your first resume to see scores',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ResumeForm(),
                                ),
                              ).then((_) => _fetchResumes());
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Create Resume'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
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
                    )
                    : AnimationLimiter(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: AnimationConfiguration.toStaggeredList(
                          duration: const Duration(milliseconds: 375),
                          childAnimationBuilder:
                              (widget) => SlideAnimation(
                                horizontalOffset: 50.0,
                                child: FadeInAnimation(child: widget),
                              ),
                          children: [
                            _buildAverageStats(_resumes),
                            ..._resumes.map(
                              (resume) => _buildResumeCard(resume),
                            ),
                          ],
                        ),
                      ),
                    ),
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
        ),
      ),
    );
  }
}
