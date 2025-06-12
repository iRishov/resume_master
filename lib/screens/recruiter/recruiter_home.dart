import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:resume_master/screens/recruiter/job_posting_page.dart';
import 'package:resume_master/screens/recruiter/job_applications_page.dart';
import 'package:resume_master/screens/recruiter/recruiter_profile.dart';
import 'package:resume_master/theme/page_transitions.dart';
import 'package:resume_master/theme/app_theme.dart';

class RecruiterHomePage extends StatefulWidget {
  const RecruiterHomePage({super.key});

  @override
  State<RecruiterHomePage> createState() => _RecruiterHomePageState();
}

class _RecruiterHomePageState extends State<RecruiterHomePage>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _activeJobs = 0;
  int _totalApplications = 0;
  String? _recruiterName;
  String? _organization;
  String? _position;
  bool _isLoading = true;

  // Animation controllers
  late AnimationController _headerAnimationController;
  late AnimationController _statsAnimationController;
  late AnimationController _actionsAnimationController;
  late AnimationController _jobsAnimationController;

  // Animations
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _statsFadeAnimation;
  late Animation<double> _actionsFadeAnimation;
  late Animation<double> _jobsFadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
    _loadStats();
  }

  void _initializeAnimations() {
    // Header animation
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _headerFadeAnimation = CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeIn,
    );

    // Stats animation
    _statsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _statsFadeAnimation = CurvedAnimation(
      parent: _statsAnimationController,
      curve: Curves.easeIn,
    );

    // Actions animation
    _actionsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _actionsFadeAnimation = CurvedAnimation(
      parent: _actionsAnimationController,
      curve: Curves.easeIn,
    );

    // Jobs animation
    _jobsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _jobsFadeAnimation = CurvedAnimation(
      parent: _jobsAnimationController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _statsAnimationController.dispose();
    _actionsAnimationController.dispose();
    _jobsAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          setState(() {
            _recruiterName = doc.data()?['name'] ?? 'Recruiter';
            _organization = doc.data()?['company'] ?? 'Organization';
            _position = doc.data()?['position'] ?? 'Position';
            _isLoading = false;
          });
          if (mounted) {
            _startAnimations();
          }
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startAnimations() {
    if (!mounted) return;

    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      _statsAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _actionsAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _jobsAnimationController.forward();
    });
  }

  Widget _buildAnimatedHeader() {
    return FadeTransition(
      opacity: _headerFadeAnimation,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _recruiterName ?? 'Recruiter',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${_position ?? ''} at ${_organization ?? ''}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeTransition(opacity: _statsFadeAnimation, child: _buildStatsCard()),
        const SizedBox(height: 24),
        FadeTransition(
          opacity: _actionsFadeAnimation,
          child: _buildActionButtons(),
        ),
        const SizedBox(height: 24),
        FadeTransition(opacity: _jobsFadeAnimation, child: _buildRecentJobs()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _refreshData,
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      automaticallyImplyLeading: false,
                      expandedHeight: 140,
                      pinned: true,
                      floating: false,
                      backgroundColor: Theme.of(context).primaryColor,
                      flexibleSpace: FlexibleSpaceBar(
                        titlePadding: const EdgeInsets.only(
                          left: 16,
                          bottom: 16,
                        ),
                        title:
                            _isLoading
                                ? const SizedBox.shrink()
                                : _buildAnimatedHeader(),
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).primaryColorDark,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(
                            Icons.refresh,
                            size: 28,
                            color: Colors.white,
                          ),
                          tooltip: 'Refresh',
                          onPressed: _refreshData,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.person_outline,
                            size: 28,
                            color: Colors.white,
                          ),
                          tooltip: 'View Profile',
                          onPressed: () {
                            Navigator.push(
                              context,
                              slidePageRouteBuilder(const RecruiterProfile()),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildAnimatedContent(),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get job stats
      final jobsSnapshot =
          await _firestore
              .collection('job_postings')
              .where('recruiterId', isEqualTo: user.uid)
              .get();

      int activeCount = 0;
      int totalApplications = 0;

      // Get total applications for each job
      for (var job in jobsSnapshot.docs) {
        final data = job.data();
        if (data['status'] == 'active') {
          activeCount++;
        }

        // Get applications count for this job
        final applicationsSnapshot =
            await _firestore
                .collection('applications')
                .where('jobId', isEqualTo: job.id)
                .get();

        totalApplications += applicationsSnapshot.docs.length;
      }

      setState(() {
        _activeJobs = activeCount;
        _totalApplications = totalApplications;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading stats: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleJobStatus(String jobId, String currentStatus) async {
    try {
      final newStatus = currentStatus == 'active' ? 'closed' : 'active';
      await _firestore.collection('job_postings').doc(jobId).update({
        'status': newStatus,
      });
      _loadStats();
    } catch (e) {
      debugPrint('Error toggling job status: $e');
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([_loadUserData(), _loadStats()]);
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              ' Overview',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Active Jobs',
                    _activeJobs.toString(),
                    Icons.work_outline,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Total Applications',
                    _totalApplications.toString(),
                    Icons.people_outline,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
          colors: [
            Theme.of(context).primaryColorDark.withOpacity(0.9),
            Theme.of(context).colorScheme.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 28),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          alignment: Alignment.center,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildActionButton('Post New Job', Icons.add_circle_outline, () {
          Navigator.push(
            context,
            slidePageRouteBuilder(const JobPostingPage()),
          );
        }),
        const SizedBox(height: 16),
        _buildActionButton('View Applications', Icons.people_outline, () {
          Navigator.push(
            context,
            slidePageRouteBuilder(
              JobApplicationsPage(jobId: '', jobTitle: 'All Applications'),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRecentJobs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Job Postings',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream:
              _firestore
                  .collection('job_postings')
                  .where('recruiterId', isEqualTo: _auth.currentUser?.uid)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              debugPrint('Error fetching jobs: ${snapshot.error}');
              return Card(
                elevation: 0,
                color: Colors.grey[50],
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error Loading Jobs',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please try again later',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {});
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final jobs = snapshot.data!.docs;

            // Sort jobs by createdAt timestamp
            jobs.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTime =
                  (aData['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.now();
              final bTime =
                  (bData['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.now();
              return bTime.compareTo(aTime); // Descending order
            });

            // Take only the first 5 jobs
            final recentJobs = jobs.take(5).toList();

            if (recentJobs.isEmpty) {
              return Card(
                elevation: 0,
                color: Colors.grey[50],
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.work_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Jobs Created Yet',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start posting jobs to find the perfect candidates for your company',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            slidePageRouteBuilder(const JobPostingPage()),
                          ).then((_) => _loadStats());
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text(
                          'Create Your First Job',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children:
                  recentJobs.map((job) {
                    final data = job.data() as Map<String, dynamic>;
                    final status = data['status'] as String? ?? 'active';
                    final isActive = status == 'active';
                    final createdAt =
                        (data['createdAt'] as Timestamp?)?.toDate() ??
                        DateTime.now();

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[200]!, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title and Actions
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    data['title'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      slidePageRouteBuilder(
                                        JobPostingPage(jobId: job.id),
                                      ),
                                    ).then((_) => _loadStats());
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    isActive ? Icons.close : Icons.refresh,
                                    color: isActive ? Colors.red : Colors.green,
                                  ),
                                  onPressed:
                                      () => _toggleJobStatus(job.id, status),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // 4 Column Layout
                            Row(
                              children: [
                                // Company Column
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.business,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              'Company',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        data['company'] ?? '',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Location Column
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              'Location',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        data['location'] ?? '',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Type Column
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.work_outline,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              'Type',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        data['type'] ?? '',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Status Column
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.circle,
                                            size: 16,
                                            color:
                                                isActive
                                                    ? Colors.green
                                                    : Colors.orange,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              'Status',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              isActive
                                                  ? Colors.green[50]
                                                  : Colors.orange[50],
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color:
                                                isActive
                                                    ? Colors.green[200]!
                                                    : Colors.orange[200]!,
                                          ),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            color:
                                                isActive
                                                    ? Colors.green[700]
                                                    : Colors.orange[700],
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Posted ${_getTimeAgo(createdAt)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            );
          },
        ),
      ],
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
