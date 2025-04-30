import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:resume_master/services/pdf_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class ResumePreview extends StatefulWidget {
  final Map<String, dynamic> resumeData;

  const ResumePreview({super.key, required this.resumeData});

  @override
  State<ResumePreview> createState() => _ResumePreviewState();
}

class _ResumePreviewState extends State<ResumePreview> {
  bool _isGeneratingPDF = false;

  Future<void> _downloadAndSharePDF() async {
    if (!mounted) return;

    setState(() {
      _isGeneratingPDF = true;
    });

    try {
      // Generate PDF
      final pdfFile = await PDFService.generateResumePDF(widget.resumeData);

      if (!mounted) return;

      // Share the PDF using share_plus
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: 'My Resume',
        subject: 'Resume PDF', // optional subject
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Preview'),
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
              icon: const Icon(Icons.download),
              onPressed: _downloadAndSharePDF,
              tooltip: 'Download PDF',
            ),
        ],
      ),
      body: SingleChildScrollView(
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
                    widget.resumeData['personalInfo']['fullName'] ?? '',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.resumeData['personalInfo']['email'] ?? '',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    widget.resumeData['personalInfo']['phone'] ?? '',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    widget.resumeData['personalInfo']['address'] ?? '',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (widget.resumeData['personalInfo']['dateOfBirth'] != null)
                    Text(
                      'Date of Birth: ${widget.resumeData['personalInfo']['dateOfBirth']}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  if (widget.resumeData['personalInfo']['nationality'] != null)
                    Text(
                      'Nationality: ${widget.resumeData['personalInfo']['nationality']}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                ],
              ),
            ),

            const Divider(height: 40),

            // Professional Summary
            if (widget.resumeData['summary'] != null &&
                widget.resumeData['summary'].isNotEmpty)
              _buildSection(
                title: 'Professional Summary',
                child: Text(
                  widget.resumeData['summary'],
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),

            // Objective
            if (widget.resumeData['objective'] != null &&
                widget.resumeData['objective'].isNotEmpty)
              _buildSection(
                title: 'Objective',
                child: Text(
                  widget.resumeData['objective'],
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),

            // Work Experience
            if (widget.resumeData['experiences'] != null &&
                widget.resumeData['experiences'].isNotEmpty)
              _buildSection(
                title: 'Work Experience',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      widget.resumeData['experiences'].map<Widget>((exp) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exp['jobTitle'] ?? '',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                exp['company'] ?? '',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                exp['duration'] ?? '',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                exp['description'] ?? '',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ),

            // Education
            if (widget.resumeData['education'] != null &&
                widget.resumeData['education'].isNotEmpty)
              _buildSection(
                title: 'Education',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      widget.resumeData['education'].map<Widget>((edu) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                edu['degree'] ?? '',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                edu['institution'] ?? '',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                edu['year'] ?? '',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (edu['description'] != null &&
                                  edu['description'].isNotEmpty)
                                Text(
                                  edu['description'] ?? '',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ),

            // Projects
            if (widget.resumeData['projects'] != null &&
                widget.resumeData['projects'].isNotEmpty)
              _buildSection(
                title: 'Projects',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      widget.resumeData['projects'].map<Widget>((proj) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                proj['title'] ?? '',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                proj['description'] ?? '',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ),

            // Skills
            if (widget.resumeData['skills'] != null &&
                widget.resumeData['skills'].isNotEmpty)
              _buildSection(
                title: 'Skills',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      widget.resumeData['skills'].map<Widget>((skill) {
                        return Chip(
                          label: Text(skill),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(150),
                        );
                      }).toList(),
                ),
              ),

            // Languages
            if (widget.resumeData['languages'] != null &&
                widget.resumeData['languages'].isNotEmpty)
              _buildSection(
                title: 'Languages',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      widget.resumeData['languages'].map<Widget>((lang) {
                        return Chip(
                          label: Text(lang),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(150),
                        );
                      }).toList(),
                ),
              ),

            // Certifications
            if (widget.resumeData['certifications'] != null &&
                widget.resumeData['certifications'].isNotEmpty)
              _buildSection(
                title: 'Certifications',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      widget.resumeData['certifications'].map<Widget>((cert) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cert['name'] ?? '',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                cert['organization'] ?? '',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                cert['year'] ?? '',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ),

            // Hobbies
            if (widget.resumeData['hobbies'] != null &&
                widget.resumeData['hobbies'].isNotEmpty)
              _buildSection(
                title: 'Hobbies',
                child: Text(
                  widget.resumeData['hobbies'],
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}
