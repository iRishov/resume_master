import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resume_master/services/auth_service.dart';

class RecruiterProfile extends StatefulWidget {
  const RecruiterProfile({super.key});

  @override
  State<RecruiterProfile> createState() => _RecruiterProfileState();
}

class _RecruiterProfileState extends State<RecruiterProfile> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _positionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isProfileLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          final data = userDoc.data();
          if (mounted) {
            setState(() {
              _nameController.text = data?['name'] ?? '';
              _companyController.text = data?['company'] ?? '';
              _positionController.text = data?['position'] ?? '';
              _phoneController.text =
                  data?['phone'] ??
                  data?['phoneNumber'] ??
                  data?['mobile'] ??
                  data?['mobileNumber'] ??
                  data?['contact'] ??
                  data?['contactNumber'] ??
                  '';
              _isProfileLoaded = true;
            });
          }
        }

        // Debug print to check the data
        debugPrint('Loaded profile data: ${userDoc.data()}');
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = _authService.currentUser;
        if (user != null) {
          // Update in users collection instead of recruiters
          await _firestore.collection('users').doc(user.uid).update({
            'name': _nameController.text,
            'company': _companyController.text,
            'position': _positionController.text,
            'phone': _phoneController.text,
            'phoneNumber': _phoneController.text,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
            setState(() {
              _isEditing = false;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating profile: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _signOut() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/startup');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _positionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading && !_isProfileLoaded
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 120.0,
                    floating: false,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                      title: Text(
                        'Profile',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).primaryColorDark,
                              Theme.of(context).colorScheme.primary,
                            ],
                          ),
                        ),
                      ),
                    ),
                    elevation: 0,
                    actions: [
                      if (!_isEditing)
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: 'Edit Profile',
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                        ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Information Card
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person_outline,
                                          color: Theme.of(context).primaryColor,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Personal Information',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    if (!_isEditing) ...[
                                      _buildInfoRow(
                                        'Name',
                                        _nameController.text,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildInfoRow(
                                        'Position',
                                        _positionController.text,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildInfoRow(
                                        'Company',
                                        _companyController.text,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildInfoRow(
                                        'Phone',
                                        _phoneController.text,
                                      ),
                                    ] else ...[
                                      _buildTextField(
                                        controller: _nameController,
                                        label: 'Full Name',
                                        icon: Icons.person_outline,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your name';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        controller: _positionController,
                                        label: 'Position',
                                        icon: Icons.work_outline,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your position';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        controller: _companyController,
                                        label: 'Company',
                                        icon: Icons.business,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your company name';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        controller: _phoneController,
                                        label: 'Phone Number',
                                        icon: Icons.phone_outlined,
                                        keyboardType: TextInputType.phone,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your phone number';
                                          }
                                          // Basic phone number validation
                                          if (!RegExp(
                                            r'^\+?[\d\s-]{10,}$',
                                          ).hasMatch(value)) {
                                            return 'Please enter a valid phone number';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Action Buttons
                            if (_isEditing) ...[
                              _buildButton(
                                onPressed: _isLoading ? null : _saveProfile,
                                icon:
                                    _isLoading
                                        ? Icons.hourglass_empty
                                        : Icons.save,
                                label:
                                    _isLoading ? 'Saving...' : 'Save Changes',
                                isPrimary: true,
                                isLoading: _isLoading,
                              ),
                              const SizedBox(height: 16),
                              _buildButton(
                                onPressed:
                                    _isLoading
                                        ? null
                                        : () {
                                          setState(() {
                                            _isEditing = false;
                                            _loadProfile();
                                          });
                                        },
                                icon: Icons.cancel,
                                label: 'Cancel',
                                isPrimary: false,
                              ),
                            ],

                            const SizedBox(height: 32),
                            const Divider(),
                            const SizedBox(height: 16),

                            // Logout Button
                            _buildButton(
                              onPressed: _signOut,
                              icon: Icons.logout,
                              label: 'Logout',
                              isPrimary: true,
                              backgroundColor: Colors.red,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator,
    );
  }

  Widget _buildButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
    bool isLoading = false,
    Color? backgroundColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              backgroundColor ??
              (isPrimary ? Theme.of(context).primaryColor : Colors.white),
          foregroundColor:
              isPrimary ? Colors.white : Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side:
                isPrimary
                    ? BorderSide.none
                    : BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 1,
                    ),
          ),
          elevation: isPrimary ? 2 : 0,
        ),
        icon:
            isLoading
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isPrimary ? Colors.white : Theme.of(context).primaryColor,
                    ),
                  ),
                )
                : Icon(icon),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isPrimary ? Colors.white : Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }
}
