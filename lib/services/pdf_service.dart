import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class PDFService {
  // Layout constants
  static const double _pageMargin = 40.0;
  static const double _sectionSpacing = 15.0;
  static const double _contentSpacing = 8.0;
  static const double _titleFontSize = 20.0;
  static const double _sectionTitleFontSize = 16.0;
  static const double _contentFontSize = 10.0;
  static const double _subtitleFontSize = 12.0;
  static const double _paragraphSpacing = 12.0;

  // Colors - using only black and white
  static const PdfColor _textColor = PdfColor.fromInt(
    0xFF000000,
  ); // Black for all text
  static const PdfColor _dividerColor = PdfColor.fromInt(
    0xFF666666,
  ); // Darker grey for dividers

  static Future<File> generateResumePDF(Map<String, dynamic> resumeData) async {
    final pdf = pw.Document();

    final headerStyle = pw.TextStyle(
      fontSize: _titleFontSize,
      fontWeight: pw.FontWeight.bold,
      color: _textColor,
      letterSpacing: 0.1,
    );
    final subheaderStyle = pw.TextStyle(
      fontSize: _subtitleFontSize,
      fontWeight: pw.FontWeight.bold,
      color: _textColor,
      letterSpacing: 0.1,
    );
    final sectionStyle = pw.TextStyle(
      fontSize: _sectionTitleFontSize,
      fontWeight: pw.FontWeight.bold,
      color: _textColor,
      letterSpacing: 0.1,
    );
    final bodyStyle = pw.TextStyle(
      fontSize: _contentFontSize,
      color: _textColor,
      lineSpacing: 1.1,
      letterSpacing: 0.05,
    );

    pw.Widget sectionDivider() => pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Divider(thickness: 1.0, color: _dividerColor, height: 1),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(_pageMargin),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Text(
                resumeData['personalInfo']['fullName'] ?? '',
                style: headerStyle,
              ),
              pw.SizedBox(height: _contentSpacing),
              pw.Text(
                [
                  resumeData['personalInfo']['email'] ?? '',
                  resumeData['personalInfo']['phone'] ?? '',
                  resumeData['personalInfo']['address'] ?? '',
                  if (resumeData['personalInfo']['linkedin']?.isNotEmpty ??
                      false)
                    'LinkedIn: ${resumeData['personalInfo']['linkedin']}',
                  if (resumeData['personalInfo']['nationality']?.isNotEmpty ??
                      false)
                    'Nationality: ${resumeData['personalInfo']['nationality']}',
                  if (resumeData['personalInfo']['dateOfBirth']?.isNotEmpty ??
                      false)
                    'DOB: ${resumeData['personalInfo']['dateOfBirth']}',
                ].where((item) => item.isNotEmpty).join(' | '),
                style: bodyStyle,
              ),
              pw.SizedBox(height: _sectionSpacing),
              sectionDivider(),

              // Summary
              if (resumeData['summary']?.isNotEmpty ?? false) ...[
                pw.SizedBox(height: _sectionSpacing),
                pw.Text('Summary', style: sectionStyle),
                pw.SizedBox(height: _contentSpacing),
                pw.Text(resumeData['summary'], style: bodyStyle),
                pw.SizedBox(height: _paragraphSpacing),
                sectionDivider(),
              ],

              // Work Experience
              if (resumeData['experiences']?.isNotEmpty ?? false) ...[
                pw.SizedBox(height: _sectionSpacing),
                pw.Text('Work Experience', style: sectionStyle),
                pw.SizedBox(height: _contentSpacing),
                ...resumeData['experiences'].map<pw.Widget>((exp) {
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(exp['jobTitle'] ?? '', style: subheaderStyle),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "${exp['company'] ?? ''} | ${exp['duration'] ?? ''}",
                        style: bodyStyle,
                      ),
                      if (exp['description'] != null &&
                          exp['description'].isNotEmpty) ...[
                        pw.SizedBox(height: 8),
                        pw.Text(exp['description'], style: bodyStyle),
                        pw.SizedBox(height: _paragraphSpacing),
                      ],
                      pw.SizedBox(height: _contentSpacing),
                    ],
                  );
                }).toList(),
                sectionDivider(),
              ],

              // Education
              if (resumeData['education']?.isNotEmpty ?? false) ...[
                pw.SizedBox(height: _sectionSpacing),
                pw.Text('Education', style: sectionStyle),
                pw.SizedBox(height: _contentSpacing),
                ...resumeData['education'].map<pw.Widget>((edu) {
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(edu['degree'] ?? '', style: subheaderStyle),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "${edu['institution'] ?? ''} | ${edu['year'] ?? ''}",
                        style: bodyStyle,
                      ),
                      if (edu['description']?.isNotEmpty ?? false) ...[
                        pw.SizedBox(height: 8),
                        pw.Text(edu['description'], style: bodyStyle),
                        pw.SizedBox(height: _paragraphSpacing),
                      ],
                      pw.SizedBox(height: _contentSpacing),
                    ],
                  );
                }).toList(),
                sectionDivider(),
              ],

              // Skills
              if (resumeData['skills']?.isNotEmpty ?? false) ...[
                pw.SizedBox(height: _sectionSpacing),
                pw.Text('Skills', style: sectionStyle),
                pw.SizedBox(height: _contentSpacing),
                pw.Text(resumeData['skills'].join(', '), style: bodyStyle),
                pw.SizedBox(height: _paragraphSpacing),
                sectionDivider(),
              ],

              // Languages
              if (resumeData['languages']?.isNotEmpty ?? false) ...[
                pw.SizedBox(height: _sectionSpacing),
                pw.Text('Languages', style: sectionStyle),
                pw.SizedBox(height: _contentSpacing),
                pw.Text(resumeData['languages'].join(', '), style: bodyStyle),
                pw.SizedBox(height: _paragraphSpacing),
                sectionDivider(),
              ],

              // Projects
              if (resumeData['projects']?.isNotEmpty ?? false) ...[
                pw.SizedBox(height: _sectionSpacing),
                pw.Text('Projects', style: sectionStyle),
                pw.SizedBox(height: _contentSpacing),
                ...resumeData['projects'].map<pw.Widget>((proj) {
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(proj['title'] ?? '', style: subheaderStyle),
                      if (proj['description']?.isNotEmpty ?? false) ...[
                        pw.SizedBox(height: 8),
                        pw.Text(proj['description'], style: bodyStyle),
                        pw.SizedBox(height: _paragraphSpacing),
                      ],
                      pw.SizedBox(height: _contentSpacing),
                    ],
                  );
                }).toList(),
                sectionDivider(),
              ],

              // Certifications
              if (resumeData['certifications']?.isNotEmpty ?? false) ...[
                pw.SizedBox(height: _sectionSpacing),
                pw.Text('Certifications', style: sectionStyle),
                pw.SizedBox(height: _contentSpacing),
                ...resumeData['certifications'].map<pw.Widget>((cert) {
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(cert['name'] ?? '', style: subheaderStyle),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "${cert['organization'] ?? ''} | ${cert['year'] ?? ''}",
                        style: bodyStyle,
                      ),
                      pw.SizedBox(height: _paragraphSpacing),
                    ],
                  );
                }).toList(),
                sectionDivider(),
              ],
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/resume.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static List<Map<String, String>> _validateAndSanitizeEducation(
    dynamic education,
  ) {
    if (education == null) return [];
    if (education is! List) return [];

    return education
        .where((edu) => edu != null && edu is Map)
        .map((edu) {
          final map = edu as Map<String, dynamic>;
          return {
            'degree': map['degree']?.toString().trim() ?? '',
            'institution': map['institution']?.toString().trim() ?? '',
            'year': map['year']?.toString().trim() ?? '',
            'description': map['description']?.toString().trim() ?? '',
          };
        })
        .where(
          (edu) =>
              edu['degree']!.isNotEmpty &&
              edu['institution']!.isNotEmpty &&
              edu['year']!.isNotEmpty,
        )
        .toList();
  }

  static List<Map<String, String>> _validateAndSanitizeExperiences(
    dynamic experiences,
  ) {
    if (experiences == null) return [];
    if (experiences is! List) return [];

    return experiences
        .where((exp) => exp != null && exp is Map)
        .map((exp) {
          final map = exp as Map<String, dynamic>;
          return {
            'jobTitle': map['jobTitle']?.toString().trim() ?? '',
            'company': map['company']?.toString().trim() ?? '',
            'duration': map['duration']?.toString().trim() ?? '',
            'description': map['description']?.toString().trim() ?? '',
          };
        })
        .where(
          (exp) =>
              exp['jobTitle']!.isNotEmpty ||
              exp['company']!.isNotEmpty ||
              exp['duration']!.isNotEmpty ||
              exp['description']!.isNotEmpty,
        )
        .toList();
  }

  static List<String> _validateAndSanitizeSkills(dynamic skills) {
    if (skills == null) return [];
    if (skills is! List) return [];

    return skills
        .where((skill) => skill != null)
        .map((skill) => skill.toString().trim())
        .where((skill) => skill.isNotEmpty)
        .toList();
  }

  static List<String> _validateAndSanitizeLanguages(dynamic languages) {
    if (languages == null) return [];
    if (languages is! List) return [];

    return languages
        .where((language) => language != null)
        .map((language) => language.toString().trim())
        .where((language) => language.isNotEmpty)
        .toList();
  }

  static List<Map<String, String>> _validateAndSanitizeProjects(
    dynamic projects,
  ) {
    if (projects == null) return [];
    if (projects is! List) return [];

    return projects
        .where((proj) => proj != null && proj is Map)
        .map((proj) {
          final map = proj as Map<String, dynamic>;
          return {
            'title': map['title']?.toString().trim() ?? '',
            'description': map['description']?.toString().trim() ?? '',
          };
        })
        .where(
          (proj) =>
              proj['title']!.isNotEmpty && proj['description']!.isNotEmpty,
        )
        .toList();
  }

  static List<Map<String, String>> _validateAndSanitizeCertifications(
    dynamic certifications,
  ) {
    if (certifications == null) return [];
    if (certifications is! List) return [];

    return certifications
        .where((cert) => cert != null && cert is Map)
        .map((cert) {
          final map = cert as Map<String, dynamic>;
          return {
            'name': map['name']?.toString().trim() ?? '',
            'organization': map['organization']?.toString().trim() ?? '',
            'year': map['year']?.toString().trim() ?? '',
          };
        })
        .where(
          (cert) =>
              cert['name']!.isNotEmpty &&
              cert['organization']!.isNotEmpty &&
              cert['year']!.isNotEmpty,
        )
        .toList();
  }

  static pw.Widget _buildHeaderSection(Map<String, dynamic> personalInfo) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          personalInfo['fullName']?.toString().trim() ?? '',
          style: pw.TextStyle(
            fontSize: _titleFontSize,
            fontWeight: pw.FontWeight.bold,
            color: _textColor,
            letterSpacing: 0.1,
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Text(
          [
            personalInfo['email']?.toString().trim() ?? '',
            personalInfo['phone']?.toString().trim() ?? '',
            personalInfo['address']?.toString().trim() ?? '',
            if (personalInfo['linkedin']?.toString().trim().isNotEmpty ?? false)
              'LinkedIn: ${personalInfo['linkedin'].toString().trim()}',
            if (personalInfo['nationality']?.toString().trim().isNotEmpty ??
                false)
              'Nationality: ${personalInfo['nationality'].toString().trim()}',
            if (personalInfo['dateOfBirth']?.toString().trim().isNotEmpty ??
                false)
              'DOB: ${personalInfo['dateOfBirth'].toString().trim()}',
          ].where((item) => item.isNotEmpty).join(' | '),
          style: pw.TextStyle(fontSize: _contentFontSize),
        ),
      ],
    );
  }

  static pw.Widget _buildSummarySection(String summary) {
    return pw.Text(
      summary,
      style: pw.TextStyle(
        fontSize: _contentFontSize,
        color: _textColor,
        lineSpacing: 1.1,
        letterSpacing: 0.05,
      ),
    );
  }

  static pw.Widget _buildExperienceSection(
    List<Map<String, String>> experiences,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children:
          experiences.map((exp) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        exp['jobTitle'] ?? '',
                        style: pw.TextStyle(
                          fontSize: _subtitleFontSize,
                          fontWeight: pw.FontWeight.bold,
                          color: _textColor,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    pw.Text(
                      exp['duration'] ?? '',
                      style: pw.TextStyle(
                        fontSize: _contentFontSize,
                        color: _textColor,
                        letterSpacing: 0.05,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  exp['company'] ?? '',
                  style: pw.TextStyle(
                    fontSize: _contentFontSize,
                    color: _textColor,
                    letterSpacing: 0.05,
                  ),
                ),
                if (exp['description']?.isNotEmpty == true) ...[
                  pw.SizedBox(height: 12),
                  pw.Text(
                    exp['description'] ?? '',
                    style: pw.TextStyle(
                      fontSize: _contentFontSize,
                      color: _textColor,
                      lineSpacing: 1.1,
                      letterSpacing: 0.05,
                    ),
                  ),
                ],
                pw.SizedBox(height: 16),
              ],
            );
          }).toList(),
    );
  }

  static pw.Widget _buildEducationSection(List<Map<String, String>> education) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children:
          education.map((edu) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        edu['degree'] ?? '',
                        style: pw.TextStyle(
                          fontSize: _subtitleFontSize,
                          fontWeight: pw.FontWeight.bold,
                          color: _textColor,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    pw.Text(
                      edu['year'] ?? '',
                      style: pw.TextStyle(
                        fontSize: _contentFontSize,
                        color: _textColor,
                        letterSpacing: 0.05,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  edu['institution'] ?? '',
                  style: pw.TextStyle(
                    fontSize: _contentFontSize,
                    color: _textColor,
                    letterSpacing: 0.05,
                  ),
                ),
                if (edu['description']?.isNotEmpty == true) ...[
                  pw.SizedBox(height: 12),
                  pw.Text(
                    edu['description'] ?? '',
                    style: pw.TextStyle(
                      fontSize: _contentFontSize,
                      color: _textColor,
                      lineSpacing: 1.1,
                      letterSpacing: 0.05,
                    ),
                  ),
                ],
                pw.SizedBox(height: 16),
              ],
            );
          }).toList(),
    );
  }

  static pw.Widget _buildSkillsSection(List<String> skills) {
    return pw.Text(
      skills.join(', '),
      style: pw.TextStyle(
        fontSize: _contentFontSize,
        color: _textColor,
        lineSpacing: 1.1,
      ),
    );
  }

  static pw.Widget _buildProjectsSection(List<Map<String, String>> projects) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children:
          projects.map((proj) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  proj['title'] ?? '',
                  style: pw.TextStyle(
                    fontSize: _subtitleFontSize,
                    fontWeight: pw.FontWeight.bold,
                    color: _textColor,
                    letterSpacing: 0.1,
                  ),
                ),
                if (proj['description']?.isNotEmpty == true) ...[
                  pw.SizedBox(height: 8),
                  pw.Text(
                    proj['description'] ?? '',
                    style: pw.TextStyle(
                      fontSize: _contentFontSize,
                      color: _textColor,
                      lineSpacing: 1.1,
                      letterSpacing: 0.05,
                    ),
                  ),
                ],
                pw.SizedBox(height: 16),
              ],
            );
          }).toList(),
    );
  }

  static pw.Widget _buildCertificationsSection(
    List<Map<String, String>> certifications,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children:
          certifications.map((cert) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        cert['name'] ?? '',
                        style: pw.TextStyle(
                          fontSize: _subtitleFontSize,
                          fontWeight: pw.FontWeight.bold,
                          color: _textColor,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    pw.Text(
                      cert['year'] ?? '',
                      style: pw.TextStyle(
                        fontSize: _contentFontSize,
                        color: _textColor,
                        letterSpacing: 0.05,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  cert['organization'] ?? '',
                  style: pw.TextStyle(
                    fontSize: _contentFontSize,
                    color: _textColor,
                    letterSpacing: 0.05,
                  ),
                ),
                pw.SizedBox(height: 16),
              ],
            );
          }).toList(),
    );
  }

  static pw.Widget _buildLanguagesSection(List<String> languages) {
    return pw.Text(
      languages.join(', '),
      style: pw.TextStyle(
        fontSize: _contentFontSize,
        color: _textColor,
        lineSpacing: 1.1,
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title.toUpperCase(),
      style: pw.TextStyle(
        fontSize: _sectionTitleFontSize,
        fontWeight: pw.FontWeight.bold,
        color: _textColor,
        letterSpacing: 0.5,
      ),
    );
  }

  static Future<Uint8List> generateResumePDFBytes(
    Map<String, dynamic> resumeData,
  ) async {
    try {
      debugPrint('Starting PDF generation with data: $resumeData');

      // Validate required fields
      if (resumeData['personalInfo'] == null) {
        throw Exception('Personal information is required');
      }

      final personalInfo = resumeData['personalInfo'] as Map<String, dynamic>;
      debugPrint('Personal info: $personalInfo');

      if (personalInfo['fullName'] == null ||
          personalInfo['fullName'].toString().trim().isEmpty) {
        throw Exception('Full name is required');
      }

      // Create PDF document
      final pdf = pw.Document();

      // Add pages
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(_pageMargin),
          build: (context) {
            final sections = <pw.Widget>[];

            try {
              // Header section with contact info
              sections.add(_buildHeaderSection(personalInfo));
              sections.add(pw.SizedBox(height: _sectionSpacing));

              // Summary
              final summary = resumeData['summary']?.toString().trim();
              if (summary != null && summary.isNotEmpty) {
                sections.add(_buildSectionTitle('Summary'));
                sections.add(_buildSummarySection(summary));
                sections.add(pw.SizedBox(height: _sectionSpacing));
              }

              // Work Experience
              final experiences = _validateAndSanitizeExperiences(
                resumeData['experiences'],
              );
              if (experiences.isNotEmpty) {
                sections.add(_buildSectionTitle('Experience'));
                sections.add(_buildExperienceSection(experiences));
                sections.add(pw.SizedBox(height: _sectionSpacing));
              }

              // Education
              final education = _validateAndSanitizeEducation(
                resumeData['education'],
              );
              if (education.isNotEmpty) {
                sections.add(_buildSectionTitle('Education'));
                sections.add(_buildEducationSection(education));
                sections.add(pw.SizedBox(height: _sectionSpacing));
              }

              // Skills
              final skills = _validateAndSanitizeSkills(resumeData['skills']);
              if (skills.isNotEmpty) {
                sections.add(_buildSectionTitle('Technical Skills'));
                sections.add(_buildSkillsSection(skills));
                sections.add(pw.SizedBox(height: _sectionSpacing));
              }

              // Projects
              final projects = _validateAndSanitizeProjects(
                resumeData['projects'],
              );
              if (projects.isNotEmpty) {
                sections.add(_buildSectionTitle('Projects'));
                sections.add(_buildProjectsSection(projects));
                sections.add(pw.SizedBox(height: _sectionSpacing));
              }

              // Certifications
              final certifications = _validateAndSanitizeCertifications(
                resumeData['certifications'],
              );
              if (certifications.isNotEmpty) {
                sections.add(_buildSectionTitle('Certifications'));
                sections.add(_buildCertificationsSection(certifications));
                sections.add(pw.SizedBox(height: _sectionSpacing));
              }

              // Languages
              final languages = _validateAndSanitizeLanguages(
                resumeData['languages'],
              );
              if (languages.isNotEmpty) {
                sections.add(_buildSectionTitle('Languages'));
                sections.add(_buildLanguagesSection(languages));
              }

              return sections;
            } catch (e, stackTrace) {
              debugPrint('Error building PDF sections: $e');
              debugPrint('Stack trace: $stackTrace');
              rethrow;
            }
          },
        ),
      );

      // Return PDF bytes
      return await pdf.save();
    } catch (e, stackTrace) {
      debugPrint('Error generating PDF: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Failed to generate PDF: ${e.toString()}');
    }
  }
}
