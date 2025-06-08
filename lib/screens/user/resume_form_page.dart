import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resume_master/screens/user/home.dart';
import 'package:app_settings/app_settings.dart';
import 'package:resume_master/widgets/form_fields.dart';
import 'package:resume_master/models/experience.dart';
import 'package:resume_master/models/education.dart';
import 'package:resume_master/widgets/experience_card.dart';
import 'package:resume_master/widgets/education_card.dart';
import 'package:resume_master/models/project.dart';
import 'package:resume_master/models/certification.dart';
import 'package:resume_master/widgets/project_card.dart';
import 'package:resume_master/widgets/certification_card.dart';
import 'package:resume_master/models/resume.dart';
import 'package:resume_master/widgets/skill_widgets.dart'; // Import the new skill widgets
import 'dart:async'; // Import dart:async for Timer
import 'package:resume_master/services/firebase_service.dart';

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
  final int _totalSteps = 7;

  // Model-driven state
  Resume? _resume;

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
  late TextEditingController _newSkillController;

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Skills and languages
  final Set<String> _selectedSkills = {};
  final Set<String> _selectedLanguages = {};
  String? _selectedGender;

  // Dynamic lists (model-based)
  final List<Experience> _experiences = [];
  final List<Education> _education = [];
  final List<Project> _projects = [];
  final List<Certification> _certifications = [];

  // Progress Tracking
  bool _isPersonalInfoComplete = false;
  bool _isSummaryComplete = false;
  bool _isExperienceComplete = false;
  bool _isEducationComplete = false;
  bool _isSkillsComplete = false;
  bool _isProjectsComplete = false;
  bool _isCertificationsComplete = false;
  double _overallProgress = 0.0;

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
    _newSkillController = TextEditingController();
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
  }

  // Load resume data into model and controllers
  Future<void> _loadResumeData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Get user profile data
      final userData = await FirebaseService().getUserData(user.uid);
      final userName = userData.data()?['name'] ?? user.displayName ?? '';
      final userPhone = userData.data()?['phone'] ?? '';

      if (widget.resumeData == null) {
        // New resume
        _resume = null;
        _fullNameController.text = userName;
        _emailController.text = user.email ?? '';
        _phoneController.text = userPhone;
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
        setState(() => _isLoading = false);
        _updateProgress(); // Calculate initial progress
        return;
      }

      // Editing existing resume
      // Get the document ID from the map and pass it to fromMap
      final resumeId = widget.resumeData!['id'] as String? ?? '';
      _resume = Resume.fromMap(widget.resumeData!, id: resumeId);
      final pi = _resume!.personalInfo;

      // Only auto-fill if fields are empty
      _fullNameController.text =
          (pi['fullName'] as String?)?.isEmpty ?? true
              ? userName
              : pi['fullName'] ?? '';
      _emailController.text =
          (pi['email'] as String?)?.isEmpty ?? true
              ? user.email ?? ''
              : pi['email'] ?? '';
      _phoneController.text =
          (pi['phone'] as String?)?.isEmpty ?? true
              ? userPhone
              : pi['phone'] ?? '';
      _addressController.text = pi['address'] ?? '';
      _dobController.text = pi['dateOfBirth'] ?? '';
      _nationalityController.text = pi['nationality'] ?? '';
      _selectedGender = pi['gender'];
      _objectiveController.text = _resume!.objective;
      _summaryController.text = _resume!.summary;
      _hobbiesController.text = _resume!.hobbies;

      // Update lists using clear and addAll
      _selectedSkills.clear();
      _selectedSkills.addAll(_resume!.skills);
      _selectedLanguages.clear();
      _selectedLanguages.addAll(_resume!.languages);
      _experiences.clear();
      _experiences.addAll(_resume!.experiences);
      _education.clear();
      _education.addAll(_resume!.education);
      _projects.clear();
      _projects.addAll(_resume!.projects);
      _certifications.clear();
      _certifications.addAll(_resume!.certifications);

      setState(() => _isLoading = false);
      _updateProgress(); // Calculate initial progress
    } catch (e) {
      debugPrint('Error loading resume data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading resume: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  // Build Resume model from controllers and lists
  Resume _buildResumeForSave(String userId) {
    return Resume(
      id: _resume?.id ?? '',
      userId: userId,
      personalInfo: {
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
      summary: _summaryController.text.trim(),
      objective: _objectiveController.text.trim(),
      skills: _selectedSkills.where((s) => s.isNotEmpty).toList(),
      languages: _selectedLanguages.where((l) => l.isNotEmpty).toList(),
      experiences: List<Experience>.from(_experiences),
      education: List<Education>.from(_education),
      projects: List<Project>.from(_projects),
      certifications: List<Certification>.from(_certifications),
      hobbies: _hobbiesController.text.trim(),
      createdAt: _resume?.createdAt,
      updatedAt: DateTime.now(),
      title: '${_fullNameController.text.trim()}\'s Resume',
    );
  }

  // Save handler
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
    if (_education.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one education entry'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    bool hasValidEducation = false;
    for (var edu in _education) {
      if (edu.degree.isNotEmpty &&
          edu.institution.isNotEmpty &&
          edu.year.isNotEmpty) {
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
      if (user == null) throw Exception('User not authenticated');
      final resume = _buildResumeForSave(user.uid);
      final resumeData = resume.toMap();
      // Add createdAt only for new resumes
      if (_resume == null || _resume!.id.isEmpty) {
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
          if (_resume != null && _resume!.id.isNotEmpty) {
            await _firestore
                .collection('resumes')
                .doc(_resume!.id)
                .update(resumeData);
          } else {
            await _firestore.collection('resumes').add(resumeData);
          }
          break;
        } catch (e) {
          retryCount++;
          if (retryCount == maxRetries) rethrow;
          await Future.delayed(Duration(seconds: retryCount));
        }
      }
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resume saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
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
    _newSkillController.dispose();
    _pageAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _resume == null ? 'Create Resume' : 'Edit Resume',
            style: const TextStyle(
              fontFamily: 'CrimsonText',
              fontWeight: FontWeight.bold,
            ),
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
                LinearProgressIndicator(
                  value: _overallProgress,
                  backgroundColor: Colors.grey[300],
                  color: Theme.of(context).colorScheme.primary,
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _currentStep = index;
                      });
                      // Dismiss keyboard when changing pages
                      FocusScope.of(context).unfocus();
                    },
                    children: [
                      _buildScrollableStep(_buildPersonalInfoStep()),
                      _buildScrollableStep(_buildSummaryStep()),
                      _buildScrollableStep(_buildExperienceStep()),
                      _buildScrollableStep(_buildEducationStep()),
                      _buildScrollableStep(_buildSkillsStep()),
                      _buildScrollableStep(_buildProjectsStep()),
                      _buildScrollableStep(_buildCertificationsStep()),
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
      ),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: List.generate(_totalSteps, (index) {
            final isActive = index == _currentStep;
            final isCompleted = index < _currentStep;
            Color stepColor =
                isCompleted
                    ? Theme.of(context).colorScheme.primary
                    : isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[400]!;

            Color textColor =
                isCompleted
                    ? Theme.of(context).colorScheme.onPrimary
                    : isActive
                    ? Theme.of(context).colorScheme.onPrimary
                    : Colors.grey[700]!;

            Widget stepContent =
                isCompleted
                    ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 14,
                    )
                    : Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );

            return InkWell(
              onTap: () {
                setState(() {
                  _currentStep = index;
                });
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.8,
                          end: 1.0,
                        ).animate(_pageAnimationController),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: stepColor,
                            border: Border.all(
                              color:
                                  isCompleted || isActive
                                      ? stepColor
                                      : Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: Center(child: stepContent),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getStepTitle(index),
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              isActive
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey[700],
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  if (index < _totalSteps - 1)
                    Container(
                      height: 2.0,
                      width: 40.0,
                      color:
                          isCompleted
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[300],
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    ),
                ],
              ),
            );
          }),
        ),
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
      case 6:
        return 'Certifications';
      default:
        return '';
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageAnimationController.forward(from: 0.0);
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
      _pageAnimationController.forward(from: 0.0);
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
            Tooltip(
              message: 'Previous Step',
              child: ElevatedButton.icon(
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
              ),
            )
          else
            const SizedBox(width: 100),
          Tooltip(
            message:
                _currentStep == _totalSteps - 1 ? 'Save Resume' : 'Next Step',
            child: ElevatedButton.icon(
              onPressed:
                  _isLoading
                      ? null
                      : (_currentStep == _totalSteps - 1
                          ? _handleFormSubmit
                          : _nextStep),
              icon:
                  _isLoading
                      ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(4.0),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : Icon(
                        _currentStep == _totalSteps - 1
                            ? Icons.save
                            : Icons.arrow_forward,
                      ),
              label:
                  _isLoading
                      ? const Text('Saving...')
                      : Text(
                        _currentStep == _totalSteps - 1
                            ? 'Save Resume'
                            : 'Next',
                      ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
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
    bool autofocus = false,
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
      autofocus: autofocus,
      textInputAction: maxLines == null ? TextInputAction.next : TextInputAction.newline,
      onFieldSubmitted: (_) {
        if (maxLines == null) {
          FocusScope.of(context).nextFocus();
        }
      },
    );
  }

  Widget _buildSummaryStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _buildSummaryStepContent(),
    );
  }

  Widget _buildSummaryStepContent() {
    return Column(
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
          autofocus: false,
          onChanged: (_) => _updateProgress(),
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
    );
  }

  Widget _buildExperienceStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: _buildExperienceStepContent(),
    );
  }

  Widget _buildExperienceStepContent() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              title: 'Work Experience',
              subtitle:
                  "Optional — Add your work experience or skip if you're a fresh graduate",
              icon: Icons.work_outline,
            ),
            const SizedBox(height: 20),
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
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 20,
                      ),
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
                    "If you're a fresh graduate, you can:",
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
                  _buildTipItem(
                    'Include any volunteer work or leadership roles',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ...List.generate(_experiences.length, (index) {
              return ExperienceCard(
                experience: _experiences[index],
                autofocus: false,
                onChanged: (exp) => _updateExperience(index, exp),
                onDelete: () => _removeExperience(index),
              );
            }),
            const SizedBox(height: 16),
            _buildAddButton(
              onPressed: _addExperience,
              label: 'Add Work Experience',
              icon: Icons.add_circle_outline,
            ),
          ],
        ),
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

  Widget _buildEducationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _buildEducationStepContent(),
    );
  }

  Widget _buildEducationStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Education',
          subtitle: 'Add your educational background',
          icon: Icons.school,
        ),
        const SizedBox(height: 24),
        ...List.generate(_education.length, (index) {
          return EducationCard(
            education: _education[index],
            autofocus: false,
            onChanged: (edu) => _updateEducation(index, edu),
            onDelete: () => _removeEducation(index),
          );
        }),
        _buildAddButton(
          onPressed: _addEducation,
          label: 'Add Education',
          icon: Icons.add_circle_outline,
        ),
      ],
    );
  }

  Widget _buildSkillsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _buildSkillsStepContent(),
    );
  }

  Widget _buildSkillsStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Skills',
          subtitle: 'Add your technical and soft skills',
          icon: Icons.psychology,
        ),
        const SizedBox(height: 24),
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
        TextField(
          controller: _newSkillController,
          decoration: InputDecoration(
            hintText: 'Enter Your Professional skill',
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _addSkill,
            ),
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
          onSubmitted: (_) => _addSkill(),
        ),
        const SizedBox(height: 24),
        SelectedSkillsDisplay(
          selectedSkills: _selectedSkills,
          onSkillRemoved: (skill) {
            setState(() {
              _selectedSkills.remove(skill);
              _updateProgress();
            });
          },
        ),
      ],
    );
  }

  Widget _buildProjectsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _buildProjectsStepContent(),
    );
  }

  Widget _buildProjectsStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Projects',
          subtitle: 'Add your notable projects',
          icon: Icons.code,
        ),
        const SizedBox(height: 24),
        ...List.generate(_projects.length, (index) {
          return ProjectCard(
            project: _projects[index],
            autofocus: false,
            onChanged: (proj) => _updateProject(index, proj),
            onDelete: () => _removeProject(index),
          );
        }),
        _buildAddButton(
          onPressed: _addProject,
          label: 'Add Project',
          icon: Icons.add_circle_outline,
        ),
      ],
    );
  }

  Widget _buildCertificationsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _buildCertificationsStepContent(),
    );
  }

  Widget _buildCertificationsStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Certifications',
          subtitle: 'Add your certifications',
          icon: Icons.card_membership,
        ),
        const SizedBox(height: 24),
        ...List.generate(_certifications.length, (index) {
          return CertificationCard(
            certification: _certifications[index],
            autofocus: false,
            onChanged: (cert) => _updateCertification(index, cert),
            onDelete: () => _removeCertification(index),
          );
        }),
        _buildAddButton(
          onPressed: _addCertification,
          label: 'Add Certification',
          icon: Icons.add_circle_outline,
        ),
      ],
    );
  }

  // Add/Remove methods for dynamic lists
  void _addExperience() => setState(() {
    _experiences.add(
      Experience(jobTitle: '', company: '', duration: '', description: ''),
    );
    // Request focus for the first field of the newly added experience card
    // This will be handled by the autofocus logic within ExperienceCard
    _updateProgress();
  });

  void _removeExperience(int index) => setState(() {
    _experiences.removeAt(index);
    _updateProgress();
  });

  void _updateExperience(int index, Experience updatedExperience) =>
      setState(() {
        if (index >= 0 && index < _experiences.length) {
          _experiences[index] = updatedExperience;
        }
        _updateProgress();
      });

  void _addEducation() => setState(() {
    _education.add(
      Education(degree: '', institution: '', year: '', description: ''),
    );
    // Request focus for the first field of the newly added education card
    // This will be handled by the autofocus logic within EducationCard
    _updateProgress();
  });

  void _removeEducation(int index) => setState(() {
    _education.removeAt(index);
    _updateProgress();
  });

  void _updateEducation(int index, Education updatedEducation) => setState(() {
    if (index >= 0 && index < _education.length) {
      _education[index] = updatedEducation;
    }
    _updateProgress();
  });

  void _addProject() => setState(() {
    _projects.add(Project(title: '', description: ''));
    // Request focus for the first field of the newly added project card
    // This will be handled by the autofocus logic within ProjectCard
    _updateProgress();
  });

  void _removeProject(int index) => setState(() {
    _projects.removeAt(index);
    _updateProgress();
  });

  void _updateProject(int index, Project updatedProject) => setState(() {
    if (index >= 0 && index < _projects.length) {
      _projects[index] = updatedProject;
    }
    _updateProgress();
  });

  void _addCertification() => setState(() {
    _certifications.add(Certification(name: '', organization: '', year: ''));
    // Request focus for the first field of the newly added certification card
    // This will be handled by the autofocus logic within CertificationCard
    _updateProgress();
  });

  void _removeCertification(int index) => setState(() {
    _certifications.removeAt(index);
    _updateProgress();
  });

  void _updateCertification(int index, Certification updatedCertification) =>
      setState(() {
        if (index >= 0 && index < _certifications.length) {
          _certifications[index] = updatedCertification;
        }
        _updateProgress();
      });

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

  void _addSkill() {
    final newSkill = _newSkillController.text.trim();
    if (newSkill.isNotEmpty && !_selectedSkills.contains(newSkill)) {
      setState(() {
        _selectedSkills.add(newSkill);
        _newSkillController.clear();
        _updateProgress();
      });
    }
  }

  // Helper method to update progress
  void _updateProgress() {
    setState(() {
      _isPersonalInfoComplete =
          _fullNameController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _phoneController.text.isNotEmpty;

      _isSummaryComplete = _summaryController.text.isNotEmpty;

      _isExperienceComplete = _experiences.isNotEmpty;

      _isEducationComplete = _education.isNotEmpty;

      _isSkillsComplete = _selectedSkills.isNotEmpty;

      _isProjectsComplete = _projects.isNotEmpty;

      _isCertificationsComplete = _certifications.isNotEmpty;

      // ignore: unused_local_variable
      int completedSections = 0;
      if (_isPersonalInfoComplete) completedSections++;
      if (_isSummaryComplete) completedSections++;
      if (_isExperienceComplete) completedSections++;
      if (_isEducationComplete) completedSections++;
      if (_isSkillsComplete) completedSections++;
      if (_isProjectsComplete) completedSections++;
      if (_isCertificationsComplete) completedSections++;

      _overallProgress = completedSections / _totalSteps;
    });
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
            autofocus: false,
            onChanged: (_) => _updateProgress(),
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _emailController,
            label: 'Email Address',
            hintText: 'Enter your email address',
            isRequired: true,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            onChanged: (_) => _updateProgress(),
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _phoneController,
            label: 'Phone Number',
            hintText: 'Enter your phone number',
            isRequired: true,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            onChanged: (_) => _updateProgress(),
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _addressController,
            label: 'Address',
            hintText: 'Enter your address',
            prefixIcon: Icons.location_on_outlined,
            onChanged: (_) => _updateProgress(),
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
                _updateProgress();
              }
            },
            onChanged: (_) => _updateProgress(),
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _nationalityController,
            label: 'Nationality',
            hintText: 'Enter your nationality',
            prefixIcon: Icons.public_outlined,
            onChanged: (_) => _updateProgress(),
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _linkedinController,
            label: 'LinkedIn Profile',
            hintText: 'Enter your LinkedIn profile URL',
            prefixIcon: Icons.link_outlined,
            onChanged: (_) => _updateProgress(),
          ),
          const SizedBox(height: 16),
          GenderSelection(
            selectedGender: _selectedGender,
            onChanged: (value) {
              setState(() {
                _selectedGender = value;
                _updateProgress();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableStep(Widget content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: content,
      ),
    );
  }
}
