import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ResumeWizard extends StatefulWidget {
  const ResumeWizard({super.key});

  @override
  State<ResumeWizard> createState() => _ResumeWizardState();
}

class _ResumeWizardState extends State<ResumeWizard>
    with AutomaticKeepAliveClientMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  File? _profileImage;
  final Set<String> _selectedSkills = {};
  final Set<String> _selectedLanguages = {};
  String? _selectedGender;

  // Dynamic list state variables
  final List<Map<String, String>> _experiences = [];
  final List<Map<String, String>> _education = [];
  final List<Map<String, String>> _projects = [];
  final List<Map<String, String>> _certifications = [];

  // Form controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _objectiveController = TextEditingController();
  final _hobbiesController = TextEditingController();
  final _summaryController = TextEditingController();
  final _dobController = TextEditingController();
  final _nationalityController = TextEditingController();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  bool get wantKeepAlive => true;

  Future<String?> _uploadImage(File image) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final ref = _storage.ref().child('profile_images/${user.uid}');
      final uploadTask = ref.putFile(image);
      final snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _saveResume() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must be logged in to save')),
          );
        }
        return;
      }

      // Upload profile image if exists
      String? imageUrl;
      if (_profileImage != null) {
        imageUrl = await _uploadImage(_profileImage!);
      }

      // Prepare resume data
      final resumeData = {
        'profileImage': imageUrl,
        'personalInfo': {
          'fullName': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'dateOfBirth': _dobController.text.trim(),
          'nationality': _nationalityController.text.trim(),
          'gender': _selectedGender,
        },
        'objective': _objectiveController.text.trim(),
        'summary': _summaryController.text.trim(),
        'experiences': _experiences,
        'education': _education,
        'skills': _selectedSkills.toList(),
        'projects': _projects,
        'certifications': _certifications,
        'hobbies': _hobbiesController.text.trim(),
        'languages': _selectedLanguages.toList(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      await _firestore
          .collection('resumes')
          .doc(user.uid)
          .set(resumeData, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resume saved successfully!')),
        );
      }
    } catch (e) {
      debugPrint('Error saving resume: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving resume: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadResumeData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore.collection('resumes').doc(user.uid).get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;

      // Load profile image
      if (data['profileImage'] != null) {
        // Note: This just stores the URL, not the actual File
        setState(
          () => _profileImage = null,
        ); // Would need to download the image
      }

      // Load personal info
      if (data['personalInfo'] != null) {
        final personalInfo = data['personalInfo'] as Map<String, dynamic>;
        _fullNameController.text = personalInfo['fullName'] ?? '';
        _emailController.text = personalInfo['email'] ?? '';
        _phoneController.text = personalInfo['phone'] ?? '';
        _addressController.text = personalInfo['address'] ?? '';
        _dobController.text = personalInfo['dateOfBirth'] ?? '';
        _nationalityController.text = personalInfo['nationality'] ?? '';
        _selectedGender = personalInfo['gender'];
      }

      // Load other fields
      _objectiveController.text = data['objective'] ?? '';
      _summaryController.text = data['summary'] ?? '';
      _hobbiesController.text = data['hobbies'] ?? '';

      // Load lists
      if (data['experiences'] != null) {
        setState(() {
          _experiences.clear();
          _experiences.addAll(
            (data['experiences'] as List).cast<Map<String, String>>(),
          );
        });
      }

      if (data['education'] != null) {
        setState(() {
          _education.clear();
          _education.addAll(
            (data['education'] as List).cast<Map<String, String>>(),
          );
        });
      }

      if (data['projects'] != null) {
        setState(() {
          _projects.clear();
          _projects.addAll(
            (data['projects'] as List).cast<Map<String, String>>(),
          );
        });
      }

      if (data['certifications'] != null) {
        setState(() {
          _certifications.clear();
          _certifications.addAll(
            (data['certifications'] as List).cast<Map<String, String>>(),
          );
        });
      }

      if (data['skills'] != null) {
        setState(() {
          _selectedSkills.clear();
          _selectedSkills.addAll((data['skills'] as List).cast<String>());
        });
      }

      if (data['languages'] != null) {
        setState(() {
          _selectedLanguages.clear();
          _selectedLanguages.addAll((data['languages'] as List).cast<String>());
        });
      }
    } catch (e) {
      debugPrint('Error loading resume: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadResumeData();
  }

  Future<void> _pickImage() async {
    try {
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Permission denied')));
        return;
      }

      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
      );

      if (pickedFile != null && mounted) {
        setState(() => _profileImage = File(pickedFile.path));
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
      }
    }
  }

  void _nextPage() {
    if (_currentPage < 10) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Resume'),
        actions: [
          if (_currentPage == 10)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveResume,
              tooltip: 'Save Resume',
            ),
        ],
      ),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: _buildPages(),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  List<Widget> _buildPages() => [
    _buildProfilePage(),
    _buildContactInfoPage(),
    _buildWorkExperiencePage(),
    _buildEducationPage(),
    _buildObjectivePage(),
    _buildSkillsPage(),
    _buildProjectsPage(),
    _buildCertificationsPage(),
    _buildHobbiesPage(),
    _buildLanguagesPage(),
    _buildPersonalInfoPage(),
  ];

  Widget _buildBottomNavBar() => BottomAppBar(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage != 0)
            TextButton.icon(
              onPressed: _previousPage,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
          if (_currentPage < 10)
            TextButton.icon(
              onPressed: _nextPage,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next'),
            ),
          if (_currentPage == 10)
            ElevatedButton.icon(
              onPressed: _saveResume,
              icon: const Icon(Icons.save),
              label: const Text('Save Resume'),
            ),
        ],
      ),
    ),
  );

  Widget _buildProfilePage() {
    return _buildFormPage(
      title: 'Profile Picture',
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[200],
            backgroundImage:
                _profileImage != null ? FileImage(_profileImage!) : null,
            child:
                _profileImage == null
                    ? const Icon(
                      Icons.add_a_photo,
                      size: 50,
                      color: Colors.grey,
                    )
                    : null,
          ),
        ),
        const SizedBox(height: 20),
        _buildTextFormField(
          controller: _fullNameController,
          label: 'Full Name *',
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        ),
        _buildTextFormField(
          controller: _emailController,
          label: 'Email *',
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        ),
        _buildTextFormField(
          controller: _phoneController,
          label: 'Phone Number *',
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildContactInfoPage() {
    return _buildFormPage(
      title: 'Contact Information',
      children: [
        _buildTextFormField(
          controller: _fullNameController,
          label: 'Full Name *',
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        ),
        _buildTextFormField(
          controller: _emailController,
          label: 'Email *',
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        ),
        _buildTextFormField(
          controller: _phoneController,
          label: 'Phone Number *',
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        ),
        _buildTextFormField(controller: _addressController, label: 'Address'),
      ],
    );
  }

  Widget _buildWorkExperiencePage() {
    return _buildFormPage(
      title: 'Work Experience',
      children: [
        ..._experiences.asMap().entries.map((entry) {
          final index = entry.key;
          final experience = entry.value;
          return _buildEditableCard(
            title: 'Experience ${index + 1}',
            onDelete: () => _removeExperience(index),
            children: [
              _buildTextFormField(
                initialValue: experience['jobTitle'],
                label: 'Job Title *',
                onChanged: (value) => experience['jobTitle'] = value ?? '',
              ),
              _buildTextFormField(
                initialValue: experience['company'],
                label: 'Company *',
                onChanged: (value) => experience['company'] = value ?? '',
              ),
              _buildTextFormField(
                initialValue: experience['duration'],
                label: 'Duration (e.g., 2020-2022)',
                onChanged: (value) => experience['duration'] = value ?? '',
              ),
              _buildTextFormField(
                initialValue: experience['description'],
                label: 'Job Description',
                maxLines: 3,
                onChanged: (value) => experience['description'] = value ?? '',
              ),
            ],
          );
        }),
        _buildAddButton(
          text: 'Add Another Experience',
          onPressed: _addExperience,
        ),
      ],
    );
  }

  Widget _buildEducationPage() {
    return _buildFormPage(
      title: 'Education',
      children: [
        ..._education.asMap().entries.map((entry) {
          final index = entry.key;
          final education = entry.value;
          return _buildEditableCard(
            title: 'Education ${index + 1}',
            onDelete: () => _removeEducation(index),
            children: [
              _buildTextFormField(
                initialValue: education['degree'],
                label: 'Degree *',
                onChanged: (value) => education['degree'] = value ?? '',
              ),
              _buildTextFormField(
                initialValue: education['institution'],
                label: 'Institution *',
                onChanged: (value) => education['institution'] = value ?? '',
              ),
              _buildTextFormField(
                initialValue: education['year'],
                label: 'Year of Graduation',
                onChanged: (value) => education['year'] = value ?? '',
              ),
              _buildTextFormField(
                initialValue: education['description'],
                label: 'Description (Optional)',
                maxLines: 3,
                onChanged: (value) => education['description'] = value ?? '',
              ),
            ],
          );
        }),
        _buildAddButton(
          text: 'Add Another Education',
          onPressed: _addEducation,
        ),
      ],
    );
  }

  Widget _buildObjectivePage() {
    return _buildFormPage(
      title: 'Resume Objective',
      children: [
        _buildTextFormField(
          controller: _objectiveController,
          hintText:
              'Summarize your career goals and what you bring to a company...',
          maxLines: 6,
        ),
      ],
    );
  }

  Widget _buildSkillsPage() {
    final skills = [
      'Flutter',
      'Dart',
      'Firebase',
      'React',
      'Python',
      'SQL',
      'Teamwork',
      'Leadership',
      'Communication',
      'Problem Solving',
    ];

    return _buildFormPage(
      title: 'Select Your Skills',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              skills
                  .map(
                    (skill) => FilterChip(
                      label: Text(skill),
                      selected: _selectedSkills.contains(skill),
                      onSelected:
                          (selected) => setState(() {
                            selected
                                ? _selectedSkills.add(skill)
                                : _selectedSkills.remove(skill);
                          }),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildProjectsPage() {
    return _buildFormPage(
      title: 'Projects',
      children: [
        ..._projects.asMap().entries.map((entry) {
          final index = entry.key;
          final project = entry.value;
          return _buildEditableCard(
            title: 'Project ${index + 1}',
            onDelete: () => _removeProject(index),
            children: [
              _buildTextFormField(
                initialValue: project['title'],
                label: 'Project Title *',
                onChanged: (value) => project['title'] = value ?? '',
              ),
              _buildTextFormField(
                initialValue: project['description'],
                label: 'Description *',
                maxLines: 3,
                onChanged: (value) => project['description'] = value ?? '',
              ),
            ],
          );
        }),
        _buildAddButton(text: 'Add Another Project', onPressed: _addProject),
      ],
    );
  }

  Widget _buildCertificationsPage() {
    return _buildFormPage(
      title: 'Certifications',
      children: [
        ..._certifications.asMap().entries.map((entry) {
          final index = entry.key;
          final certification = entry.value;
          return _buildEditableCard(
            title: 'Certification ${index + 1}',
            onDelete: () => _removeCertification(index),
            children: [
              _buildTextFormField(
                initialValue: certification['name'],
                label: 'Certification Name *',
                onChanged: (value) => certification['name'] = value ?? '',
              ),
              _buildTextFormField(
                initialValue: certification['organization'],
                label: 'Issuing Organization *',
                onChanged:
                    (value) => certification['organization'] = value ?? '',
              ),
              _buildTextFormField(
                initialValue: certification['year'],
                label: 'Year Obtained',
                onChanged: (value) => certification['year'] = value ?? '',
              ),
            ],
          );
        }),
        _buildAddButton(
          text: 'Add Another Certification',
          onPressed: _addCertification,
        ),
      ],
    );
  }

  Widget _buildHobbiesPage() {
    return _buildFormPage(
      title: 'Your Hobbies',
      children: [
        _buildTextFormField(
          controller: _hobbiesController,
          hintText: 'List your hobbies like reading, traveling, coding...',
          maxLines: 5,
        ),
      ],
    );
  }

  Widget _buildLanguagesPage() {
    final languages = [
      'English',
      'Spanish',
      'French',
      'German',
      'Hindi',
      'Mandarin',
      'Arabic',
    ];

    return _buildFormPage(
      title: 'Languages You Know',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              languages
                  .map(
                    (lang) => FilterChip(
                      label: Text(lang),
                      selected: _selectedLanguages.contains(lang),
                      onSelected:
                          (selected) => setState(() {
                            selected
                                ? _selectedLanguages.add(lang)
                                : _selectedLanguages.remove(lang);
                          }),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoPage() {
    return _buildFormPage(
      title: 'Personal Information',
      children: [
        _buildTextFormField(
          controller: _dobController,
          label: 'Date of Birth',
          readOnly: true,
          suffixIcon: const Icon(Icons.calendar_today),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (date != null && mounted) {
              _dobController.text = "${date.day}/${date.month}/${date.year}";
            }
          },
        ),
        _buildTextFormField(
          controller: _nationalityController,
          label: 'Nationality',
        ),
        Text('Gender', style: Theme.of(context).textTheme.labelLarge),
        Row(
          children: [
            _buildGenderRadio('Male'),
            _buildGenderRadio('Female'),
            _buildGenderRadio('Other'),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderRadio(String gender) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Radio<String>(
        value: gender,
        groupValue: _selectedGender,
        onChanged: (value) => setState(() => _selectedGender = value),
      ),
      Text(gender),
    ],
  );

  // Reusable widget builders
  Widget _buildFormPage({
    required String title,
    required List<Widget> children,
  }) => Padding(
    padding: const EdgeInsets.all(20.0),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    ),
  );

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
  }) {
    final effectiveController =
        controller ??
        (initialValue != null
            ? TextEditingController(text: initialValue)
            : null);

    return Column(
      children: [
        TextFormField(
          controller: effectiveController,
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText,
            border: const OutlineInputBorder(),
            suffixIcon: suffixIcon,
          ),
          maxLines: maxLines,
          readOnly: readOnly,
          validator: validator,
          onTap: onTap,
          onChanged: onChanged,
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildEditableCard({
    required String title,
    required VoidCallback onDelete,
    required List<Widget> children,
  }) => Card(
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title),
              IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
            ],
          ),
          ...children,
        ],
      ),
    ),
  );

  Widget _buildAddButton({
    required String text,
    required VoidCallback onPressed,
  }) => Column(
    children: [
      const SizedBox(height: 20),
      ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add),
        label: Text(text),
      ),
    ],
  );
}
