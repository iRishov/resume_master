import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:resume_master/screens/user/resume_preview.dart';
import 'package:resume_master/models/resume.dart';

class JobApplicationsPage extends StatefulWidget {
  final String jobId;
  final String jobTitle;

  const JobApplicationsPage({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  State<JobApplicationsPage> createState() => _JobApplicationsPageState();
}

class _JobApplicationsPageState extends State<JobApplicationsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _applications = [];
  String _selectedStatus = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      debugPrint('Loading applications for recruiter: ${user.uid}');
      debugPrint('Job ID: ${widget.jobId}');

      Query query;

      if (widget.jobId.isEmpty) {
        // If no specific job is selected, get all applications for the recruiter's jobs
        query = _firestore
            .collection('applications')
            .where('recruiterId', isEqualTo: user.uid);

        debugPrint('Querying all applications for recruiter');
      } else {
        // If a specific job is selected, query only its applications
        query = _firestore
            .collection('applications')
            .where('jobId', isEqualTo: widget.jobId);

        debugPrint('Querying applications for specific job: ${widget.jobId}');
      }

      if (_selectedStatus != 'all') {
        query = query.where('status', isEqualTo: _selectedStatus);
        debugPrint('Filtering by status: $_selectedStatus');
      }

      final snapshot = await query.get();
      debugPrint('Found ${snapshot.docs.length} applications');

      if (!mounted) return;

      setState(() {
        _applications =
            snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              debugPrint('Application data: ${data.toString()}');
              return {
                'id': doc.id,
                'applicantEmail': data['applicantEmail'] ?? '',
                'applicantId': data['applicantId'] ?? '',
                'applicantName': data['applicantName'] ?? '',
                'companyName': data['companyName'] ?? '',
                'createdAt': data['createdAt'],
                'jobId': data['jobId'] ?? '',
                'jobTitle': data['jobTitle'] ?? '',
                'resumeId': data['resumeId'] ?? '',
                'resumeTitle': data['resumeTitle'] ?? '',
                'status': data['status'] ?? 'pending',
                'updatedAt': data['updatedAt'],
              };
            }).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading applications: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading applications: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateApplicationStatus(
    String applicationId,
    String newStatus,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(applicationId)
          .update({
            'status': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Show success message based on status
      String message;
      switch (newStatus) {
        case 'accepted':
          message = 'Application accepted successfully';
          break;
        case 'rejected':
          message = 'Application rejected';
          break;
        case 'pending':
          message = 'Application status set to pending';
          break;
        default:
          message = 'Application status updated';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  newStatus == 'accepted'
                      ? Icons.check_circle
                      : newStatus == 'rejected'
                      ? Icons.cancel
                      : Icons.pending,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(message),
              ],
            ),
            backgroundColor:
                newStatus == 'accepted'
                    ? Colors.green
                    : newStatus == 'rejected'
                    ? Colors.red
                    : Colors.orange,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(8),
          ),
        );
      }

      // Reload applications after status update
      _loadApplications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(8),
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredApplications() {
    return _applications.where((application) {
      final name =
          (application['applicantName'] ?? '').toString().toLowerCase();
      final email =
          (application['applicantEmail'] ?? '').toString().toLowerCase();
      final jobTitle = (application['jobTitle'] ?? '').toString().toLowerCase();
      final searchLower = _searchQuery.toLowerCase();

      return searchLower.isEmpty ||
          name.contains(searchLower) ||
          email.contains(searchLower) ||
          jobTitle.contains(searchLower);
    }).toList();
  }

