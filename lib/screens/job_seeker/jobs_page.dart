import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:resume_master/widgets/bottom_nav_bar.dart';
import 'package:resume_master/theme/page_transitions.dart';
import 'package:resume_master/screens/job_seeker/home.dart';
import 'package:resume_master/screens/job_seeker/profile_page.dart';
import 'package:resume_master/screens/job_seeker/resume_score.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _jobs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedType = 'All';

  final List<String> _jobTypes = [
    'All',
    'Full-time',
    'Part-time',
    'Contract',
    'Internship',
    'Freelance',
    'Temporary',
  ];

  int _currentIndex = 2;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  DocumentSnapshot? _lastDocument;
  static const int _pageSize = 10;
  String? _selectedResumeId;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredJobs = [];

  @override
  void initState() {
    super.initState();
    _loadInitialJobs();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMore &&
        _lastDocument != null) {
      _loadMoreJobs();
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filteredJobs = _getFilteredJobs();
    });
  }

  List<Map<String, dynamic>> _getFilteredJobs() {
    return _jobs.where((job) {
      final title = (job['title'] ?? '').toString().toLowerCase();
      final company =
          (job['recruiter']?['companyName'] ?? '').toString().toLowerCase();
      final location = (job['location'] ?? '').toString().toLowerCase();
      final description = (job['description'] ?? '').toString().toLowerCase();
      final requirements = (job['requirements'] ?? '').toString().toLowerCase();
      final type = (job['type'] ?? '').toString();
      final searchLower = _searchQuery.toLowerCase();

      final matchesSearch =
          searchLower.isEmpty ||
          title.contains(searchLower) ||
          company.contains(searchLower) ||
          location.contains(searchLower) ||
          description.contains(searchLower) ||
          requirements.contains(searchLower);

      final matchesType = _selectedType == 'All' || type == _selectedType;

      print(
        'Job type: $type, Selected type: $_selectedType, Matches: $matchesType',
      );

      return matchesSearch && matchesType;
    }).toList();
  }

  Future<void> _loadInitialJobs() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _jobs = [];
      _filteredJobs = [];
      _lastDocument = null;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No user logged in');
        return;
      }

      print('Fetching jobs for user: ${user.uid}');

      // Get user role
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        print('User document not found');
        return;
      }

      final userData = userDoc.data();
      if (userData == null) {
        print('User data is null');
        return;
      }

      print('User role: ${userData['role']}');

      // Get user's applications first
      final applicationsSnapshot =
          await _firestore
              .collection('applications')
              .where('applicantId', isEqualTo: user.uid)
              .get();

      // Create a set of applied job IDs
      final appliedJobIds =
          applicationsSnapshot.docs
              .map((doc) => doc.data()['jobId'] as String)
              .toSet();

      print('Applied job IDs: $appliedJobIds');

      // Get all active jobs
      final jobsSnapshot =
          await _firestore
              .collection('job_postings')
              .where('status', isEqualTo: 'active')
              .orderBy('createdAt', descending: true)
              .limit(_pageSize)
              .get();

      print('Found ${jobsSnapshot.docs.length} jobs');

      if (!mounted) return;

      final loadedJobs =
          jobsSnapshot.docs
              .where(
                (doc) => !appliedJobIds.contains(doc.id),
              ) // Filter out applied jobs
              .map((doc) {
                final data = doc.data();
                print('Job data: ${data.toString()}');

                final createdAt = data['createdAt'];
                final DateTime? createdDate =
                    createdAt is Timestamp
                        ? createdAt.toDate()
                        : createdAt is DateTime
                        ? createdAt
                        : null;

                return {
                  'id': doc.id,
                  'title': data['title']?.toString() ?? 'Untitled Job',
                  'description':
                      data['description']?.toString() ??
                      'No description available',
                  'location':
                      data['location']?.toString() ?? 'Location not specified',
                  'type': data['type']?.toString() ?? 'Full-time',
                  'salary': data['salary']?.toString(),
                  'category': data['category']?.toString() ?? 'IT',
                  'experienceLevel':
                      data['experienceLevel']?.toString() ?? 'Entry Level',
                  'requirements':
                      data['requirements']?.toString() ??
                      'No requirements specified',
                  'recruiterId': data['recruiterId']?.toString(),
                  'recruiter': {
                    'name': data['recruiter']?['name']?.toString() ?? '',
                    'companyName':
                        data['company']?.toString() ?? 'Company Name',
                    'email': data['recruiter']?['email']?.toString() ?? '',
                  },
                  'createdAt': createdDate,
                  'status': data['status']?.toString() ?? 'active',
                };
              })
              .toList();

      print('Loaded ${loadedJobs.length} jobs after filtering applied jobs');

      setState(() {
        _jobs = loadedJobs;
        _filteredJobs = _getFilteredJobs();
        _lastDocument =
            jobsSnapshot.docs.isNotEmpty ? jobsSnapshot.docs.last : null;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading jobs: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreJobs() async {
    if (_isLoadingMore || _lastDocument == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get user's applications
      final applicationsSnapshot =
          await _firestore
              .collection('applications')
              .where('applicantId', isEqualTo: user.uid)
              .get();

      final appliedJobIds =
          applicationsSnapshot.docs
              .map((doc) => doc.data()['jobId'] as String)
              .toSet();

      final snapshot =
          await _firestore
              .collection('job_postings')
              .where('status', isEqualTo: 'active')
              .orderBy('createdAt', descending: true)
              .startAfterDocument(_lastDocument!)
              .limit(_pageSize)
              .get();

      if (!mounted) return;

      if (snapshot.docs.isNotEmpty) {
        final newJobs =
            snapshot.docs.where((doc) => !appliedJobIds.contains(doc.id)).map((
              doc,
            ) {
              final data = doc.data();
              final createdAt = data['createdAt'];
              final DateTime? createdDate =
                  createdAt is Timestamp
                      ? createdAt.toDate()
                      : createdAt is DateTime
                      ? createdAt
                      : null;

              return {
                'id': doc.id,
                'title': data['title']?.toString() ?? 'Untitled Job',
                'description':
                    data['description']?.toString() ??
                    'No description available',
                'location':
                    data['location']?.toString() ?? 'Location not specified',
                'type': data['type']?.toString() ?? 'Full-time',
                'salary': data['salary']?.toString(),
                'category': data['category']?.toString() ?? 'IT',
                'experienceLevel':
                    data['experienceLevel']?.toString() ?? 'Entry Level',
                'requirements':
                    data['requirements']?.toString() ??
                    'No requirements specified',
                'recruiterId': data['recruiterId']?.toString(),
                'recruiter': {
                  'name': data['recruiter']?['name']?.toString() ?? '',
                  'companyName': data['company']?.toString() ?? 'Company Name',
                  'email': data['recruiter']?['email']?.toString() ?? '',
                },
                'createdAt': createdDate,
                'status': data['status']?.toString() ?? 'active',
              };
            }).toList();

        setState(() {
          _jobs.addAll(newJobs);
          _filteredJobs = _getFilteredJobs();
          _lastDocument = snapshot.docs.last;
        });
      }
    } catch (e) {
      print('Error loading more jobs: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _refreshJobs() async {
    await _loadInitialJobs();
  }

  Future<List<Map<String, dynamic>>> _getUserResumes() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    final snapshot =
        await _firestore
            .collection('resumes')
            .where('userId', isEqualTo: user.uid)
            .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  void _showJobDetails(Map<String, dynamic> job) {
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
                                    job['title'] ?? 'Untitled Job',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    job['recruiter']?['companyName'] ??
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
                                job['description'] ?? 'No description provided',
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
                                      padding: const EdgeInsets.only(bottom: 8),
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
                                        Theme.of(context).textTheme.bodyMedium,
                                  )
                              else
                                Text(
                                  'No requirements specified',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              const SizedBox(height: 32),

                              // Apply Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showApplyDialog(job);
                                  },
                                  icon: const Icon(Icons.send),
                                  label: const Text('Apply Now'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
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
    );
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

  String _getTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'Unknown time';

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return 'Invalid date';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
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

  Future<void> _submitApplication(
    Map<String, dynamic> job,
    Map<String, dynamic> resume,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final application = {
        'jobId': job['id'],
        'jobTitle': job['title'],
        'companyName': job['recruiter']?['companyName'] ?? 'Company Name',
        'resumeId': resume['id'],
        'resumeTitle': resume['title'],
        'applicantId': user.uid,
        'applicantName': user.displayName ?? 'Anonymous',
        'applicantEmail': user.email,
        'recruiterId': job['recruiterId'],
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('applications')
          .add(application);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting application: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showApplyDialog(Map<String, dynamic> job) {
    showDialog(
      context: context,
      builder:
          (context) => FutureBuilder<List<Map<String, dynamic>>>(
            future: _getUserResumes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return AlertDialog(
                  title: const Text('Error'),
                  content: Text('Error loading resumes: ${snapshot.error}'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                );
              }

              final resumes = snapshot.data ?? [];
              if (resumes.isEmpty) {
                return AlertDialog(
                  title: const Text('No Resumes'),
                  content: const Text(
                    'Please create a resume before applying for jobs.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                );
              }

              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    title: const Text('Select Resume'),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Choose a resume to submit with your application:',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ...resumes.map((resume) {
                            final isSelected =
                                resume['id'] == _selectedResumeId;
                            final updatedAt = resume['updatedAt'];
                            String timeAgo = 'Unknown time';

                            if (updatedAt != null) {
                              if (updatedAt is Timestamp) {
                                timeAgo = _getTimeAgo(updatedAt.toDate());
                              } else if (updatedAt is DateTime) {
                                timeAgo = _getTimeAgo(updatedAt);
                              }
                            }

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              color:
                                  isSelected
                                      ? Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.1)
                                      : null,
                              child: ListTile(
                                title: Text(
                                  resume['title'] ?? 'Untitled Resume',
                                  style: TextStyle(
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  'Last updated: $timeAgo',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                trailing:
                                    isSelected
                                        ? Icon(
                                          Icons.check_circle,
                                          color: Theme.of(context).primaryColor,
                                        )
                                        : null,
                                onTap: () {
                                  setState(() {
                                    _selectedResumeId = resume['id'];
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed:
                              _selectedResumeId == null
                                  ? null
                                  : () async {
                                    try {
                                      final selectedResume = resumes.firstWhere(
                                        (r) => r['id'] == _selectedResumeId,
                                      );
                                      await _submitApplication(
                                        job,
                                        selectedResume,
                                      );
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(e.toString()),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Text('Submit Application'),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
    );
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
        // Already on jobs page
        break;
      case 3: // Profile
        Navigator.pushReplacement(
          context,
          slidePageRouteBuilder(const ProfilePage()),
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
            'Jobs',
            style: TextStyle(
              fontFamily: 'CrimsonText',
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 35,
            ),
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadInitialJobs,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search jobs...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _filteredJobs = _getFilteredJobs();
                    });
                  },
                ),
              ),
              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredJobs.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.work_outline,
                                size: 64,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.4),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No Jobs Found',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your filters or search',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        )
                        : RefreshIndicator(
                          onRefresh: _refreshJobs,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount:
                                _filteredJobs.length + (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _filteredJobs.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              final job = _filteredJobs[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  onTap: () => _showJobDetails(job),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    job['title'] ??
                                                        'Untitled Job',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleLarge
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    job['recruiter']?['companyName'] ??
                                                        'Company Name',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(
                                                  context,
                                                ).primaryColor.withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                job['type'] ?? 'Full-time',
                                                style: TextStyle(
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).primaryColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on_outlined,
                                              size: 16,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              job['location'] ??
                                                  'Location not specified',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Icon(
                                              Icons.work_outline,
                                              size: 16,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              job['experienceLevel'] ??
                                                  'Entry Level',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (job['salary'] != null) ...[
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.attach_money,
                                                size: 16,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                job['salary']!,
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            TextButton(
                                              onPressed:
                                                  () => _showJobDetails(job),
                                              child: const Text('View Details'),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton(
                                              onPressed:
                                                  () => _showApplyDialog(job),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Theme.of(
                                                      context,
                                                    ).primaryColorDark,
                                                foregroundColor: Colors.white,
                                              ),
                                              child: const Text('Apply Now'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
        ),
      ),
    );
  }

  void _showFilterDialog() {
    // Calculate job counts for each type
    final jobCounts = <String, int>{};
    for (final job in _jobs) {
      final type = (job['type'] ?? '').toString();
      jobCounts[type] = (jobCounts[type] ?? 0) + 1;
    }

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Jobs',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'CrimsonText',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Job Type',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                _jobTypes.map((type) {
                                  final isSelected = _selectedType == type;
                                  final count = jobCounts[type] ?? 0;
                                  return FilterChip(
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(type),
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                isSelected
                                                    ? Theme.of(
                                                      context,
                                                    ).primaryColor
                                                    : Colors.grey[300],
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            count.toString(),
                                            style: TextStyle(
                                              color:
                                                  isSelected
                                                      ? Colors.white
                                                      : Colors.black87,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedType = selected ? type : 'All';
                                        _filteredJobs = _getFilteredJobs();
                                      });
                                      Navigator.pop(context);
                                    },
                                    backgroundColor: Colors.grey[200],
                                    selectedColor: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.2),
                                    checkmarkColor:
                                        Theme.of(context).primaryColor,
                                    labelStyle: TextStyle(
                                      color:
                                          isSelected
                                              ? Theme.of(context).primaryColor
                                              : Colors.black87,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _selectedType = 'All';
                                _filteredJobs = _getFilteredJobs();
                              });
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            child: Text(
                              'Reset',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontFamily: 'CrimsonText',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _filteredJobs = _getFilteredJobs();
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Apply',
                              style: TextStyle(fontFamily: 'CrimsonText'),
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
    );
  }
}
