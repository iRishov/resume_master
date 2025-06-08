import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:resume_master/services/pdf_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import 'package:resume_master/models/resume.dart';
import 'package:resume_master/models/experience.dart';
import 'package:resume_master/models/education.dart';
import 'package:resume_master/models/project.dart';
import 'package:resume_master/models/certification.dart';
import 'dart:async';

class ResumePreview extends StatefulWidget {
  final Resume resume;

  const ResumePreview({super.key, required this.resume});

  @override
  State<ResumePreview> createState() => _ResumePreviewState();
}

class _ResumePreviewState extends State<ResumePreview> {
  bool _isGeneratingPDF = false;
  final bool _isLoading = false;
  String? _errorMessage;

  // Helper to get first name or default
  String _getFirstName(String? fullName) {
    if (fullName == null || fullName.isEmpty) {
      return 'User';
    }
    final names = fullName.trim().split(' ');
    return names.isNotEmpty ? names.first : 'User';
  }

  Future<void> _sharePDF() async {
    if (!mounted) return;
    setState(() {
      _isGeneratingPDF = true;
      _errorMessage = null;
    });
    try {
      // Generate PDF bytes in memory using the model
      final Uint8List pdfBytes = await PDFService.generateResumePDFModel(
        widget.resume,
      );
      // Create filename based on first name
      final firstName = _getFirstName(
        widget.resume.personalInfo['fullName'] as String?,
      );
      final filename = '${firstName.toLowerCase()}_resume.pdf';
      // Write to a temp file for sharing
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(pdfBytes, flush: true);
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My Resume',
        subject: 'Resume PDF',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error generating PDF: ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _sharePDF,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPDF = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final resume = widget.resume;
    final personalInfo = resume.personalInfo;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Resume Preview',
          style: TextStyle(
            fontFamily: 'CrimsonText',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isGeneratingPDF)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _sharePDF,
              tooltip: 'Share PDF',
            ),
        ],
      ),
      body: Stack(
        children: [
          if (_errorMessage != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                      });
                    },
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            )
          else
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personal Information Section
                  _buildSection(
                    title: 'Personal Information',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          personalInfo['fullName'] ?? '',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          icon: Icons.email,
                          text: personalInfo['email'] ?? '',
                        ),
                        _buildInfoRow(
                          icon: Icons.phone,
                          text: personalInfo['phone'] ?? '',
                        ),
                        _buildInfoRow(
                          icon: Icons.location_on,
                          text: personalInfo['address'] ?? '',
                        ),
                        if ((personalInfo['linkedin'] ?? '')
                            .toString()
                            .isNotEmpty)
                          _buildInfoRow(
                            icon: Icons.link,
                            text: 'LinkedIn: ${personalInfo['linkedin']}',
                          ),
                        if ((personalInfo['dateOfBirth'] ?? '')
                            .toString()
                            .isNotEmpty)
                          _buildInfoRow(
                            icon: Icons.calendar_today,
                            text:
                                'Date of Birth: ${personalInfo['dateOfBirth']}',
                          ),
                        if ((personalInfo['nationality'] ?? '')
                            .toString()
                            .isNotEmpty)
                          _buildInfoRow(
                            icon: Icons.public,
                            text: 'Nationality: ${personalInfo['nationality']}',
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 40),
                  if (resume.summary.isNotEmpty)
                    _buildSection(
                      title: 'Professional Summary',
                      child: Text(
                        resume.summary,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  if (resume.objective.isNotEmpty)
                    _buildSection(
                      title: 'Objective',
                      child: Text(
                        resume.objective,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  if (resume.experiences.isNotEmpty)
                    _buildSection(
                      title: 'Work Experience',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            resume.experiences.map((exp) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exp.jobTitle,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      exp.company,
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                    ),
                                    Text(
                                      exp.duration,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      exp.description,
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  if (resume.education.isNotEmpty)
                    _buildSection(
                      title: 'Education',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            resume.education.map((edu) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      edu.degree,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      edu.institution,
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                    ),
                                    Text(
                                      edu.year,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Colors.grey[600]),
                                    ),
                                    if (edu.description.isNotEmpty)
                                      Text(
                                        edu.description,
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyLarge,
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  if (resume.skills.isNotEmpty)
                    _buildSection(
                      title: 'Skills',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            resume.skills.map((skill) {
                              return Chip(
                                label: Text(skill),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1),
                                labelStyle: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  if (resume.languages.isNotEmpty)
                    _buildSection(
                      title: 'Languages',
                      child: Text(
                        resume.languages.join(', '),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  if (resume.projects.isNotEmpty)
                    _buildSection(
                      title: 'Projects',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            resume.projects.map((proj) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      proj.title,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      proj.description,
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  if (resume.certifications.isNotEmpty)
                    _buildSection(
                      title: 'Certifications',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            resume.certifications.map((cert) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cert.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      cert.organization,
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                    ),
                                    Text(
                                      cert.year,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  if (resume.hobbies.isNotEmpty)
                    _buildSection(
                      title: 'Hobbies & Interests',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            resume.hobbies
                                .split(',')
                                .map((hobby) => hobby.trim())
                                .where((hobby) => hobby.isNotEmpty)
                                .map(
                                  (hobby) => Chip(
                                    label: Text(
                                      hobby,
                                      style: TextStyle(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                      ),
                                    ),
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.secondary.withOpacity(0.1),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                ],
              ),
            ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        child,
        const SizedBox(height: 24),
      ],
    );
  }
}
