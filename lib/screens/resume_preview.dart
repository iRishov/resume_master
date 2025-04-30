import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ResumePreview extends StatelessWidget {
  final Map<String, dynamic> resumeData;

  const ResumePreview({super.key, required this.resumeData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              // TODO: Implement print functionality
            },
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
                    '${resumeData['firstName']} ${resumeData['lastName']}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    resumeData['email'] ?? '',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    resumeData['phone'] ?? '',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    resumeData['address'] ?? '',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),

            const Divider(height: 40),

            // Professional Summary
            if (resumeData['summary'] != null &&
                resumeData['summary'].isNotEmpty)
              _buildSection(
                title: 'Professional Summary',
                child: Text(
                  resumeData['summary'],
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),

            // Work Experience
            if (resumeData['experience'] != null &&
                resumeData['experience'].isNotEmpty)
              _buildSection(
                title: 'Work Experience',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      (resumeData['experience'] as List).map((exp) {
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
                                '${_formatDate(exp['startDate'])} - ${_formatDate(exp['endDate'])}',
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
            if (resumeData['education'] != null &&
                resumeData['education'].isNotEmpty)
              _buildSection(
                title: 'Education',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      (resumeData['education'] as List).map((edu) {
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
                                '${_formatDate(edu['startDate'])} - ${_formatDate(edu['endDate'])}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ),

            // Skills
            if (resumeData['skills'] != null && resumeData['skills'].isNotEmpty)
              _buildSection(
                title: 'Skills',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      (resumeData['skills'] as List).map((skill) {
                        return Chip(
                          label: Text(skill),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(150),
                        );
                      }).toList(),
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

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'Present';
    try {
      final dateTime = DateTime.parse(date);
      return DateFormat('MMM yyyy').format(dateTime);
    } catch (e) {
      return date;
    }
  }
}
