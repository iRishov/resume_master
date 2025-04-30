import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resume_master/screens/home.dart';
import 'package:app_settings/app_settings.dart';
import 'package:resume_master/widgets/form_fields.dart';

class ResumeWizard extends StatefulWidget {
  final Map<String, dynamic>? resumeData;
  const ResumeWizard({super.key, this.resumeData});

  @override
  State<ResumeWizard> createState() => _ResumeWizardState();
}

class _ResumeWizardState extends State<ResumeWizard>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final PageController _pageController = PageController();
  bool _isLoading = false;
  late AnimationController _pageAnimationController;
  late Animation<double> _pageAnimation;

  // Remove profile image related variables
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

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add these lists for predefined skills and languages
  final List<String> _predefinedSkills = [
    // Programming Languages
    'Python', 'Java', 'JavaScript', 'C++', 'C#', 'PHP', 'Swift', 'Kotlin',
    // Web Development
    'HTML5', 'CSS3', 'React', 'Angular', 'Vue.js', 'Node.js', 'Express.js',
    // Backend & Databases
    'Django', 'Flask', 'Spring Boot', 'SQL', 'MongoDB', 'PostgreSQL', 'MySQL',
    // Cloud & DevOps
    'AWS', 'Azure', 'Google Cloud', 'Docker', 'Kubernetes', 'Git', 'CI/CD',
    // Mobile Development
    'Flutter', 'React Native', 'Android', 'iOS',
    // Data Science & AI
    'Machine Learning',
    'Deep Learning',
    'Data Science',
    'TensorFlow',
    'PyTorch',
    // Testing & QA
    'JUnit', 'Selenium', 'TestNG', 'Postman',
    // Other Technical Skills
    'RESTful APIs', 'GraphQL', 'Microservices', 'Agile', 'Scrum', 'DevOps',
  ];

  final List<String> _predefinedLanguages = [
    'English',
    'Hindi',
    'Bengali',
    'Telugu',
    'Marathi',
    'Tamil',
    'Gujarati',
    'Kannada',
    'Malayalam',
    'Punjabi',
    'Odia',
    'Assamese',
    'Urdu',
    'Sanskrit',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _pageAnimation = CurvedAnimation(
      parent: _pageAnimationController,
      curve: Curves.easeInOut,
    );

    // Initialize controllers with empty values
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _objectiveController = TextEditingController();
    _hobbiesController = TextEditingController();
    _summaryController = TextEditingController();
    _dobController = TextEditingController();
    _nationalityController = TextEditingController();

    // Start the animation
    _pageAnimationController.forward();

    // Load data after a short delay to ensure UI is ready
    Future.delayed(const Duration(milliseconds: 100), () {
      if (widget.resumeData != null) {
        _loadExistingResumeData();
      } else {
        _loadResumeData();
      }
    });
  }

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
      }

      // Load other fields
      _objectiveController.text = data['objective']?.toString() ?? '';
      _summaryController.text = data['summary']?.toString() ?? '';
      _hobbiesController.text = data['hobbies']?.toString() ?? '';

      // Load lists
      _experiences.clear();
      if (data['experiences'] != null) {
        _experiences.addAll(
          (data['experiences'] as List).map((e) {
            final map = e as Map<String, dynamic>;
            return {
              'jobTitle': map['jobTitle']?.toString() ?? '',
              'company': map['company']?.toString() ?? '',
              'duration': map['duration']?.toString() ?? '',
              'description': map['description']?.toString() ?? '',
            };
          }).toList(),
        );
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

  void _loadExistingResumeData() {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      _loadDataFromMap(widget.resumeData!);
    } catch (e) {
      debugPrint('Error loading existing resume: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading resume: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Add this method for handling form navigation

  void _addExperience() => setState(() {
    _experiences.add({
      'jobTitle': '',
      'company': '',
      'duration': '',
      'description': '',
    });
  });

  void _removeExperience(int index) =>
      setState(() => _experiences.removeAt(index));

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
          content: Text('Please enter your email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(_emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
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
        },
        'summary': _summaryController.text.trim(),
        'objective': _objectiveController.text.trim(),
        'skills': _selectedSkills.toList(),
        'languages': _selectedLanguages.toList(),
        'experiences':
            _experiences
                .where(
                  (exp) =>
                      exp['jobTitle']?.isNotEmpty == true &&
                      exp['company']?.isNotEmpty == true,
                )
                .toList(),
        'education':
            _education
                .where(
                  (edu) =>
                      edu['degree']?.isNotEmpty == true &&
                      edu['institution']?.isNotEmpty == true,
                )
                .toList(),
        'projects':
            _projects
                .where(
                  (proj) =>
                      proj['title']?.isNotEmpty == true &&
                      proj['description']?.isNotEmpty == true,
                )
                .toList(),
        'certifications':
            _certifications
                .where(
                  (cert) =>
                      cert['name']?.isNotEmpty == true &&
                      cert['organization']?.isNotEmpty == true,
                )
                .toList(),
        'hobbies': _hobbiesController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'title': '${_fullNameController.text.trim()}\'s Resume',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Save to Firestore
      if (widget.resumeData != null && widget.resumeData!['id'] != null) {
        // Update existing resume
        await _firestore
            .collection('resumes')
            .doc(widget.resumeData!['id'])
            .update(resumeData);
      } else {
        // Create new resume
        await _firestore.collection('resumes').add(resumeData);
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

      // Navigate back to home with animation
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

  // Add this method for the skills section
  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Skills', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Select your skills from the list below or add custom ones',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _predefinedSkills.map((skill) {
                return FilterChip(
                  label: Text(skill),
                  selected: _selectedSkills.contains(skill),
                  selectedColor: Theme.of(
                    context,
                  ).colorScheme.primary.withAlpha(100),
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color:
                        _selectedSkills.contains(skill)
                            ? Theme.of(context).colorScheme.primary
                            : Colors.black,
                    fontWeight:
                        _selectedSkills.contains(skill)
                            ? FontWeight.bold
                            : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedSkills.add(skill);
                      } else {
                        _selectedSkills.remove(skill);
                      }
                    });
                  },
                );
              }).toList(),
        ),
        const SizedBox(height: 24),
        CustomFieldList(
          items: _selectedSkills.toList(),
          onChanged: (items) {
            setState(() {
              _selectedSkills.clear();
              _selectedSkills.addAll(items);
            });
          },
          label: 'Custom Skills',
          hintText: 'Add a custom skill',
        ),
      ],
    );
  }

  Widget _buildLanguagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Languages', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Select languages you are proficient in',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _predefinedLanguages.map((lang) {
                return FilterChip(
                  label: Text(lang),
                  selected: _selectedLanguages.contains(lang),
                  selectedColor: Theme.of(
                    context,
                  ).colorScheme.primary.withAlpha(100),
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color:
                        _selectedLanguages.contains(lang)
                            ? Theme.of(context).colorScheme.primary
                            : Colors.black,
                    fontWeight:
                        _selectedLanguages.contains(lang)
                            ? FontWeight.bold
                            : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedLanguages.add(lang);
                      } else {
                        _selectedLanguages.remove(lang);
                      }
                    });
                  },
                );
              }).toList(),
        ),
        const SizedBox(height: 24),
        CustomFieldList(
          items: _selectedLanguages.toList(),
          onChanged: (items) {
            setState(() {
              _selectedLanguages.clear();
              _selectedLanguages.addAll(items);
            });
          },
          label: 'Custom Languages',
          hintText: 'Add a custom language',
        ),
      ],
    );
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
    _pageAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.resumeData != null ? 'Edit Resume' : 'Create Resume',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _handleFormSubmit,
            tooltip: 'Save Resume',
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Personal Information Section
                _buildSection(
                  title: 'Personal Information',
                  subtitle: 'Enter your basic details',
                  children: [
                    _buildTextFormField(
                      controller: _fullNameController,
                      label: 'Full Name',
                      hintText: 'Enter your full name',
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _emailController,
                      label: 'Email Address',
                      hintText: 'Enter your email address',
                      isRequired: true,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hintText: 'Enter your phone number',
                      isRequired: true,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _addressController,
                      label: 'Address',
                      hintText: 'Enter your address',
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
                    const SizedBox(height: 16),
                    TextField(
                      controller: _dobController,
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          _dobController.text = date.toString().split(' ')[0];
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _nationalityController,
                      label: 'Nationality',
                      hintText: 'Enter your nationality',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Professional Summary Section
                _buildSection(
                  title: 'Professional Summary',
                  subtitle:
                      'Write a brief summary of your professional background',
                  children: [
                    _buildTextFormField(
                      controller: _summaryController,
                      label: 'Summary',
                      hintText:
                          'Write a brief summary of your professional background',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _objectiveController,
                      label: 'Career Objective',
                      hintText: 'Write your career objectives and goals',
                      maxLines: 4,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Work Experience Section
                _buildSection(
                  title: 'Work Experience',
                  subtitle: 'Add your work experience details',
                  children: [
                    ..._experiences.asMap().entries.map((entry) {
                      final index = entry.key;
                      final experience = entry.value;
                      return _buildEditableCard(
                        title: 'Experience ${index + 1}',
                        onDelete: () => _removeExperience(index),
                        children: [
                          _buildTextFormField(
                            controller: TextEditingController(
                              text: experience['jobTitle'],
                            ),
                            label: 'Job Title',
                            onChanged:
                                (value) => experience['jobTitle'] = value ?? '',
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: TextEditingController(
                              text: experience['company'],
                            ),
                            label: 'Company',
                            onChanged:
                                (value) => experience['company'] = value ?? '',
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: TextEditingController(
                              text: experience['duration'],
                            ),
                            label: 'Duration',
                            onChanged:
                                (value) => experience['duration'] = value ?? '',
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: TextEditingController(
                              text: experience['description'],
                            ),
                            label: 'Description',
                            maxLines: 3,
                            onChanged:
                                (value) =>
                                    experience['description'] = value ?? '',
                          ),
                        ],
                      );
                    }),
                    _buildAddButton(
                      text: 'Add Another Experience',
                      onPressed: _addExperience,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Education Section
                _buildSection(
                  title: 'Education',
                  subtitle: 'Add your educational background',
                  children: [
                    ..._education.asMap().entries.map((entry) {
                      final index = entry.key;
                      final education = entry.value;
                      return _buildEditableCard(
                        title: 'Education ${index + 1}',
                        onDelete: () => _removeEducation(index),
                        children: [
                          _buildTextFormField(
                            controller: TextEditingController(
                              text: education['degree'],
                            ),
                            label: 'Degree',
                            onChanged:
                                (value) => education['degree'] = value ?? '',
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: TextEditingController(
                              text: education['institution'],
                            ),
                            label: 'Institution',
                            onChanged:
                                (value) =>
                                    education['institution'] = value ?? '',
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: TextEditingController(
                              text: education['year'],
                            ),
                            label: 'Year',
                            onChanged:
                                (value) => education['year'] = value ?? '',
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: TextEditingController(
                              text: education['description'],
                            ),
                            label: 'Description',
                            maxLines: 3,
                            onChanged:
                                (value) =>
                                    education['description'] = value ?? '',
                          ),
                        ],
                      );
                    }),
                    _buildAddButton(
                      text: 'Add Another Education',
                      onPressed: _addEducation,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Skills & Languages Section
                _buildSection(
                  title: 'Skills & Languages',
                  subtitle: 'Add your skills and languages',
                  children: [
                    _buildSkillsSection(),
                    const SizedBox(height: 24),
                    _buildLanguagesSection(),
                  ],
                ),
                const SizedBox(height: 24),

                // Projects Section
                _buildSection(
                  title: 'Projects',
                  subtitle: 'Add your projects',
                  children: [
                    ..._projects.asMap().entries.map((entry) {
                      final index = entry.key;
                      final project = entry.value;
                      return _buildEditableCard(
                        title: 'Project ${index + 1}',
                        onDelete: () => _removeProject(index),
                        children: [
                          _buildTextFormField(
                            controller: TextEditingController(
                              text: project['title'],
                            ),
                            label: 'Project Title',
                            onChanged:
                                (value) => project['title'] = value ?? '',
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: TextEditingController(
                              text: project['description'],
                            ),
                            label: 'Description',
                            maxLines: 3,
                            onChanged:
                                (value) => project['description'] = value ?? '',
                          ),
                        ],
                      );
                    }),
                    _buildAddButton(
                      text: 'Add Another Project',
                      onPressed: _addProject,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Certifications Section
                _buildSection(
                  title: 'Certifications',
                  subtitle: 'Add your certifications',
                  children: [
                    ..._certifications.asMap().entries.map((entry) {
                      final index = entry.key;
                      final certification = entry.value;
                      return _buildEditableCard(
                        title: 'Certification ${index + 1}',
                        onDelete: () => _removeCertification(index),
                        children: [
                          _buildTextFormField(
                            controller: TextEditingController(
                              text: certification['name'],
                            ),
                            label: 'Certification Name',
                            onChanged:
                                (value) => certification['name'] = value ?? '',
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: TextEditingController(
                              text: certification['organization'],
                            ),
                            label: 'Issuing Organization',
                            onChanged:
                                (value) =>
                                    certification['organization'] = value ?? '',
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: TextEditingController(
                              text: certification['year'],
                            ),
                            label: 'Year Obtained',
                            onChanged:
                                (value) => certification['year'] = value ?? '',
                          ),
                        ],
                      );
                    }),
                    _buildAddButton(
                      text: 'Add Another Certification',
                      onPressed: _addCertification,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Additional Information Section
                _buildSection(
                  title: 'Additional Information',
                  subtitle: 'Add any additional information about yourself',
                  children: [
                    _buildTextFormField(
                      controller: _hobbiesController,
                      label: 'Hobbies & Interests',
                      hintText: 'List your hobbies and interests',
                      maxLines: 3,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withAlpha(150),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleFormSubmit,
        icon: const Icon(Icons.save),
        label: const Text('Save Resume'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.edit_document,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    TextEditingController? controller,
    String? initialValue,
    String? label,
    String? hintText,
    int maxLines = 1,
    bool readOnly = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function()? onTap,
    void Function(String?)? onChanged,
    bool isRequired = false,
    TextInputType? keyboardType,
  }) {
    final effectiveController =
        controller ??
        (initialValue != null
            ? TextEditingController(text: initialValue)
            : null);

    return ScaleTransition(
      scale: _pageAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isRequired)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text(
                      '*',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: effectiveController,
              decoration: InputDecoration(
                hintText: hintText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: suffixIcon,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                errorStyle: const TextStyle(fontSize: 12, height: 0.5),
              ),
              maxLines: maxLines,
              readOnly: readOnly,
              validator: validator,
              onTap: onTap,
              onChanged: onChanged,
              keyboardType: keyboardType,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableCard({
    required String title,
    required VoidCallback onDelete,
    required List<Widget> children,
  }) {
    return ScaleTransition(
      scale: _pageAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withAlpha(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    onPressed: onDelete,
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return ScaleTransition(
      scale: _pageAnimation,
      child: Container(
        margin: const EdgeInsets.only(top: 16),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.add),
          label: Text(text),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
