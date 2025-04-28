import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firebase_service.dart';

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
  final _projectTitleController = TextEditingController();
  final _projectDescriptionController = TextEditingController();
  final _certificationNameController = TextEditingController();
  final _certificationOrgController = TextEditingController();
  final _dobController = TextEditingController();
  final _nationalityController = TextEditingController();

  Future<void> _pickImage() async {
    try {
      var status = await Permission.photos.request();
      if (status.isGranted) {
        final pickedFile = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
        );
        if (pickedFile != null) {
          setState(() {
            _profileImage = File(pickedFile.path);
          });
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Permission denied')));
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
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

  Future<void> _saveResume() async {
    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_profileImage != null) {
        // For demo purposes, using a fixed userId. In a real app, this would come from authentication
        const userId = 'demo_user';
        imageUrl = await FirebaseService.uploadImage(_profileImage!, userId);
      }

      final resumeData = {
        'profileImage': imageUrl,
        'personalInfo': {
          'fullName': _fullNameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
          'dateOfBirth': _dobController.text,
          'nationality': _nationalityController.text,
          'gender': _selectedGender,
        },
        'objective': _objectiveController.text,
        'summary': _summaryController.text,
        'experiences': _experiences,
        'education': _education,
        'skills': _selectedSkills.toList(),
        'projects': _projects,
        'certifications': _certifications,
        'hobbies': _hobbiesController.text,
        'languages': _selectedLanguages.toList(),
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      await FirebaseService.saveResume(
        userId: 'demo_user',
        resumeData: resumeData,
      );

      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resume saved successfully!')),
      );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving resume: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addExperience() {
    setState(() {
      _experiences.add({
        'jobTitle': '',
        'company': '',
        'duration': '',
        'description': '',
      });
    });
  }

  void _removeExperience(int index) {
    setState(() {
      _experiences.removeAt(index);
    });
  }

  void _addEducation() {
    setState(() {
      _education.add({
        'degree': '',
        'institution': '',
        'year': '',
        'description': '',
      });
    });
  }

  void _removeEducation(int index) {
    setState(() {
      _education.removeAt(index);
    });
  }

  void _addProject() {
    setState(() {
      _projects.add({
        'title': '',
        'description': '',
      });
    });
  }

  void _removeProject(int index) {
    setState(() {
      _projects.removeAt(index);
    });
  }

  void _addCertification() {
    setState(() {
      _certifications.add({
        'name': '',
        'organization': '',
        'year': '',
      });
    });
  }

  void _removeCertification(int index) {
    setState(() {
      _certifications.removeAt(index);
    });
  }

  @override
  bool get wantKeepAlive => true;

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
    _projectTitleController.dispose();
    _projectDescriptionController.dispose();
    _certificationNameController.dispose();
    _certificationOrgController.dispose();
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
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
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
            ],
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
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
      ),
    );
  }

  Widget _buildProfilePage() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
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
            Text(
              'Profile Picture',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoPage() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value!.isEmpty ? 'Name required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value!.isEmpty ? 'Email required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value!.isEmpty ? 'Phone required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkExperiencePage() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Work Experience',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _experiences.length,
              itemBuilder: (context, index) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Experience ${index + 1}'),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeExperience(index),
                            ),
                          ],
                        ),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Job Title *',
                border: OutlineInputBorder(),
              ),
                          onChanged: (value) {
                            _experiences[index]['jobTitle'] = value;
                          },
            ),
            const SizedBox(height: 10),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Company *',
                border: OutlineInputBorder(),
              ),
                          onChanged: (value) {
                            _experiences[index]['company'] = value;
                          },
            ),
            const SizedBox(height: 10),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Duration (e.g., 2020-2022)',
                border: OutlineInputBorder(),
              ),
                          onChanged: (value) {
                            _experiences[index]['duration'] = value;
                          },
            ),
            const SizedBox(height: 10),
            TextFormField(
                          maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Job Description',
                border: OutlineInputBorder(),
              ),
                          onChanged: (value) {
                            _experiences[index]['description'] = value;
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _addExperience,
              icon: const Icon(Icons.add),
              label: const Text('Add Another Experience'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationPage() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Education', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _education.length,
              itemBuilder: (context, index) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Education ${index + 1}'),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeEducation(index),
                            ),
                          ],
                        ),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Degree *',
                border: OutlineInputBorder(),
              ),
                          onChanged: (value) {
                            _education[index]['degree'] = value;
                          },
            ),
            const SizedBox(height: 10),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Institution *',
                border: OutlineInputBorder(),
              ),
                          onChanged: (value) {
                            _education[index]['institution'] = value;
                          },
            ),
            const SizedBox(height: 10),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Year of Graduation',
                border: OutlineInputBorder(),
              ),
                          onChanged: (value) {
                            _education[index]['year'] = value;
                          },
            ),
            const SizedBox(height: 10),
            TextFormField(
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
                          onChanged: (value) {
                            _education[index]['description'] = value;
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _addEducation,
              icon: const Icon(Icons.add),
              label: const Text('Add Another Education'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObjectivePage() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resume Objective',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _objectiveController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText:
                    'Summarize your career goals and what you bring to a company...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
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

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Your Skills',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                skills.map((skill) {
                  final isSelected = _selectedSkills.contains(skill);
                  return FilterChip(
                    label: Text(skill),
                    selected: isSelected,
                    onSelected: (bool selected) {
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
        ],
      ),
    );
  }

  Widget _buildProjectsPage() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Projects', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _projects.length,
              itemBuilder: (context, index) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Project ${index + 1}'),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeProject(index),
                            ),
                          ],
                        ),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Project Title *',
                border: OutlineInputBorder(),
              ),
                          onChanged: (value) {
                            _projects[index]['title'] = value;
                          },
            ),
            const SizedBox(height: 10),
            TextFormField(
                          maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
              ),
                          onChanged: (value) {
                            _projects[index]['description'] = value;
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _addProject,
              icon: const Icon(Icons.add),
              label: const Text('Add Another Project'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificationsPage() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Certifications',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _certifications.length,
              itemBuilder: (context, index) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Certification ${index + 1}'),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeCertification(index),
                            ),
                          ],
                        ),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Certification Name *',
                border: OutlineInputBorder(),
              ),
                          onChanged: (value) {
                            _certifications[index]['name'] = value;
                          },
            ),
            const SizedBox(height: 10),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Issuing Organization *',
                border: OutlineInputBorder(),
              ),
                          onChanged: (value) {
                            _certifications[index]['organization'] = value;
                          },
            ),
            const SizedBox(height: 10),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Year Obtained',
                border: OutlineInputBorder(),
              ),
                          onChanged: (value) {
                            _certifications[index]['year'] = value;
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _addCertification,
              icon: const Icon(Icons.add),
              label: const Text('Add Another Certification'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHobbiesPage() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Hobbies', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          TextFormField(
            controller: _hobbiesController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'List your hobbies like reading, traveling, coding...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
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

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Languages You Know',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                languages.map((lang) {
                  final isSelected = _selectedLanguages.contains(lang);
                  return FilterChip(
                    label: Text(lang),
                    selected: isSelected,
                    onSelected: (bool selected) {
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
        ],
      ),
    );
  }

  Widget _buildPersonalInfoPage() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _dobController,
              decoration: const InputDecoration(
                labelText: 'Date of Birth',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
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
                  _dobController.text =
                      "${date.day}/${date.month}/${date.year}";
                }
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nationalityController,
              decoration: const InputDecoration(
                labelText: 'Nationality',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Text('Gender', style: Theme.of(context).textTheme.labelLarge),
            Row(
              children: [
                Radio<String>(
                  value: 'Male',
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                ),
                const Text('Male'),
                Radio<String>(
                  value: 'Female',
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                ),
                const Text('Female'),
                Radio<String>(
                  value: 'Other',
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                ),
                const Text('Other'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
