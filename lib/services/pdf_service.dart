import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../models/resume.dart';
import '../models/experience.dart'; // Import Experience model
import '../models/education.dart'; // Import Education model
import '../models/project.dart'; // Import Project model
import '../models/certification.dart'; // Import Certification model

class PDFService {
  // Layout constants
  static const double _pageMargin = 40.0;
  static const double _sectionSpacing = 10.0;
  static const double _contentSpacing = 5.0;
  static const double _titleFontSize = 28.0;
  static const double _sectionTitleFontSize = 16.0;
  static const double _contentFontSize = 10.0;
  static const double _subtitleFontSize = 12.0;
  static const double _paragraphSpacing = 8.0;

  // Colors - using only black and white
  static const PdfColor _textColor = PdfColor.fromInt(
    0xFF000000,
  ); // Black for all text
  static const PdfColor _dividerColor = PdfColor.fromInt(
    0xFF666666,
  ); // Darker grey for dividers

  static const PdfColor _blueColor = PdfColor.fromInt(0xFF107BDF);

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
      color: _blueColor,
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
              // HeaderS
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
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              exp['company'] ?? '',
                              style: bodyStyle,
                            ),
                          ),
                          pw.Text(exp['duration'] ?? '', style: bodyStyle),
                        ],
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
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              edu['institution'] ?? '',
                              style: bodyStyle,
                            ),
                          ),
                          pw.Text(edu['year'] ?? '', style: bodyStyle),
                        ],
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
                _buildSkillsSection(resumeData['skills']),
                pw.SizedBox(height: _paragraphSpacing),
                sectionDivider(),
              ],

              // Languages
              if (resumeData['languages']?.isNotEmpty ?? false) ...[
                pw.SizedBox(height: _sectionSpacing),
                pw.Text('Languages', style: sectionStyle),
                pw.SizedBox(height: _contentSpacing),
                _buildLanguagesSection(resumeData['languages']),
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

  static Future<Uint8List> generateResumePDFModel(Resume resume) async {
    final pdf = pw.Document();

    // Styles
    final headerStyle = pw.TextStyle(
      fontSize: _titleFontSize,
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

    // Section Divider Widget
    pw.Widget sectionDivider() => pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Divider(thickness: 1.0, color: _dividerColor, height: 1),
    );

    final personalInfo = resume.personalInfo;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(_pageMargin),
        build: (context) {
          final sections = <pw.Widget>[];

          // Header section with contact info
          sections.add(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  personalInfo['fullName']?.toString().trim() ?? '',
                  style: headerStyle,
                ),
                pw.SizedBox(height: _contentSpacing),
                pw.Text(
                  [
                    personalInfo['email']?.toString().trim() ?? '',
                    personalInfo['phone']?.toString().trim() ?? '',
                    personalInfo['address']?.toString().trim() ?? '',
                    if (personalInfo['linkedin']
                            ?.toString()
                            .trim()
                            .isNotEmpty ??
                        false)
                      'LinkedIn: ${personalInfo['linkedin'].toString().trim()}',
                  ].where((item) => item.isNotEmpty).join(' | '),
                  style: bodyStyle,
                ),
              ],
            ),
          );

          // Add sections dynamically with dividers and spacing
          void addSection({
            required String title,
            required bool shouldAdd,
            required pw.Widget content,
          }) {
            if (shouldAdd) {
              // Add divider only if there are previous sections
              if (sections.isNotEmpty) {
                sections.add(pw.SizedBox(height: _sectionSpacing));
                sections.add(sectionDivider());
              }
              sections.add(pw.SizedBox(height: _sectionSpacing));
              sections.add(_buildSectionTitle(title));
              sections.add(pw.SizedBox(height: _contentSpacing));
              sections.add(content);
            }
          }

          addSection(
            title: 'Summary',
            shouldAdd: resume.summary.isNotEmpty,
            content: _buildSummarySection(resume.summary),
          );

          addSection(
            title: 'Objective',
            shouldAdd: resume.objective.isNotEmpty,
            content: _buildSummarySection(resume.objective),
          );

          addSection(
            title: 'Work Experience',
            shouldAdd: resume.experiences.isNotEmpty,
            content: _buildExperienceSection(resume.experiences),
          );

          addSection(
            title: 'Education',
            shouldAdd: resume.education.isNotEmpty,
            content: _buildEducationSection(resume.education),
          );

          addSection(
            title: 'Skills',
            shouldAdd: resume.skills.isNotEmpty,
            content: _buildSkillsSection(resume.skills),
          );

          addSection(
            title: 'Languages',
            shouldAdd: resume.languages.isNotEmpty,
            content: _buildLanguagesSection(resume.languages),
          );

          addSection(
            title: 'Projects',
            shouldAdd: resume.projects.isNotEmpty,
            content: _buildProjectsSection(resume.projects),
          );

          addSection(
            title: 'Certifications',
            shouldAdd: resume.certifications.isNotEmpty,
            content: _buildCertificationsSection(resume.certifications),
          );

          return sections;
        },
      ),
    );
    return pdf.save();
  }

  // Helper methods for building sections

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
        pw.SizedBox(height: _contentSpacing),
        pw.Text(
          [
            personalInfo['email']?.toString().trim() ?? '',
            personalInfo['phone']?.toString().trim() ?? '',
            personalInfo['address']?.toString().trim() ?? '',
            if (personalInfo['linkedin']?.toString().trim().isNotEmpty ?? false)
              'LinkedIn: ${personalInfo['linkedin'].toString().trim()}',
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

  static pw.Widget _buildExperienceSection(List<Experience> experiences) {
    List<pw.Widget> experienceRows = [];
    for (int i = 0; i < experiences.length; i += 2) {
      List<pw.Widget> rowChildren = [];

      // First item in the row
      rowChildren.add(
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Arrange Job Title and Duration in a Row
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      experiences[i].jobTitle, // Job Title on the left
                      style: pw.TextStyle(
                        fontSize: _subtitleFontSize,
                        fontWeight: pw.FontWeight.bold,
                        color: _textColor,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  pw.Text(
                    experiences[i].duration, // Duration on the right
                    style: pw.TextStyle(
                      fontSize: _contentFontSize,
                      color: _textColor,
                      letterSpacing: 0.05,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(
                height: 4,
              ), // Spacing between title/duration and company
              // Company below the title/duration row
              pw.Text(
                experiences[i].company,
                style: pw.TextStyle(
                  fontSize: _contentFontSize,
                  color: _textColor,
                  letterSpacing: 0.05,
                ),
              ),
              if (experiences[i].description.isNotEmpty) ...[
                // Use isNotEmpty
                pw.SizedBox(height: 8), // Spacing before description
                pw.Text(
                  experiences[i].description,
                  style: pw.TextStyle(
                    fontSize: _contentFontSize,
                    color: _textColor,
                    lineSpacing: 1.1,
                    letterSpacing: 0.05,
                  ),
                ),
              ],
            ],
          ),
        ),
      );

      // Second item in the row (if exists)
      if (i + 1 < experiences.length) {
        rowChildren.add(pw.SizedBox(width: 16)); // Spacing between columns
        rowChildren.add(
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Arrange Job Title and Duration in a Row
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        experiences[i + 1].jobTitle, // Job Title on the left
                        style: pw.TextStyle(
                          fontSize: _subtitleFontSize,
                          fontWeight: pw.FontWeight.bold,
                          color: _textColor,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    pw.Text(
                      experiences[i + 1].duration, // Duration on the right
                      style: pw.TextStyle(
                        fontSize: _contentFontSize,
                        color: _textColor,
                        letterSpacing: 0.05,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(
                  height: 4,
                ), // Spacing between title/duration and company
                // Company below the title/duration row
                pw.Text(
                  experiences[i + 1].company,
                  style: pw.TextStyle(
                    fontSize: _contentFontSize,
                    color: _textColor,
                    letterSpacing: 0.05,
                  ),
                ),
                if (experiences[i + 1].description.isNotEmpty) ...[
                  // Use isNotEmpty
                  pw.SizedBox(height: 8), // Spacing before description
                  pw.Text(
                    experiences[i + 1].description,
                    style: pw.TextStyle(
                      fontSize: _contentFontSize,
                      color: _textColor,
                      lineSpacing: 1.1,
                      letterSpacing: 0.05,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      } else {
        // Add an empty Expanded to balance the row if there's only one item
        rowChildren.add(pw.Expanded(child: pw.Container()));
      }

      experienceRows.add(
        pw.Padding(
          padding:
              i == 0
                  ? pw.EdgeInsets.zero
                  : const pw.EdgeInsets.only(
                    top: _paragraphSpacing,
                  ), // Add spacing between rows of entries
          child: pw.Row(children: rowChildren),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: experienceRows,
    );
  }

  static pw.Widget _buildEducationSection(List<Education> education) {
    List<pw.Widget> educationRows = [];
    for (int i = 0; i < education.length; i += 2) {
      List<pw.Widget> rowChildren = [];

      // First item in the row
      rowChildren.add(
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Arrange Degree and Year in a Row
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      education[i].degree, // Degree on the left
                      style: pw.TextStyle(
                        fontSize: _subtitleFontSize,
                        fontWeight: pw.FontWeight.bold,
                        color: _textColor,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  pw.Text(
                    education[i].year, // Year on the right
                    style: pw.TextStyle(
                      fontSize: _contentFontSize,
                      color: _textColor,
                      letterSpacing: 0.05,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(
                height: 4,
              ), // Spacing between degree/year and institution
              // Institution below the degree/year row
              pw.Text(
                education[i].institution,
                style: pw.TextStyle(
                  fontSize: _contentFontSize,
                  color: _textColor,
                  letterSpacing: 0.05,
                ),
              ),
              if (education[i].description.isNotEmpty) ...[
                // Use isNotEmpty
                pw.SizedBox(height: 8), // Spacing before description
                pw.Text(
                  education[i].description,
                  style: pw.TextStyle(
                    fontSize: _contentFontSize,
                    color: _textColor,
                    lineSpacing: 1.1,
                    letterSpacing: 0.05,
                  ),
                ),
              ],
            ],
          ),
        ),
      );

      // Second item in the row (if exists)
      if (i + 1 < education.length) {
        rowChildren.add(pw.SizedBox(width: 16)); // Spacing between columns
        rowChildren.add(
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Arrange Degree and Year in a Row
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        education[i + 1].degree, // Degree on the left
                        style: pw.TextStyle(
                          fontSize: _subtitleFontSize,
                          fontWeight: pw.FontWeight.bold,
                          color: _textColor,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    pw.Text(
                      education[i + 1].year, // Year on the right
                      style: pw.TextStyle(
                        fontSize: _contentFontSize,
                        color: _textColor,
                        letterSpacing: 0.05,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(
                  height: 4,
                ), // Spacing between degree/year and institution
                // Institution below the degree/year row
                pw.Text(
                  education[i + 1].institution,
                  style: pw.TextStyle(
                    fontSize: _contentFontSize,
                    color: _textColor,
                    letterSpacing: 0.05,
                  ),
                ),
                if (education[i + 1].description.isNotEmpty) ...[
                  // Use isNotEmpty
                  pw.SizedBox(height: 8), // Spacing before description
                  pw.Text(
                    education[i + 1].description,
                    style: pw.TextStyle(
                      fontSize: _contentFontSize,
                      color: _textColor,
                      lineSpacing: 1.1,
                      letterSpacing: 0.05,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      } else {
        // Add an empty Expanded to balance the row if there's only one item
        rowChildren.add(pw.Expanded(child: pw.Container()));
      }

      educationRows.add(
        pw.Padding(
          padding:
              i == 0
                  ? pw.EdgeInsets.zero
                  : const pw.EdgeInsets.only(
                    top: _paragraphSpacing,
                  ), // Add spacing between rows of entries
          child: pw.Row(children: rowChildren),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: educationRows,
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

  static pw.Widget _buildProjectsSection(List<Project> projects) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        ...projects.asMap().entries.map((entry) {
          final index = entry.key;
          final proj = entry.value;
          final isLast = index == projects.length - 1;
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                proj.title,
                style: pw.TextStyle(
                  fontSize: _subtitleFontSize,
                  fontWeight: pw.FontWeight.bold,
                  color: _textColor,
                  letterSpacing: 0.1,
                ),
              ),
              if (proj.description.isNotEmpty) ...[
                // Use isNotEmpty
                pw.SizedBox(height: 8), // Spacing before description
                pw.Text(
                  proj.description,
                  style: pw.TextStyle(
                    fontSize: _contentFontSize,
                    color: _textColor,
                    lineSpacing: 1.1,
                    letterSpacing: 0.05,
                  ),
                ),
              ],
              if (!isLast)
                pw.SizedBox(
                  height: _paragraphSpacing,
                ), // Spacing after item unless it's the last one
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildCertificationsSection(
    List<Certification> certifications,
  ) {
    List<pw.Widget> certificationRows = [];
    for (int i = 0; i < certifications.length; i += 2) {
      List<pw.Widget> rowChildren = [];

      // First item in the row
      rowChildren.add(
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Arrange Name and Year in a Row
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      certifications[i].name, // Name on the left
                      style: pw.TextStyle(
                        fontSize: _subtitleFontSize,
                        fontWeight: pw.FontWeight.bold,
                        color: _textColor,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  pw.Text(
                    certifications[i].year, // Year on the right
                    style: pw.TextStyle(
                      fontSize: _contentFontSize,
                      color: _textColor,
                      letterSpacing: 0.05,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(
                height: 4,
              ), // Spacing between name/year and organization
              // Organization below the name/year row
              pw.Text(
                certifications[i].organization,
                style: pw.TextStyle(
                  fontSize: _contentFontSize,
                  color: _textColor,
                  letterSpacing: 0.05,
                ),
              ),
            ],
          ),
        ),
      );

      // Second item in the row (if exists)
      if (i + 1 < certifications.length) {
        rowChildren.add(pw.SizedBox(width: 16)); // Spacing between columns
        rowChildren.add(
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Arrange Name and Year in a Row
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        certifications[i + 1].name, // Name on the left
                        style: pw.TextStyle(
                          fontSize: _subtitleFontSize,
                          fontWeight: pw.FontWeight.bold,
                          color: _textColor,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    pw.Text(
                      certifications[i + 1].year, // Year on the right
                      style: pw.TextStyle(
                        fontSize: _contentFontSize,
                        color: _textColor,
                        letterSpacing: 0.05,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(
                  height: 4,
                ), // Spacing between name/year and organization
                // Organization below the name/year row
                pw.Text(
                  certifications[i + 1].organization,
                  style: pw.TextStyle(
                    fontSize: _contentFontSize,
                    color: _textColor,
                    letterSpacing: 0.05,
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Add an empty Expanded to balance the row if there's only one item
        rowChildren.add(pw.Expanded(child: pw.Container()));
      }

      certificationRows.add(
        pw.Padding(
          padding:
              i == 0
                  ? pw.EdgeInsets.zero
                  : const pw.EdgeInsets.only(
                    top: _paragraphSpacing,
                  ), // Add spacing between rows of entries
          child: pw.Row(children: rowChildren),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: certificationRows,
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title.toUpperCase(),
      style: pw.TextStyle(
        fontSize: _sectionTitleFontSize,
        fontWeight: pw.FontWeight.bold,
        color: _blueColor,
        letterSpacing: 0.5,
      ),
    );
  }
}