  void _showApplicationDetails(Map<String, dynamic> application) {
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
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    application['applicantName'] ??
                                        'Unknown Applicant',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    application['jobTitle'] ??
                                        'Unknown Position',
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
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(20),
                          children: [
                            _buildStatusSection(application),
                            const SizedBox(height: 24),
                            _buildApplicantInfoSection(application),
                            const SizedBox(height: 24),
                            _buildResumeSection(application),
                            const SizedBox(height: 24),
                            _buildActionButtons(application),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildStatusSection(Map<String, dynamic> application) {
    final status = application['status'] ?? 'pending';
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status.toLowerCase()) {
      case 'accepted':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Accepted';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor),
          const SizedBox(width: 8),
          Text(
            'Status: $statusText',
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicantInfoSection(Map<String, dynamic> application) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Applicant Information',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildInfoCard([
          _buildInfoRow(
            Icons.person,
            'Name',
            application['applicantName'] ?? 'Unknown',
          ),
          _buildInfoRow(
            Icons.email,
            'Email',
            application['applicantEmail'] ?? 'No email provided',
          ),
          _buildInfoRow(
            Icons.work,
            'Position',
            application['jobTitle'] ?? 'Unknown position',
          ),
          _buildInfoRow(
            Icons.business,
            'Company',
            application['companyName'] ?? 'Unknown company',
          ),
        ]),
      ],
    );
  }

  Widget _buildResumeSection(Map<String, dynamic> application) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resume',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildInfoCard([
          InkWell(
            onTap: () async {
              try {
                // Get the resume data from Firestore
                final resumeDoc =
                    await _firestore
                        .collection('resumes')
                        .doc(application['resumeId'])
                        .get();

                if (!resumeDoc.exists) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Resume not found'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }

                final resumeData = resumeDoc.data()!;
                final resume = Resume.fromMap(resumeData, id: resumeDoc.id);

                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResumePreview(resume: resume),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error loading resume: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: _buildInfoRow(
              Icons.description,
              'Resume Title',
              application['resumeTitle'] ?? 'Untitled Resume',
              isClickable: true,
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isClickable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: isClickable ? Theme.of(context).primaryColor : null,
                    decoration: isClickable ? TextDecoration.underline : null,
                  ),
                ),
              ],
            ),
          ),
          if (isClickable)
            Icon(Icons.chevron_right, size: 16, color: Colors.grey[600]),
        ],
      ),
    );
  }

  Future<void> _showConfirmationDialog(
    BuildContext context,
    String status,
    String applicationId,
  ) async {
    String message;
    String title;
    switch (status) {
      case 'accepted':
        title = 'Accept Application';
        message = 'Are you sure you want to accept this application?';
        break;
      case 'rejected':
        title = 'Reject Application';
        message = 'Are you sure you want to reject this application?';
        break;
      case 'pending':
        title = 'Set to Pending';
        message = 'Are you sure you want to set this application to pending?';
        break;
      default:
        title = 'Update Status';
        message = 'Are you sure you want to update the application status?';
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    status == 'accepted'
                        ? Colors.green
                        : status == 'rejected'
                        ? Colors.red
                        : Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      _updateApplicationStatus(applicationId, status);
    }
  }

  Widget _buildActionButtons(Map<String, dynamic> application) {
    final status = application['status'] ?? 'pending';
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed:
                status == 'accepted'
                    ? null
                    : () => _showConfirmationDialog(
                      context,
                      'accepted',
                      application['id'],
                    ),
            icon: const Icon(Icons.check),
            label: const Text('Accept'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed:
                status == 'rejected'
                    ? null
                    : () => _showConfirmationDialog(
                      context,
                      'rejected',
                      application['id'],
                    ),
            icon: const Icon(Icons.close),
            label: const Text('Reject'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed:
                status == 'pending'
                    ? null
                    : () => _showConfirmationDialog(
                      context,
                      'pending',
                      application['id'],
                    ),
            icon: const Icon(Icons.pending),
            label: const Text('Pending'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _selectedStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Theme.of(context).primaryColor.withOpacity(0.2)
                        : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color:
                      isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedStatus = value);
          _loadApplications();
        },
        backgroundColor: Colors.grey[100],
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        checkmarkColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Map<String, int> _getStatusCounts() {
    final counts = {
      'all': _applications.length,
      'pending': 0,
      'accepted': 0,
      'rejected': 0,
    };

    for (var application in _applications) {
      final status =
          (application['status'] as String?)?.toLowerCase() ?? 'pending';
      if (counts.containsKey(status)) {
        counts[status] = (counts[status] ?? 0) + 1;
      }
    }

    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final filteredApplications = _getFilteredApplications();
    final statusCounts = _getStatusCounts();

    return Scaffold(
      appBar: AppBar(
        title: Text('Applications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApplications,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search applications...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all', statusCounts['all'] ?? 0),
                      _buildFilterChip(
                        'Pending',
                        'pending',
                        statusCounts['pending'] ?? 0,
                      ),
                      _buildFilterChip(
                        'Accepted',
                        'accepted',
                        statusCounts['accepted'] ?? 0,
                      ),
                      _buildFilterChip(
                        'Rejected',
                        'rejected',
                        statusCounts['rejected'] ?? 0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredApplications.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.work_outline,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No applications found',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Try adjusting your search'
                                : 'Applications will appear here when candidates apply',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredApplications.length,
                      itemBuilder: (context, index) {
                        final application = filteredApplications[index];
                        final status = application['status'] ?? 'pending';
                        Color statusColor;
                        IconData statusIcon;

                        switch (status.toLowerCase()) {
                          case 'accepted':
                            statusColor = Colors.green;
                            statusIcon = Icons.check_circle;
                            break;
                          case 'rejected':
                            statusColor = Colors.red;
                            statusIcon = Icons.cancel;
                            break;
                          case 'interview':
                            statusColor = Colors.blue;
                            statusIcon = Icons.event;
                            break;
                          default:
                            statusColor = Colors.orange;
                            statusIcon = Icons.pending;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          child: InkWell(
                            onTap: () => _showApplicationDetails(application),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: statusColor
                                            .withOpacity(0.1),
                                        child: Icon(
                                          statusIcon,
                                          color: statusColor,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              application['applicantName'] ??
                                                  'Unknown Applicant',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              application['jobTitle'] ??
                                                  'Unknown Position',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              status.toUpperCase(),
                                              style: TextStyle(
                                                color: statusColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat('MMM d, y').format(
                                              (application['createdAt']
                                                          as Timestamp?)
                                                      ?.toDate() ??
                                                  DateTime.now(),
                                            ),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
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
        ],
      ),
    );
  }
}
