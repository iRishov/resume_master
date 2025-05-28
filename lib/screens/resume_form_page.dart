import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resume_master/screens/home.dart';
import 'package:app_settings/app_settings.dart';
import 'package:resume_master/widgets/form_fields.dart';

class ResumeForm extends StatefulWidget {
  final Map<String, dynamic>? resumeData;

  const ResumeForm({super.key, this.resumeData});

  @override
  State<ResumeForm> createState() => _ResumeFormState();
}

class _ResumeFormState extends State<ResumeForm>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final PageController _pageController = PageController();
  bool _isLoading = false;
  late AnimationController _pageAnimationController;
  int _currentStep = 0;
  final int _totalSteps = 6;

  // Form state variables
  final Set<String> _selectedSkills = {};
  final Set<String> _selectedLanguages = {};
  String? _selectedGender;

  // Dynamic list state variables
  final List<Map<String, String>> _experiences = [];
  final List<Map<String, String>> _education = [];
  final List<Map<String, String>> _projects = [];
  final List<Map<String, String>> _certifications = [];

  // Form controllers
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _objectiveController;
  late TextEditingController _hobbiesController;
  late TextEditingController _summaryController;
  late TextEditingController _dobController;
  late TextEditingController _nationalityController;
  late TextEditingController _linkedinController;
  late TextEditingController _skillSearchController;

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Predefined skills and languages lists

  // Experience controllers
  final List<Map<String, TextEditingController>> _experienceControllers = [];

  // Skill search state
  String _skillSearchQuery = '';
  String _selectedSkillCategory = 'All';

  // Cache for filtered skills
  List<String>? _cachedFilteredSkills;
  String? _lastSearchQuery;
  String? _lastSelectedCategory;

  // Add this map for skill categories
  final Map<String, List<String>> _skillCategories = {
    'All': [],
    'Programming Languages': [
      'Python',
      'Java',
      'JavaScript',
      'C++',
      'C#',
      'PHP',
      'Swift',
      'Kotlin',
      'TypeScript',
      'Ruby',
      'Go',
      'Rust',
      'Scala',
      'R',
      'MATLAB',
      'Perl',
      'Shell Scripting',
      'Assembly',
    ],
    'Web Development': [
      'HTML5',
      'CSS3',
      'React',
      'Angular',
      'Vue.js',
      'Node.js',
      'Express.js',
      'Next.js',
      'Django',
      'Flask',
      'Laravel',
      'Spring Boot',
      'jQuery',
      'Bootstrap',
      'Tailwind CSS',
      'SASS/SCSS',
      'Redux',
      'GraphQL',
      'REST APIs',
      'WebSocket',
      'Webpack',
      'Babel',
    ],
    'Mobile Development': [
      'Flutter',
      'React Native',
      'Android',
      'iOS',
      'Xamarin',
      'Ionic',
      'Swift',
      'Kotlin',
      'Objective-C',
      'Mobile UI/UX',
      'App Store',
      'Google Play',
      'Firebase Mobile',
      'Mobile Testing',
    ],
    'Database & Cloud': [
      'SQL',
      'MongoDB',
      'PostgreSQL',
      'MySQL',
      'AWS',
      'Azure',
      'Google Cloud',
      'Docker',
      'Kubernetes',
      'Firebase',
      'Redis',
      'Cassandra',
      'Oracle',
      'SQLite',
      'MariaDB',
      'Elasticsearch',
      'DynamoDB',
      'Cloud Functions',
      'Serverless',
      'CI/CD',
    ],
    'Data Science & AI': [
      'Machine Learning',
      'Deep Learning',
      'Data Science',
      'TensorFlow',
      'PyTorch',
      'Scikit-learn',
      'Pandas',
      'NumPy',
      'R',
      'Data Analysis',
      'Data Visualization',
      'Natural Language Processing',
      'Computer Vision',
      'Big Data',
      'Hadoop',
      'Spark',
      'Tableau',
      'Power BI',
      'Statistical Analysis',
      'Predictive Modeling',
    ],
    'DevOps & Tools': [
      'Git',
      'CI/CD',
      'Jenkins',
      'Ansible',
      'Terraform',
      'Linux',
      'Shell Scripting',
      'JIRA',
      'Confluence',
      'GitHub',
      'GitLab',
      'Bitbucket',
      'Docker',
      'Kubernetes',
      'AWS',
      'Azure',
      'Google Cloud',
      'Monitoring',
      'Logging',
      'Security',
      'Networking',
    ],
    'Design & UI/UX': [
      'Figma',
      'Adobe XD',
      'Photoshop',
      'Illustrator',
      'UI Design',
      'UX Design',
      'Wireframing',
      'Prototyping',
      'InDesign',
      'Sketch',
      'User Research',
      'User Testing',
      'Accessibility',
      'Responsive Design',
      'Design Systems',
      'Typography',
      'Color Theory',
      'Motion Design',
      '3D Design',
      'Brand Design',
    ],
    'Soft Skills': [
      'Communication',
      'Leadership',
      'Problem Solving',
      'Teamwork',
      'Time Management',
      'Project Management',
      'Agile',
      'Scrum',
      'Critical Thinking',
      'Adaptability',
      'Creativity',
      'Emotional Intelligence',
      'Conflict Resolution',
      'Negotiation',
      'Public Speaking',
      'Mentoring',
      'Strategic Planning',
      'Decision Making',
      'Customer Service',
      'Cross-functional Collaboration',
    ],
    'Business & Management': [
      'Project Management',
      'Business Analysis',
      'Strategic Planning',
      'Risk Management',
      'Budgeting',
      'Financial Analysis',
      'Marketing',
      'Sales',
      'Customer Relationship Management',
      'Supply Chain Management',
      'Operations Management',
      'Quality Assurance',
      'Process Improvement',
      'Business Development',
      'Market Research',
      'Product Management',
      'Team Leadership',
      'Stakeholder Management',
      'Change Management',
      'Performance Management',
    ],
    'Security & Compliance': [
      'Cybersecurity',
      'Network Security',
      'Information Security',
      'Penetration Testing',
      'Security Auditing',
      'Compliance',
      'GDPR',
      'HIPAA',
      'PCI DSS',
      'Risk Assessment',
      'Security Architecture',
      'Cryptography',
      'Firewall Management',
      'Security Monitoring',
      'Incident Response',
      'Vulnerability Assessment',
      'Security Policies',
      'Identity Management',
      'Access Control',
      'Security Training',
    ],
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadResumeData();
    _pageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _initializeControllers() {
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _dobController = TextEditingController();
    _nationalityController = TextEditingController();
    _linkedinController = TextEditingController();
    _objectiveController = TextEditingController();
    _summaryController = TextEditingController();
    _hobbiesController = TextEditingController();
    _skillSearchController = TextEditingController();
  }

  // Optimized method to get filtered skills
  List<String> _getFilteredSkills() {
    // Return cached result if search query and category haven't changed
    if (_cachedFilteredSkills != null &&
        _lastSearchQuery == _skillSearchQuery &&
        _lastSelectedCategory == _selectedSkillCategory) {
      return _cachedFilteredSkills!;
    }

    List<String> filteredSkills = [];

    // Get skills from selected category
    if (_selectedSkillCategory == 'All') {
      // Combine all skills from all categories
      for (var skills in _skillCategories.values) {
        filteredSkills.addAll(skills);
      }
    } else {
      filteredSkills = List.from(
        _skillCategories[_selectedSkillCategory] ?? [],
      );
    }

    // Apply search filter
    if (_skillSearchQuery.isNotEmpty) {
      filteredSkills =
          filteredSkills
              .where((skill) => skill.toLowerCase().contains(_skillSearchQuery))
              .toList();
    }

    // Remove already selected skills
    filteredSkills =
        filteredSkills
            .where((skill) => !_selectedSkills.contains(skill))
            .toList();

    // Cache the result
    _cachedFilteredSkills = filteredSkills;
    _lastSearchQuery = _skillSearchQuery;
    _lastSelectedCategory = _selectedSkillCategory;

    return filteredSkills;
  }

  // Optimized method to add experience
  void _addExperience() {
    setState(() {
      _experiences.add({
        'jobTitle': '',
        'company': '',
        'duration': '',
        'description': '',
      });
      _experienceControllers.add({
        'jobTitle': TextEditingController(),
        'company': TextEditingController(),
        'duration': TextEditingController(),
        'description': TextEditingController(),
      });
    });
  }

  // Optimized method to remove experience
  void _removeExperience(int index) {
    setState(() {
      // Dispose controllers to prevent memory leaks
      for (var controller in _experienceControllers[index].values) {
        controller.dispose();
      }
      _experiences.removeAt(index);
      _experienceControllers.removeAt(index);
    });
  }

  void _addEducation() => setState(() {
    _education.add({
      'degree': '',
      'institution': '',
      'year': '',
      'description': '',
    });
  });

  void _removeEducation(int index) =>
      setState(() => _education.removeAt(index));

  void _addProject() => setState(() {
    _projects.add({'title': '', 'description': ''});
  });

  void _removeProject(int index) => setState(() => _projects.removeAt(index));

  void _addCertification() => setState(() {
    _certifications.add({'name': '', 'organization': '', 'year': ''});
  });

  void _removeCertification(int index) =>
      setState(() => _certifications.removeAt(index));

  Future<void> _loadResumeData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      // For new resume creation, initialize with default values
      if (widget.resumeData == null) {
        setState(() {
          _fullNameController.text = '';
          _emailController.text = user.email ?? '';
          _phoneController.text = '';
          _addressController.text = '';
          _dobController.text = '';
          _nationalityController.text = '';
          _selectedGender = null;
          _objectiveController.text = '';
          _summaryController.text = '';
          _hobbiesController.text = '';
          _selectedSkills.clear();
          _selectedLanguages.clear();
          _experiences.clear();
          _education.clear();
          _projects.clear();
          _certifications.clear();
          _experienceControllers.clear();
          _isLoading = false;
        });
        return;
      }

      // For editing existing resume
      _loadDataFromMap(widget.resumeData!);
    } catch (e) {
      debugPrint('Error loading resume: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading resume: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadDataFromMap(Map<String, dynamic> data) {
    if (!mounted) return;

    setState(() {
      // Load personal info
      if (data['personalInfo'] != null) {
        final personalInfo = data['personalInfo'] as Map<String, dynamic>;
        _fullNameController.text = personalInfo['fullName']?.toString() ?? '';
        _emailController.text = personalInfo['email']?.toString() ?? '';
        _phoneController.text = personalInfo['phone']?.toString() ?? '';
        _addressController.text = personalInfo['address']?.toString() ?? '';
        _dobController.text = personalInfo['dateOfBirth']?.toString() ?? '';
        _nationalityController.text =
            personalInfo['nationality']?.toString() ?? '';
        _selectedGender = personalInfo['gender']?.toString();
        _linkedinController.text = personalInfo['linkedin']?.toString() ?? '';
      }

      // Load other fields
      _objectiveController.text = data['objective']?.toString() ?? '';
      _summaryController.text = data['summary']?.toString() ?? '';
      _hobbiesController.text = data['hobbies']?.toString() ?? '';

      // Load experiences
      _experiences.clear();
      _experienceControllers.clear();
      if (data['experiences'] != null) {
        for (final exp in data['experiences'] as List) {
          final map = exp as Map<String, dynamic>;
          _experiences.add({
            'jobTitle': map['jobTitle']?.toString() ?? '',
            'company': map['company']?.toString() ?? '',
            'duration': map['duration']?.toString() ?? '',
            'description': map['description']?.toString() ?? '',
          });
          _experienceControllers.add({
            'jobTitle': TextEditingController(
              text: map['jobTitle']?.toString() ?? '',
            ),
            'company': TextEditingController(
              text: map['company']?.toString() ?? '',
            ),
            'duration': TextEditingController(
              text: map['duration']?.toString() ?? '',
            ),
            'description': TextEditingController(
              text: map['description']?.toString() ?? '',
            ),
          });
        }
      }

      _education.clear();
      if (data['education'] != null) {
        _education.addAll(
          (data['education'] as List).map((e) {
            final map = e as Map<String, dynamic>;
            return {
              'degree': map['degree']?.toString() ?? '',
              'institution': map['institution']?.toString() ?? '',
              'year': map['year']?.toString() ?? '',
              'description': map['description']?.toString() ?? '',
            };
          }).toList(),
        );
      }

      _projects.clear();
      if (data['projects'] != null) {
        _projects.addAll(
          (data['projects'] as List).map((e) {
            final map = e as Map<String, dynamic>;
            return {
              'title': map['title']?.toString() ?? '',
              'description': map['description']?.toString() ?? '',
            };
          }).toList(),
        );
      }

      _certifications.clear();
      if (data['certifications'] != null) {
        _certifications.addAll(
          (data['certifications'] as List).map((e) {
            final map = e as Map<String, dynamic>;
            return {
              'name': map['name']?.toString() ?? '',
              'organization': map['organization']?.toString() ?? '',
              'year': map['year']?.toString() ?? '',
            };
          }).toList(),
        );
      }

      _selectedSkills.clear();
      if (data['skills'] != null) {
        _selectedSkills.addAll(
          (data['skills'] as List).map((e) => e.toString()).toList(),
        );
      }

      _selectedLanguages.clear();
      if (data['languages'] != null) {
        _selectedLanguages.addAll(
          (data['languages'] as List).map((e) => e.toString()).toList(),
        );
      }
    });
  }

  // Add this method for handling form submission
  Future<void> _handleFormSubmit() async {
    if (_isLoading) return;

    // Validate required fields
    if (_fullNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your full name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate education
    if (_education.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one education entry'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate at least one education entry has required fields
    bool hasValidEducation = false;
    for (var edu in _education) {
      if (edu['degree']?.isNotEmpty == true &&
          edu['institution']?.isNotEmpty == true &&
          edu['year']?.isNotEmpty == true) {
        hasValidEducation = true;
        break;
      }
    }

    if (!hasValidEducation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill in all required fields for at least one education entry',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Prepare resume data
      final resumeData = {
        'userId': user.uid,
        'personalInfo': {
          'fullName': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'dateOfBirth': _dobController.text.trim(),
          'nationality': _nationalityController.text.trim(),
          'gender': _selectedGender,
          'linkedin': _linkedinController.text.trim(),
          'isFreshGraduate': _experiences.isEmpty,
        },
        'summary': _summaryController.text.trim(),
        'objective': _objectiveController.text.trim(),
        'skills':
            _selectedSkills
                .where((skill) => skill.isNotEmpty)
                .map((skill) => skill.toString())
                .toList(),
        'languages':
            _selectedLanguages
                .where((language) => language.isNotEmpty)
                .map((language) => language.toString())
                .toList(),
        'experiences':
            _experiences
                // ignore: unnecessary_null_comparison
                .where((exp) => exp != null)
                .map(
                  (exp) => {
                    'jobTitle': exp['jobTitle']?.toString().trim() ?? '',
                    'company': exp['company']?.toString().trim() ?? '',
                    'duration': exp['duration']?.toString().trim() ?? '',
                    'description': exp['description']?.toString().trim() ?? '',
                  },
                )
                .where(
                  (exp) =>
                      exp['jobTitle']!.isNotEmpty ||
                      exp['company']!.isNotEmpty ||
                      exp['duration']!.isNotEmpty ||
                      exp['description']!.isNotEmpty,
                )
                .toList(),
        'education':
            _education
                // ignore: unnecessary_null_comparison
                .where((edu) => edu != null)
                .map(
                  (edu) => {
                    'degree': edu['degree']?.toString().trim() ?? '',
                    'institution': edu['institution']?.toString().trim() ?? '',
                    'year': edu['year']?.toString().trim() ?? '',
                    'description': edu['description']?.toString().trim() ?? '',
                  },
                )
                .where(
                  (edu) =>
                      edu['degree']!.isNotEmpty &&
                      edu['institution']!.isNotEmpty &&
                      edu['year']!.isNotEmpty,
                )
                .toList(),
        'projects':
            _projects
                // ignore: unnecessary_null_comparison
                .where((proj) => proj != null)
                .map(
                  (proj) => {
                    'title': proj['title']?.toString().trim() ?? '',
                    'description': proj['description']?.toString().trim() ?? '',
                  },
                )
                .where(
                  (proj) =>
                      proj['title']!.isNotEmpty &&
                      proj['description']!.isNotEmpty,
                )
                .toList(),
        'certifications':
            _certifications
                // ignore: unnecessary_null_comparison
                .where((cert) => cert != null)
                .map(
                  (cert) => {
                    'name': cert['name']?.toString().trim() ?? '',
                    'organization':
                        cert['organization']?.toString().trim() ?? '',
                    'year': cert['year']?.toString().trim() ?? '',
                  },
                )
                .where(
                  (cert) =>
                      cert['name']!.isNotEmpty &&
                      cert['organization']!.isNotEmpty &&
                      cert['year']!.isNotEmpty,
                )
                .toList(),
        'hobbies': _hobbiesController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'title': '${_fullNameController.text.trim()}\'s Resume',
      };

      // Add createdAt only for new resumes
      if (widget.resumeData == null || widget.resumeData!['id'] == null) {
        resumeData['createdAt'] = FieldValue.serverTimestamp();
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Save to Firestore with retry logic
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          if (widget.resumeData != null && widget.resumeData!['id'] != null) {
            await _firestore
                .collection('resumes')
                .doc(widget.resumeData!['id'])
                .update(resumeData);
          } else {
            await _firestore.collection('resumes').add(resumeData);
          }
          break;
        } catch (e) {
          retryCount++;
          if (retryCount == maxRetries) {
            rethrow;
          }
          await Future.delayed(Duration(seconds: retryCount));
        }
      }

      if (!mounted) return;

      // Dismiss loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resume saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to home
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const Home(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            return SlideTransition(position: offsetAnimation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Dismiss loading dialog if it's showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving resume: ${e.toString()}'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _handleFormSubmit,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _objectiveController.dispose();
    _hobbiesController.dispose();
    _summaryController.dispose();
    _dobController.dispose();
    _nationalityController.dispose();
    _linkedinController.dispose();
    _pageAnimationController.dispose();
    _skillSearchController.dispose();

    // Dispose experience controllers
    for (var controllers in _experienceControllers) {
      for (var controller in controllers.values) {
        controller.dispose();
      }
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.resumeData != null ? 'Edit Resume' : 'Create Resume',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _handleFormSubmit,
            tooltip: 'Save Resume',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildStepIndicator(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                    });
                  },
                  children: [
                    _buildPersonalInfoStep(),
                    _buildSummaryStep(),
                    _buildExperienceStep(),
                    _buildEducationStep(),
                    _buildSkillsStep(),
                    _buildProjectsStep(),
                  ],
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      bottomNavigationBar: _buildNavigationButtons(),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalSteps, (index) {
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;
              final isLast = index == _totalSteps - 1;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          isActive
                              ? Theme.of(context).colorScheme.primary
                              : isCompleted
                              ? Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.2)
                              : Colors.grey[200],
                      border: Border.all(
                        color:
                            isActive
                                ? Theme.of(context).colorScheme.primary
                                : isCompleted
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child:
                          isCompleted
                              ? Icon(
                                Icons.check,
                                color: Theme.of(context).colorScheme.primary,
                                size: 14,
                              )
                              : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color:
                                      isActive
                                          ? Colors.white
                                          : isCompleted
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.primary
                                          : Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 24,
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color:
                            isCompleted
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              );
            }),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
              minHeight: 2,
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int index) {
    switch (index) {
      case 0:
        return 'Personal Info';
      case 1:
        return 'Summary';
      case 2:
        return 'Experience';
      case 3:
        return 'Education';
      case 4:
        return 'Skills';
      case 5:
        return 'Projects';
      default:
        return '';
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            ElevatedButton.icon(
              onPressed: _previousStep,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            )
          else
            const SizedBox(width: 100),
          ElevatedButton.icon(
            onPressed:
                _currentStep == _totalSteps - 1 ? _handleFormSubmit : _nextStep,
            icon: Icon(
              _currentStep == _totalSteps - 1
                  ? Icons.save
                  : Icons.arrow_forward,
            ),
            label: Text(
              _currentStep == _totalSteps - 1 ? 'Save Resume' : 'Next',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'Personal Information',
            subtitle: 'Enter your basic details to get started',
            icon: Icons.person,
          ),
          const SizedBox(height: 24),
          _buildTextFormField(
            controller: _fullNameController,
            label: 'Full Name',
            hintText: 'Enter your full name',
            isRequired: true,
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _emailController,
            label: 'Email Address',
            hintText: 'Enter your email address',
            isRequired: true,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _phoneController,
            label: 'Phone Number',
            hintText: 'Enter your phone number',
            isRequired: true,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _addressController,
            label: 'Address',
            hintText: 'Enter your address',
            prefixIcon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _dobController,
            label: 'Date of Birth',
            hintText: 'Select your date of birth',
            prefixIcon: Icons.calendar_today_outlined,
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                _dobController.text = '${date.day}/${date.month}/${date.year}';
              }
            },
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _nationalityController,
            label: 'Nationality',
            hintText: 'Enter your nationality',
            prefixIcon: Icons.public_outlined,
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _linkedinController,
            label: 'LinkedIn Profile',
            hintText: 'Enter your LinkedIn profile URL',
            prefixIcon: Icons.link_outlined,
          ),
          const SizedBox(height: 16),
          GenderSelection(
            selectedGender: _selectedGender,
            onChanged: (value) {
              setState(() {
                _selectedGender = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    bool isRequired = false,
    TextInputType? keyboardType,
    IconData? prefixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
    int? maxLines,
    Function(String?)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label + (isRequired ? ' *' : ''),
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'This field is required';
        }
        return null;
      },
      onChanged: onChanged,
    );
  }

  Widget _buildSummaryStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'Professional Summary',
            subtitle:
                'Write a compelling summary of your professional background',
            icon: Icons.description_outlined,
          ),
          const SizedBox(height: 24),
          _buildTextFormField(
            controller: _summaryController,
            label: 'Professional Summary',
            hintText:
                'Write a brief summary of your professional background and key achievements',
            prefixIcon: Icons.work_outline,
            maxLines: 5,
          ),
          const SizedBox(height: 24),
          _buildTextFormField(
            controller: _objectiveController,
            label: 'Career Objective',
            hintText: 'Write your career objectives and goals',
            prefixIcon: Icons.flag_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          _buildTextFormField(
            controller: _hobbiesController,
            label: 'Hobbies & Interests',
            hintText: 'List your hobbies and interests',
            prefixIcon: Icons.sports_esports_outlined,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'Work Experience',
            subtitle:
                'Optional - Add your work experience or skip if you\'re a fresh graduate',
            icon: Icons.work,
          ),
          const SizedBox(height: 16),
          // Add information box for fresh graduates
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Tips for Fresh Graduates',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'If you\'re a fresh graduate, you can:',
                  style: TextStyle(
                    color: Colors.blue[900],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTipItem(
                  'Focus on your education and academic achievements',
                ),
                _buildTipItem('Add relevant projects and internships'),
                _buildTipItem('Highlight your skills and certifications'),
                _buildTipItem('Include any volunteer work or leadership roles'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_experiences.isNotEmpty) ...[
            ...List.generate(_experiences.length, (index) {
              return _buildExperienceCard(index);
            }),
            const SizedBox(height: 16),
          ],
          _buildAddButton(
            onPressed: _addExperience,
            label: 'Add Work Experience',
            icon: Icons.add_circle_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, color: Colors.blue[700], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.blue[900], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceCard(int index) {
    final controllers = _experienceControllers[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Experience ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeExperience(index),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: controllers['jobTitle']!,
              label: 'Job Title',
              hintText: 'Enter your job title',
              prefixIcon: Icons.work_outline,
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: controllers['company']!,
              label: 'Company',
              hintText: 'Enter company name',
              prefixIcon: Icons.business_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: controllers['duration']!,
              label: 'Duration',
              hintText: 'e.g., Jan 2020 - Present',
              prefixIcon: Icons.calendar_today_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: controllers['description']!,
              label: 'Description',
              hintText: 'Describe your responsibilities and achievements',
              prefixIcon: Icons.description_outlined,
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'Education',
            subtitle: 'Add your educational background',
            icon: Icons.school,
          ),
          const SizedBox(height: 24),
          ...List.generate(_education.length, (index) {
            return _buildEducationCard(index);
          }),
          _buildAddButton(
            onPressed: _addEducation,
            label: 'Add Education',
            icon: Icons.add_circle_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildEducationCard(int index) {
    final education = _education[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Education ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeEducation(index),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: TextEditingController(
                text: education['degree'] ?? '',
              ),
              label: 'Degree',
              hintText: 'Enter your degree',
              prefixIcon: Icons.school_outlined,
              onChanged: (value) => education['degree'] = value ?? '',
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: TextEditingController(
                text: education['institution'] ?? '',
              ),
              label: 'Institution',
              hintText: 'Enter institution name',
              prefixIcon: Icons.account_balance_outlined,
              onChanged: (value) => education['institution'] = value ?? '',
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: TextEditingController(text: education['year'] ?? ''),
              label: 'Year',
              hintText: 'e.g., 2018 - 2022',
              prefixIcon: Icons.calendar_today_outlined,
              onChanged: (value) => education['year'] = value ?? '',
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: TextEditingController(
                text: education['description'] ?? '',
              ),
              label: 'Description',
              hintText: 'Describe your education and achievements',
              prefixIcon: Icons.description_outlined,
              maxLines: 4,
              onChanged: (value) => education['description'] = value ?? '',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'Skills',
            subtitle: 'Add your technical and soft skills',
            icon: Icons.psychology,
          ),
          const SizedBox(height: 24),
          _buildCustomSkills(),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          Text(
            'Available Skills',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSkillSearchBar(),
          const SizedBox(height: 16),
          _buildSkillCategories(),
          const SizedBox(height: 16),
          _buildFilteredSkills(),
          const SizedBox(height: 16),
          _buildSelectedSkills(),
        ],
      ),
    );
  }

  Widget _buildCustomSkills() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom Skills',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Add your own custom skills that are not in the predefined list',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        CustomFieldList(
          items: _selectedSkills.toList(),
          onChanged: (items) {
            setState(() {
              _selectedSkills.clear();
              _selectedSkills.addAll(items);
            });
          },
          label: 'Add Custom Skills',
          hintText: 'Enter a custom skill',
        ),
      ],
    );
  }

  Widget _buildSkillSearchBar() {
    return TextField(
      controller: _skillSearchController,
      decoration: InputDecoration(
        hintText: 'Search predefined skills...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon:
            _skillSearchQuery.isNotEmpty
                ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _skillSearchController.clear();
                      _skillSearchQuery = '';
                      _cachedFilteredSkills = null;
                    });
                  },
                )
                : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      onChanged: (value) {
        setState(() {
          _skillSearchQuery = value.toLowerCase();
          _cachedFilteredSkills = null;
        });
      },
    );
  }

  Widget _buildFilteredSkills() {
    final filteredSkills = _getFilteredSkills();
    if (filteredSkills.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          filteredSkills.map((skill) {
            return FilterChip(
              label: Text(skill),
              selected: _selectedSkills.contains(skill),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSkills.add(skill);
                  } else {
                    _selectedSkills.remove(skill);
                  }
                  // Clear cache when selection changes
                  _cachedFilteredSkills = null;
                });
              },
              selectedColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.2),
              checkmarkColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color:
                    _selectedSkills.contains(skill)
                        ? Theme.of(context).colorScheme.primary
                        : Colors.black87,
                fontWeight:
                    _selectedSkills.contains(skill)
                        ? FontWeight.bold
                        : FontWeight.normal,
              ),
            );
          }).toList(),
    );
  }

  Widget _buildSelectedSkills() {
    if (_selectedSkills.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected Skills',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _selectedSkills.map((skill) {
                return Chip(
                  label: Text(skill),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () {
                    setState(() {
                      _selectedSkills.remove(skill);
                      _cachedFilteredSkills = null;
                    });
                  },
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildSkillCategories() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            _skillCategories.keys.map((category) {
              final isSelected = category == _selectedSkillCategory;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedSkillCategory = category;
                      _cachedFilteredSkills = null;
                    });
                  },
                  selectedColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.2),
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color:
                        isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.black87,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildProjectsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'Projects',
            subtitle: 'Add your notable projects',
            icon: Icons.code,
          ),
          const SizedBox(height: 24),
          ...List.generate(_projects.length, (index) {
            return _buildProjectCard(index);
          }),
          _buildAddButton(
            onPressed: _addProject,
            label: 'Add Project',
            icon: Icons.add_circle_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(int index) {
    final project = _projects[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Project ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeProject(index),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: TextEditingController(text: project['title'] ?? ''),
              label: 'Project Title',
              hintText: 'Enter project title',
              prefixIcon: Icons.code_outlined,
              onChanged: (value) => project['title'] = value ?? '',
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: TextEditingController(
                text: project['description'] ?? '',
              ),
              label: 'Description',
              hintText: 'Describe your project and your role',
              prefixIcon: Icons.description_outlined,
              maxLines: 4,
              onChanged: (value) => project['description'] = value ?? '',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
