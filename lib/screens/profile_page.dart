import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:resume_master/services/firebase_service.dart';
import 'package:resume_master/widgets/bottom_nav_bar.dart';
import 'package:resume_master/services/resume_scoring_service.dart';
import 'package:resume_master/services/auth_service.dart';
import 'package:resume_master/screens/resume_preview.dart';
import 'package:resume_master/screens/resume_score_screen.dart';
import 'package:resume_master/screens/home.dart';
import 'package:resume_master/theme/page_transitions.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final ResumeScoringService _scoringService = ResumeScoringService();
  bool _isLoading = false;
  String? _userName;
  String? _userEmail;
  int _currentIndex = 2; // Profile tab index
  int _resumeCount = 0;
  double _averageScore = 0;
  String _highestBadge = 'Resume Starter';
  Color _highestBadgeColor = Colors.red;
  IconData _highestBadgeIcon = Icons.flag;

  // Helper functions

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUserStats();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color _scoreColor(double score) {
    // Using Material Design 3 color palette with better contrast
    if (score >= 90) {
      return const Color(0xFF1B5E20); // Dark Green - Excellent
    } else if (score >= 80) {
      return const Color(0xFF2E7D32); // Green - Very Good
    } else if (score >= 70) {
      return const Color(0xFF43A047); // Light Green - Good
    } else if (score >= 60) {
      return const Color(0xFFF57F17); // Amber - Average
    } else if (score >= 50) {
      return const Color(0xFFE65100); // Deep Orange - Below Average
    } else if (score >= 40) {
      return const Color(0xFFD84315); // Deep Orange - Poor
    } else {
      return const Color(0xFFB71C1C); // Dark Red - Very Poor
    }
  }

  Color _getSectionColor(double score) {
    // Using a more subtle color palette for sections
    if (score >= 90) {
      return const Color(0xFFE8F5E9); // Light Green Background
    } else if (score >= 80) {
      return const Color(0xFFF1F8E9); // Very Light Green Background
    } else if (score >= 70) {
      return const Color(0xFFF9FBE7); // Light Lime Background
    } else if (score >= 60) {
      return const Color(0xFFFFFDE7); // Light Yellow Background
    } else if (score >= 50) {
      return const Color(0xFFFFF3E0); // Light Amber Background
    } else if (score >= 40) {
      return const Color(0xFFFFEBEE); // Light Red Background
    } else {
      return const Color(0xFFFFEBEE); // Light Red Background
    }
  }

  Color _getBorderColor(double score) {
    // Using subtle border colors
    if (score >= 90) {
      return const Color(0xFF81C784); // Light Green Border
    } else if (score >= 80) {
      return const Color(0xFFA5D6A7); // Very Light Green Border
    } else if (score >= 70) {
      return const Color(0xFFC5E1A5); // Light Lime Border
    } else if (score >= 60) {
      return const Color(0xFFFFF59D); // Light Yellow Border
    } else if (score >= 50) {
      return const Color(0xFFFFE082); // Light Amber Border
    } else if (score >= 40) {
      return const Color(0xFFFFAB91); // Light Orange Border
    } else {
      return const Color(0xFFEF9A9A); // Light Red Border
    }
  }

  Future<void> _loadUserStats() async {
    if (!mounted) return;
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get resume count and calculate stats
      final resumesSnapshot =
          await _firestore
              .collection('resumes')
              .where('userId', isEqualTo: user.uid)
              .get();

      double totalScore = 0;
      double highestScore = 0;
      String highestBadge = 'Resume Starter';
      Color highestBadgeColor = const Color(0xFFD84315);
      IconData highestBadgeIcon = Icons.flag;
      int resumeCount = resumesSnapshot.docs.length;

      for (var doc in resumesSnapshot.docs) {
        try {
          final data = doc.data();
          final scoreResult = _scoringService.calculateScore(data);
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

          // Track highest score and badge
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
          debugPrint('Error processing resume ${doc.id}: $e');
          continue;
        }
      }

      // Calculate average score
      final averageScore = resumeCount > 0 ? totalScore / resumeCount : 0.0;

      debugPrint(
        'Stats loaded - Resumes: $resumeCount, Score: $averageScore, Highest Badge: $highestBadge',
      );

      if (mounted) {
        setState(() {
          _resumeCount = resumeCount;
          _averageScore = averageScore;
          _highestBadge = highestBadge;
          _highestBadgeColor = highestBadgeColor;
          _highestBadgeIcon = highestBadgeIcon;
        });
      }
    } catch (e) {
      debugPrint('Error loading user stats: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading stats: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userData = await _firebaseService.getUserData(user.uid);
        if (userData.exists && mounted) {
          setState(() {
            _userName = userData.data()?['name'] ?? user.displayName;
            _userEmail = userData.data()?['email'] ?? user.email;
            _nameController.text = _userName ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editProfile() async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Profile'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Enter your name',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save'),
              ),
            ],
          ),
    );

    if (result == true && mounted) {
      try {
        setState(() => _isLoading = true);
        final user = _auth.currentUser;
        if (user == null) throw Exception('User not authenticated');

        final newName = _nameController.text.trim();
        if (newName.isEmpty) {
          throw Exception('Name cannot be empty');
        }

        // Update user profile in Firebase Auth
        await user.updateDisplayName(newName);

        // Update user profile in Firestore
        await _firebaseService.updateUserField(user.uid, {'name': newName});

        if (!mounted) return;
        setState(() => _userName = newName);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating profile: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _showHelpAndSupport() async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Help & Support'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Need help? Here are some resources:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildSupportItem(
                  'Email Support',
                  'ffalbus.com',
                  Icons.email_outlined,
                ),
                const SizedBox(height: 12),
                _buildSupportItem(
                  'FAQ',
                  'Visit our FAQ section',
                  Icons.help_outline,
                ),
                const SizedBox(height: 12),
                _buildSupportItem(
                  'Documentation',
                  'Read our documentation',
                  Icons.menu_book_outlined,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildSupportItem(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacement(context, fadePageRouteBuilder(const Home()));
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        fadePageRouteBuilder(const ResumeScoreScreen()),
      );
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/profile');
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    if (shouldLogout == true && mounted) {
      try {
        await _auth.signOut();
        if (mounted) {
          // Clear all navigation stack and go to login
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/startup',
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error logging out: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null && mounted) {
        setState(() => _isLoading = true);

        final user = _auth.currentUser;
        if (user == null) throw Exception('User not authenticated');

        // Upload image to Firebase Storage
        final imageUrl = await _firebaseService.uploadImage(
          File(image.path),
          user.uid,
        );

        // Update user profile in Firestore
        await _firebaseService.updateUserField(user.uid, {
          'profileImage': imageUrl,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDeleteAllResumes() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete All Resumes'),
            content: const Text(
              'Are you sure you want to delete ALL of your resumes? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete All'),
              ),
            ],
          ),
    );

    if (shouldDelete == true && mounted) {
      setState(() => _isLoading = true);
      try {
        final user = _auth.currentUser;
        if (user == null) {
          debugPrint('No user logged in to delete resumes.');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error: No user logged in.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        await _firebaseService.deleteAllResumes(user.uid);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All resumes deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh stats after deletion
          _loadUserStats();
        }
      } catch (e) {
        debugPrint('Error deleting all resumes: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete resumes: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 0.5,
            fontFamily: 'CrimsonText',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: () async {
                  await _loadUserData();
                  await _loadUserStats();
                },
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Doodle Image
                      Container(
                        height: 100,
                        width: double.infinity,
                        child: Image.asset(
                          'assets/images/doodle.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // User Info
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  _userName ?? 'User Name',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _userEmail ?? 'User Email',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Statistics Card
                            SizedBox(
                              width: double.infinity,
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.blue.withOpacity(0.05),
                                        Colors.blue.withOpacity(0.02),
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.analytics_outlined,
                                            color: Colors.blue[700],
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Your Statistics',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      // First row: Resumes and Average Score
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _buildStatColumnNew(
                                            'Resumes',
                                            _resumeCount.toString(),
                                            Icons.description_outlined,
                                            Colors.blue[700]!,
                                          ),
                                          const SizedBox(width: 20),
                                          _buildStatColumnNew(
                                            'Overall Score',
                                            '${_averageScore.toStringAsFixed(0)}%',
                                            Icons.emoji_events_outlined,
                                            _scoreColor(_averageScore),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      // Second row: Best Badge
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          _buildStatColumnNew(
                                            'Gained Badge',
                                            _highestBadge,
                                            _highestBadgeIcon,
                                            _highestBadgeColor,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Account Actions Section
                            Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.purple.withOpacity(0.05),
                                      Colors.purple.withOpacity(0.02),
                                    ],
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    _buildActionButtonRedesigned(
                                      'Edit Profile',
                                      Icons.edit_outlined,
                                      _editProfile,
                                    ),
                                    const Divider(
                                      height: 1,
                                      indent: 48,
                                      endIndent: 16,
                                    ),
                                    _buildActionButtonRedesigned(
                                      'Help & Support',
                                      Icons.help_outline,
                                      _showHelpAndSupport,
                                    ),
                                    const Divider(
                                      height: 1,
                                      indent: 48,
                                      endIndent: 16,
                                    ),
                                    _buildActionButtonRedesigned(
                                      'Delete All Resumes',
                                      Icons.delete_sweep_outlined,
                                      _handleDeleteAllResumes,
                                      isDestructive: true,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildActionButtonRedesigned(
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red[700] : Colors.purple[700],
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDestructive ? Colors.red[700] : Colors.black87,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: isDestructive ? Colors.red[700] : Colors.purple[700],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumnNew(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
