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
import 'package:resume_master/screens/job_seeker/resume_preview.dart';
import 'package:resume_master/screens/job_seeker/resume_score.dart';
import 'package:resume_master/screens/job_seeker/home.dart';
import 'package:resume_master/theme/page_transitions.dart';
import 'package:intl/intl.dart';
import 'package:resume_master/screens/job_seeker/jobs_page.dart';

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
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final ResumeScoringService _scoringService = ResumeScoringService();
  bool _isLoading = false;
  String? _userName;
  String? _userEmail;
  String? _userPhone;
  int _currentIndex = 3; // Profile tab index
  int _resumeCount = 0;
  double _averageScore = 0;
  String _highestBadge = 'Resume Starter';
  Color _highestBadgeColor = Colors.red;
  IconData _highestBadgeIcon = Icons.flag;
  List<Map<String, dynamic>> _applications = [];
  bool _isLoadingApplications = true;

  // Helper functions

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUserStats();
    _loadApplications();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Color _scoreColor(double score) {
    if (score >= 90) {
      return Theme.of(context).colorScheme.primary;
    } else if (score >= 80) {
      return Theme.of(context).colorScheme.primary.withOpacity(0.8);
    } else if (score >= 70) {
      return Theme.of(context).colorScheme.primary.withOpacity(0.6);
    } else if (score >= 60) {
      return Theme.of(context).colorScheme.secondary;
    } else if (score >= 50) {
      return Theme.of(context).colorScheme.error;
    } else if (score >= 40) {
      return Theme.of(context).colorScheme.error.withOpacity(0.8);
    } else {
      return Theme.of(context).colorScheme.error.withOpacity(0.6);
    }
  }

  Color _getSectionColor(double score) {
    // Using theme colors for sections
    if (score >= 90) {
      return Theme.of(context).colorScheme.primary.withOpacity(0.1);
    } else if (score >= 80) {
      return Theme.of(context).colorScheme.primary.withOpacity(0.08);
    } else if (score >= 70) {
      return Theme.of(context).colorScheme.primary.withOpacity(0.06);
    } else if (score >= 60) {
      return Theme.of(context).colorScheme.secondary.withOpacity(0.1);
    } else if (score >= 50) {
      return Theme.of(context).colorScheme.error.withOpacity(0.1);
    } else if (score >= 40) {
      return Theme.of(context).colorScheme.error.withOpacity(0.08);
    } else {
      return Theme.of(context).colorScheme.error.withOpacity(0.06);
    }
  }

  Color _getBorderColor(double score) {
    // Using theme colors for borders
    if (score >= 90) {
      return Theme.of(context).colorScheme.primary.withOpacity(0.3);
    } else if (score >= 80) {
      return Theme.of(context).colorScheme.primary.withOpacity(0.2);
    } else if (score >= 70) {
      return Theme.of(context).colorScheme.primary.withOpacity(0.1);
    } else if (score >= 60) {
      return Theme.of(context).colorScheme.secondary.withOpacity(0.3);
    } else if (score >= 50) {
      return Theme.of(context).colorScheme.error.withOpacity(0.3);
    } else if (score >= 40) {
      return Theme.of(context).colorScheme.error.withOpacity(0.2);
    } else {
      return Theme.of(context).colorScheme.error.withOpacity(0.1);
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

      final resumes = resumesSnapshot.docs.map((doc) => doc.data()).toList();
      final stats = _scoringService.calculateAverageScore(resumes);

      setState(() {
        _resumeCount = resumes.length;
        _averageScore = stats['averageScore'];
        _highestBadge = stats['highestBadge'];
        _highestBadgeColor = stats['highestBadgeColor'];
        _highestBadgeIcon = stats['highestBadgeIcon'];
      });

      debugPrint(
        'Stats loaded - Resumes: $_resumeCount, Score: $_averageScore, Highest Badge: $_highestBadge',
      );
    } catch (e) {
      debugPrint('Error loading user stats: $e');
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
          final data = userData.data()!;
          setState(() {
            _userName = data['name'] ?? user.displayName ?? 'Not set';
            _userEmail = data['email'] ?? user.email ?? 'Not set';
            _userPhone = data['phone'] ?? 'Not set';
            _nameController.text = _userName!;
            _phoneController.text = _userPhone!;
            _emailController.text = _userEmail!;
          });
        } else {
          // If no user data exists, create it with default values
          await _firebaseService.addUserToDatabase(
            user,
            name: user.displayName ?? 'Not set',
          );
          setState(() {
            _userName = user.displayName ?? 'Not set';
            _userEmail = user.email ?? 'Not set';
            _userPhone = 'Not set';
            _nameController.text = _userName!;
            _phoneController.text = _userPhone!;
            _emailController.text = _userEmail!;
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
            'Profile',
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
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _handleLogout,
              tooltip: 'Logout',
            ),
          ],
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                  onRefresh: _loadUserData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildUserDetails(),
                          const SizedBox(height: 24),
                          _buildResumeSection(),
                          const SizedBox(height: 24),
                          _buildApplicationsSection(),
                        ],
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

  Widget _buildUserDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'User Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.person_outline,
            'Name',
            _userName ?? 'Not set',
            () => _editField('name'),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.email_outlined,
            'Email',
            _userEmail ?? 'Not set',
            () => _editField('email'),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.phone_outlined,
            'Phone',
            _userPhone ?? 'Not set',
            () => _editField('phone'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    VoidCallback onEdit,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: Icon(
              Icons.edit_outlined,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: 'Edit $label',
          ),
        ],
      ),
    );
  }

  Future<void> _editField(String field) async {
    final controller =
        field == 'name'
            ? _nameController
            : field == 'email'
            ? _emailController
            : _phoneController;
    final label =
        field == 'name'
            ? 'Name'
            : field == 'email'
            ? 'Email'
            : 'Phone';
    final icon =
        field == 'name'
            ? Icons.person_outline
            : field == 'email'
            ? Icons.email_outlined
            : Icons.phone_outlined;

    // Set initial value
    controller.text =
        field == 'name'
            ? _userName ?? ''
            : field == 'email'
            ? _userEmail ?? ''
            : _userPhone ?? '';

    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Edit $label'),
              ],
            ),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
                prefixIcon: Icon(icon),
              ),
              keyboardType:
                  field == 'email'
                      ? TextInputType.emailAddress
                      : field == 'phone'
                      ? TextInputType.phone
                      : TextInputType.name,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (field == 'phone') {
                    // Validate phone number
                    if (!RegExp(
                      r'^\+?[\d\s-]{10,}$',
                    ).hasMatch(controller.text)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid phone number'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                  }
                  Navigator.of(context).pop(controller.text);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        final user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).update({
            field: result,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          setState(() {
            if (field == 'name') {
              _userName = result;
            } else if (field == 'email') {
              _userEmail = result;
            } else if (field == 'phone') {
              _userPhone = result;
            }
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating $label: ${e.toString()}'),
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
        Navigator.pushReplacement(
          context,
          slidePageRouteBuilder(const ResumeScore()),
        );
        break;
      case 2: // Jobs
        Navigator.pushReplacement(
          context,
          slidePageRouteBuilder(const JobsPage()),
        );
        break;
      case 3: // Profile
        // Already on profile page
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

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    if (shouldLogout == true) {
      try {
        await _auth.signOut();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/startup',
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadApplications() async {
    if (!mounted) return;
    setState(() => _isLoadingApplications = true);
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      debugPrint('Loading applications for user: ${user.uid}');

      final applicationsSnapshot =
          await _firestore
              .collection('applications')
              .where('applicantId', isEqualTo: user.uid)
              .get();

      debugPrint('Found ${applicationsSnapshot.docs.length} applications');

      if (mounted) {
        setState(() {
          _applications =
              applicationsSnapshot.docs.map((doc) {
                final data = doc.data();
                debugPrint('Application data: ${data.toString()}');
                return {
                  'id': doc.id,
                  ...data,
                  'createdAt':
                      data['createdAt'] ?? FieldValue.serverTimestamp(),
                };
              }).toList();
          _isLoadingApplications = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading applications: $e');
      if (mounted) {
        setState(() => _isLoadingApplications = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading applications: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Date not available';

    try {
      if (date is Timestamp) {
        final DateTime dateTime = date.toDate();
        return DateFormat('MMM dd, yyyy').format(dateTime);
      } else if (date is DateTime) {
        return DateFormat('MMM dd, yyyy').format(date);
      } else if (date is String) {
        final DateTime dateTime = DateTime.parse(date);
        return DateFormat('MMM dd, yyyy').format(dateTime);
      }
      return 'Invalid date format';
    } catch (e) {
      return 'Date not available';
    }
  }

  Widget _buildResumeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Resume Stats',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  Icons.description_outlined,
                  'Total Resumes',
                  _resumeCount.toString(),
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  Icons.analytics_outlined,
                  'Average Score',
                  '${_averageScore.toStringAsFixed(1)}%',
                  _scoreColor(_averageScore),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).secondaryHeaderColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _getBorderColor(_averageScore)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _highestBadgeColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _highestBadgeIcon,
                    color: _highestBadgeColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Highest Badge',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _highestBadge,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 20,
                          color: _highestBadgeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsSection() {
    if (_isLoadingApplications) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No applications yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your job applications will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _applications.length,
      itemBuilder: (context, index) {
        final application = _applications[index];
        return _buildApplicationCard(application);
      },
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> application) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          _firestore.collection('job_postings').doc(application['jobId']).get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error loading job details'),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Job not found'),
            ),
          );
        }

        final job = snapshot.data!.data() as Map<String, dynamic>;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: InkWell(
            onTap: () => _showJobDetails(application),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          job['title'] ?? 'Untitled Job',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              application['status'] == 'accepted'
                                  ? Colors.green.withOpacity(0.1)
                                  : application['status'] == 'rejected'
                                  ? Colors.red.withOpacity(0.1)
                                  : application['status'] == 'interview'
                                  ? Colors.blue.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          application['status'].toString().toUpperCase(),
                          style: TextStyle(
                            color:
                                application['status'] == 'accepted'
                                    ? Colors.green
                                    : application['status'] == 'rejected'
                                    ? Colors.red
                                    : application['status'] == 'interview'
                                    ? Colors.blue
                                    : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job['company'] ?? 'Company Name',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Applied on ${_formatDate(application['createdAt'])}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showJobDetails(Map<String, dynamic> application) async {
    try {
      // Get the job details from Firestore
      final jobDoc =
          await _firestore
              .collection('job_postings')
              .doc(application['jobId'])
              .get();

      if (!jobDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Job details not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final job = jobDoc.data()!;
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:
            (context) => DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder:
                  (context, scrollController) => Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      application['jobTitle'] ?? 'Untitled Job',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      application['companyName'] ??
                                          'Company Name',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Application Status
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      application['status'],
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    application['status'] ?? 'Pending',
                                    style: TextStyle(
                                      color: _getStatusColor(
                                        application['status'],
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Job Details
                                Text(
                                  'Job Details',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  Icons.location_on,
                                  job['location'] ?? 'Location not specified',
                                ),
                                if (job['salary'] != null)
                                  _buildInfoRow(
                                    Icons.attach_money,
                                    job['salary'],
                                  ),
                                _buildInfoRow(
                                  Icons.category,
                                  job['category'] ?? 'Category not specified',
                                ),
                                const SizedBox(height: 24),

                                // Description
                                Text(
                                  'Job Description',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  job['description'] ??
                                      'No description provided',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 24),

                                // Requirements
                                Text(
                                  'Requirements',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                if (job['requirements'] != null)
                                  if (job['requirements'] is List)
                                    ...(job['requirements'] as List).map(
                                      (req) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.circle, size: 8),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                req.toString(),
                                                style:
                                                    Theme.of(
                                                      context,
                                                    ).textTheme.bodyMedium,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  else
                                    Text(
                                      job['requirements'].toString(),
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                    )
                                else
                                  Text(
                                    'No requirements specified',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                const SizedBox(height: 24),

                                // Application Details
                                Text(
                                  'Application Details',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  Icons.calendar_today,
                                  'Applied on ${_formatDate(application['createdAt'])}',
                                ),
                                if (application['resumeId'] != null)
                                  _buildInfoRow(
                                    Icons.description,
                                    'Resume: ${application['resumeTitle'] ?? 'Not specified'}',
                                  ),
                                if (application['coverLetter'] != null)
                                  _buildInfoRow(
                                    Icons.article,
                                    'Cover Letter: ${application['coverLetter']}',
                                  ),
                                const SizedBox(height: 24),

                                // Recruiter Contact
                                if (job['recruiter'] != null) ...[
                                  Text(
                                    'Recruiter Contact',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoRow(
                                    Icons.person,
                                    'Recruiter: ${job['recruiter']['name'] ?? 'Not specified'}',
                                  ),
                                  _buildInfoRow(
                                    Icons.email,
                                    'Email: ${job['recruiter']['email'] ?? 'Not specified'}',
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading job details: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[800]),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }
}
