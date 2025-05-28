import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:resume_master/services/pdf_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';

class ResumePreview extends StatefulWidget {
  final Map<String, dynamic> resumeData;

  const ResumePreview({super.key, required this.resumeData});

  @override
  State<ResumePreview> createState() => _ResumePreviewState();
}

class _ResumePreviewState extends State<ResumePreview> {
  bool _isGeneratingPDF = false;
  final bool _isLoading = false;
  String? _errorMessage;

  Future<void> _sharePDF() async {
    if (!mounted) return;
    setState(() {
      _isGeneratingPDF = true;
      _errorMessage = null;
    });
    try {
      // Generate PDF bytes in memory
      final Uint8List pdfBytes = await PDFService.generateResumePDFBytes(
        widget.resumeData,
      );
      // Write to a temp file for sharing
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/resume_share.pdf');
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

  bool _validateResumeData() {
    // Only validate personal info as it's the minimum required
    if (widget.resumeData['personalInfo'] == null ||
        widget.resumeData['personalInfo']['fullName']?.isEmpty == true) {
      _errorMessage = 'Please add your name in personal information';
      return false;
    }
    return true;
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
                    child: Text('Dismiss'),
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
                          widget.resumeData['personalInfo']['fullName'] ?? '',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          icon: Icons.email,
                          text:
                              widget.resumeData['personalInfo']['email'] ?? '',
                        ),
                        _buildInfoRow(
                          icon: Icons.phone,
                          text:
                              widget.resumeData['personalInfo']['phone'] ?? '',
                        ),
                        _buildInfoRow(
                          icon: Icons.location_on,
                          text:
                              widget.resumeData['personalInfo']['address'] ??
                              '',
                        ),
                        if (widget.resumeData['personalInfo']['linkedin'] !=
                                null &&
                            widget.resumeData['personalInfo']['linkedin']
                                .toString()
                                .isNotEmpty)
                          _buildInfoRow(
                            icon: Icons.link,
                            text:
                                'LinkedIn: ${widget.resumeData['personalInfo']['linkedin']}',
                          ),
                        if (widget.resumeData['personalInfo']['dateOfBirth'] !=
                            null)
                          _buildInfoRow(
                            icon: Icons.calendar_today,
                            text:
                                'Date of Birth: ${widget.resumeData['personalInfo']['dateOfBirth']}',
                          ),
                        if (widget.resumeData['personalInfo']['nationality'] !=
                            null)
                          _buildInfoRow(
                            icon: Icons.public,
                            text:
                                'Nationality: ${widget.resumeData['personalInfo']['nationality']}',
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
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      exp['company'] ?? '',
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                    ),
                                    Text(
                                      exp['duration'] ?? '',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      exp['description'] ?? '',
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
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
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      edu['institution'] ?? '',
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                    ),
                                    Text(
                                      edu['year'] ?? '',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Colors.grey[600]),
                                    ),
                                    if (edu['description'] != null &&
                                        edu['description'].isNotEmpty)
                                      Text(
                                        edu['description'] ?? '',
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
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      proj['description'] ?? '',
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
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
                            (widget.resumeData['skills'] as List)
                                .map<Widget>(
                                  (skill) => Chip(
                                    label: Text(skill.toString()),
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.1),
                                    labelStyle: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                )
                                .toList(),
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
                            (widget.resumeData['languages'] as List)
                                .map<Widget>(
                                  (lang) => Chip(
                                    label: Text(lang.toString()),
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.secondary.withOpacity(0.1),
                                    labelStyle: TextStyle(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                    ),
                                  ),
                                )
                                .toList(),
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
                            widget.resumeData['certifications'].map<Widget>((
                              cert,
                            ) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cert['name'] ?? '',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      cert['organization'] ?? '',
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                    ),
                                    Text(
                                      cert['year'] ?? '',
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

                  // Hobbies
                  if (widget.resumeData['hobbies'] != null &&
                      widget.resumeData['hobbies'].isNotEmpty)
                    _buildSection(
                      title: 'Hobbies & Interests',
                      child: Text(
                        widget.resumeData['hobbies'],
                        style: Theme.of(context).textTheme.bodyLarge,
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
