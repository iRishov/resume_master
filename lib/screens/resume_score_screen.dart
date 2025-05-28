import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:resume_master/screens/resume_form_page.dart';
import 'package:resume_master/widgets/bottom_nav_bar.dart';
import 'package:resume_master/screens/home.dart';
import 'package:resume_master/services/resume_scoring_service.dart';

class ResumeScoreScreen extends StatefulWidget {
  const ResumeScoreScreen({super.key});

  @override
  State<ResumeScoreScreen> createState() => _ResumeScoreScreenState();
}

class _ResumeScoreScreenState extends State<ResumeScoreScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ResumeScoringService _scoringService = ResumeScoringService();
  List<Map<String, dynamic>> _resumes = [];
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 1; // Set to 1 for Score tab

  @override
  void initState() {
    super.initState();
    _fetchResumes();
  }

  Future<void> _fetchResumes() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      // First check if the user document exists
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        setState(() {
          _error = 'User profile not found';
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
        _error = 'Firebase error: ${e.message}';
        _isLoading = false;
      });
      debugPrint('Firebase error fetching resumes: ${e.code} - ${e.message}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error fetching resumes: ${e.toString()}';
        _isLoading = false;
      });
      debugPrint('Error fetching resumes: $e');
    }
  }

  Color _scoreColor(double score) {
    final scorePercentage = (score * 100).round().clamp(0, 100);
    if (scorePercentage >= 90)
      return const Color(0xFF1B5E20); // Dark Green - Excellent
    if (scorePercentage >= 80)
      return const Color(0xFF2E7D32); // Green - Very Good
    if (scorePercentage >= 70)
      return const Color(0xFF43A047); // Light Green - Good
    if (scorePercentage >= 60)
      return const Color(0xFFF57F17); // Amber - Average
    if (scorePercentage >= 50)
      return const Color(0xFFE65100); // Deep Orange - Below Average
    if (scorePercentage >= 40)
      return const Color(0xFFD84315); // Deep Orange - Poor
    return const Color(0xFFB71C1C); // Dark Red - Very Poor
  }

  Color _getSectionColor(double score) {
    final scorePercentage = (score * 100).round().clamp(0, 100);
    if (scorePercentage >= 90)
      return const Color(0xFFE8F5E9); // Light Green Background
    if (scorePercentage >= 80)
      return const Color(0xFFF1F8E9); // Very Light Green Background
    if (scorePercentage >= 70)
      return const Color(0xFFF9FBE7); // Light Lime Background
    if (scorePercentage >= 60)
      return const Color(0xFFFFFDE7); // Light Yellow Background
    if (scorePercentage >= 50)
      return const Color(0xFFFFF3E0); // Light Amber Background
    if (scorePercentage >= 40)
      return const Color(0xFFFFEBEE); // Light Red Background
    return const Color(0xFFFFEBEE); // Light Red Background
  }

  Color _getBorderColor(double score) {
    final scorePercentage = (score * 100).round().clamp(0, 100);
    if (scorePercentage >= 90)
      return const Color(0xFF81C784); // Light Green Border
    if (scorePercentage >= 80)
      return const Color(0xFFA5D6A7); // Very Light Green Border
    if (scorePercentage >= 70)
      return const Color(0xFFC5E1A5); // Light Lime Border
    if (scorePercentage >= 60)
      return const Color(0xFFFFF59D); // Light Yellow Border
    if (scorePercentage >= 50)
      return const Color(0xFFFFE082); // Light Amber Border
    if (scorePercentage >= 40)
      return const Color(0xFFFFAB91); // Light Orange Border
    return const Color(0xFFEF9A9A); // Light Red Border
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/profile');
    }
  }

  Widget _buildSectionScore(double score, String section) {
    final color = _scoreColor(score);
    final scorePercentage = (score * 100).round().clamp(0, 100);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getSectionColor(score),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getBorderColor(score), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getSectionIcon(section), color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            '$scorePercentage%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
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

  Widget _buildFeedbackList(List<String> items, {bool isStrengths = false}) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isStrengths ? Icons.check_circle : Icons.info,
                    color: isStrengths ? Colors.green : Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            isStrengths
                                ? Colors.green[700]
                                : Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildBadge(double score) {
    // Convert score to percentage
    final scorePercentage = (score * 100).round().clamp(0, 100);

    String badgeLabel;
    IconData badgeIcon;
    Color badgeColor;

    if (scorePercentage >= 90) {
      badgeLabel = 'Resume Master';
      badgeIcon = Icons.workspace_premium;
      badgeColor = const Color(0xFF1B5E20); // Dark Green
    } else if (scorePercentage >= 80) {
      badgeLabel = 'Resume Expert';
      badgeIcon = Icons.star;
      badgeColor = const Color(0xFF2E7D32); // Green
    } else if (scorePercentage >= 70) {
      badgeLabel = 'Resume Pro';
      badgeIcon = Icons.emoji_events;
      badgeColor = const Color(0xFF43A047); // Light Green
    } else if (scorePercentage >= 60) {
      badgeLabel = 'Resume Builder';
      badgeIcon = Icons.construction;
      badgeColor = const Color(0xFFF57F17); // Amber
    } else if (scorePercentage >= 50) {
      badgeLabel = 'Resume Learner';
      badgeIcon = Icons.school;
      badgeColor = const Color(0xFFE65100); // Deep Orange
    } else if (scorePercentage >= 40) {
      badgeLabel = 'Resume Starter';
      badgeIcon = Icons.flag;
      badgeColor = const Color(0xFFD84315); // Deep Orange
    } else {
      badgeLabel = 'Needs Work';
      badgeIcon = Icons.warning;
      badgeColor = const Color(0xFFB71C1C); // Dark Red
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getSectionColor(score),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getBorderColor(score), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, color: badgeColor, size: 14),
          const SizedBox(width: 4),
          Text(
            badgeLabel,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAverageStats(List<Map<String, dynamic>> resumes) {
    if (resumes.isEmpty) return const SizedBox.shrink();

    double totalScore = 0;
    double highestScore = 0;
    String highestBadge = 'Resume Starter';
    IconData highestBadgeIcon = Icons.flag;
    Color highestBadgeColor = const Color(0xFFD84315);

    for (var resume in resumes) {
      try {
        final scoreResult = _scoringService.calculateScore(resume);
        final sectionScores =
            scoreResult['sectionScores'] as Map<String, dynamic>;

        // Calculate average of section scores
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

        totalScore += averageScore;

        if (averageScore > highestScore) {
          highestScore = averageScore;
          if (averageScore >= 90) {
            highestBadge = 'Resume Master';
            highestBadgeIcon = Icons.workspace_premium;
            highestBadgeColor = const Color(0xFF1B5E20);
          } else if (averageScore >= 80) {
            highestBadge = 'Resume Expert';
            highestBadgeIcon = Icons.star;
            highestBadgeColor = const Color(0xFF2E7D32);
          } else if (averageScore >= 70) {
            highestBadge = 'Resume Pro';
            highestBadgeIcon = Icons.emoji_events;
            highestBadgeColor = const Color(0xFF43A047);
          } else if (averageScore >= 60) {
            highestBadge = 'Resume Builder';
            highestBadgeIcon = Icons.construction;
            highestBadgeColor = const Color(0xFFF57F17);
          } else if (averageScore >= 50) {
            highestBadge = 'Resume Learner';
            highestBadgeIcon = Icons.school;
            highestBadgeColor = const Color(0xFFE65100);
          } else if (averageScore >= 40) {
            highestBadge = 'Resume Starter';
            highestBadgeIcon = Icons.flag;
            highestBadgeColor = const Color(0xFFD84315);
          } else {
            highestBadge = 'Needs Work';
            highestBadgeIcon = Icons.warning;
            highestBadgeColor = const Color(0xFFB71C1C);
          }
        }
      } catch (e) {
        debugPrint('Error calculating score for resume in stats: $e');
        continue;
      }
    }

    final averageScore = resumes.isNotEmpty ? totalScore / resumes.length : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Overall Statistics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Average Score',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${averageScore.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _scoreColor(averageScore / 100),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Best Badge',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getSectionColor(highestScore / 100),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getBorderColor(highestScore / 100),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              highestBadgeIcon,
                              color: highestBadgeColor,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              highestBadge,
                              style: TextStyle(
                                color: highestBadgeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Total Resumes: ${resumes.length}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
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

      // Calculate average of section scores
      double sectionAverage = 0.0;
      int sectionCount = 0;
      for (final entry in sectionScores.entries) {
        if (entry.key != 'atsCompatibility') {
          // Exclude ATS score from average
          sectionAverage += entry.value as double;
          sectionCount++;
        }
      }
      final averageScore =
          sectionCount > 0 ? (sectionAverage / sectionCount) * 100 : 0.0;

      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        color: Colors.white,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            collapsedIconColor: Colors.grey[600],
            iconColor: Colors.grey[600],
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resume['personalInfo']?['fullName'] ?? 'Untitled Resume',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _scoreColor(averageScore / 100),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${averageScore.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildBadge(averageScore / 100),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children:
                      sectionScores.entries.map((entry) {
                        final score = entry.value as double;
                        return _buildSectionScore(score, entry.key);
                      }).toList(),
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
                  padding: const EdgeInsets.all(20),
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
                            const Divider(height: 32),
                            Row(
                              children: [
                                Icon(
                                  _getSectionIcon(section),
                                  color: _scoreColor(sectionScore),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  section.replaceFirst(
                                    section[0],
                                    section[0].toUpperCase(),
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                const Spacer(),
                                _buildSectionScore(sectionScore, section),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (strengths[section]?.isNotEmpty ?? false) ...[
                              const Text(
                                'Strengths',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _buildFeedbackList(
                                strengths[section]!,
                                isStrengths: true,
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (suggestions[section]?.isNotEmpty ?? false) ...[
                              const Text(
                                'Suggestions',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _buildFeedbackList(suggestions[section]!),
                              const SizedBox(height: 8),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resume['personalInfo']?['fullName'] ?? 'Untitled Resume',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Error calculating score',
                style: TextStyle(color: Colors.red[700], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Resume Scores',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
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
                  : _error != null
                  ? Center(
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
                          onPressed: _fetchResumes,
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
                  )
                  : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAverageStats(_resumes),
                        ..._resumes.map((resume) => _buildResumeCard(resume)),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/score.jpg',
                            width: double.infinity,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
