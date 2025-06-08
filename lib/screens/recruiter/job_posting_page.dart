import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resume_master/services/auth_service.dart';

class JobPostingPage extends StatefulWidget {
  final String? jobId; // For editing existing jobs

  const JobPostingPage({super.key, this.jobId});

  @override
  State<JobPostingPage> createState() => _JobPostingPageState();
}

class _JobPostingPageState extends State<JobPostingPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _companyController = TextEditingController();
  String _status = 'active';
  bool _isLoading = false;
  String? _error;
  bool _isEditing = false;
  String _selectedType = 'Full-time';
  String _selectedCategory = 'IT';
  String _selectedExperience = 'Entry Level';

  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _jobCategories = [
    'IT',
    'Design',
    'Marketing',
    'Sales',
    'Finance',
    'Healthcare',
    'Education',
    'Engineering',
    'Customer Service',
    'Human Resources',
    'Legal',
    'Manufacturing',
    'Retail',
    'Other',
  ];

  final List<String> _jobTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Internship',
    'Freelance',
    'Temporary',
  ];

  final List<String> _experienceLevels = [
    'Entry Level',
    'Junior',
    'Mid Level',
    'Senior',
    'Lead',
    'Manager',
    'Director',
    'Executive',
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.jobId != null;
    if (_isEditing) {
      _loadJobData();
    }
  }

  Future<void> _loadJobData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final jobDoc =
          await _firestore.collection('job_postings').doc(widget.jobId).get();
      if (!jobDoc.exists) throw Exception('Job not found');

      final jobData = jobDoc.data()!;
      _titleController.text = jobData['title'] ?? '';
      _locationController.text = jobData['location'] ?? '';
      _descriptionController.text = jobData['description'] ?? '';
      _requirementsController.text = jobData['requirements'] ?? '';
      _salaryController.text = jobData['salary'] ?? '';
      _companyController.text = jobData['company'] ?? '';
      _selectedType = jobData['type'] ?? 'Full-time';
      _selectedCategory = jobData['category'] ?? 'IT';
      _selectedExperience = jobData['experienceLevel'] ?? 'Entry Level';
      _status = jobData['status'] ?? 'active';

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _salaryController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user data for recruiter info
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      if (userData == null) throw Exception('User data not found');

      final jobData = {
        'title': _titleController.text,
        'company': _companyController.text,
        'location': _locationController.text,
        'description': _descriptionController.text,
        'requirements': _requirementsController.text,
        'salary': _salaryController.text,
        'type': _selectedType,
        'category': _selectedCategory,
        'experienceLevel': _selectedExperience,
        'recruiterId': user.uid,
        'recruiter': {
          'name': userData['name']?.toString() ?? '',
          'email': userData['email']?.toString() ?? '',
        },
        'status': _status,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'applicationCount': 0,
        'lastApplicationAt': null,
      };

      if (_isEditing) {
        // Update existing job
        await _firestore
            .collection('job_postings')
            .doc(widget.jobId)
            .update(jobData);

        // Update company name in all related applications
        final applicationsSnapshot =
            await _firestore
                .collection('applications')
                .where('jobId', isEqualTo: widget.jobId)
                .get();

        final batch = _firestore.batch();
        for (var doc in applicationsSnapshot.docs) {
          batch.update(doc.reference, {
            'companyName': _companyController.text,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      } else {
        // Create new job
        await _firestore.collection('job_postings').add(jobData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Job updated successfully!'
                  : 'Job posted successfully!',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Job' : 'Post a Job')),
      body:
          _isLoading && _isEditing
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_error != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Job Title',
                          prefixIcon: const Icon(Icons.work_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a job title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _companyController,
                        decoration: InputDecoration(
                          labelText: 'Company Name',
                          prefixIcon: const Icon(Icons.business),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter company name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Location',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter job location';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Job Category',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items:
                            _jobCategories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a job category';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          labelText: 'Job Type',
                          prefixIcon: const Icon(Icons.work_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items:
                            _jobTypes.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select job type';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedExperience,
                        decoration: InputDecoration(
                          labelText: 'Experience Level',
                          prefixIcon: const Icon(Icons.trending_up),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items:
                            _experienceLevels.map((level) {
                              return DropdownMenuItem(
                                value: level,
                                child: Text(level),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedExperience = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select experience level';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _salaryController,
                        decoration: InputDecoration(
                          labelText: 'Salary Range',
                          prefixIcon: const Icon(Icons.attach_money),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter salary range';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'Job Description',
                          prefixIcon: const Icon(Icons.description_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter job description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _requirementsController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'Requirements',
                          prefixIcon: const Icon(Icons.checklist_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter job requirements';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'Job Status',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'active',
                            child: Text('Active'),
                          ),
                          DropdownMenuItem(
                            value: 'closed',
                            child: Text('Closed'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _status = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _submitJob,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon:
                              _isLoading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Icon(Icons.save),
                          label: Text(
                            _isLoading ? 'Saving...' : 'Save Job',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
