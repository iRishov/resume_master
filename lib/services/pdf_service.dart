import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class PDFService {
  static Future<File> generateResumePDF(Map<String, dynamic> resumeData) async {
    final pdf = pw.Document();

    // Define styles
    final headerStyle = pw.TextStyle(
      fontSize: 24,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.black,
    );

    final sectionStyle = pw.TextStyle(
      fontSize: 18,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.black,
    );

    final bodyStyle = pw.TextStyle(fontSize: 12, color: PdfColors.black);

    final subheaderStyle = pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.black,
    );

    // Build the PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with name and contact info
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      resumeData['personalInfo']['fullName'] ?? '',
                      style: headerStyle,
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Text(
                          '${resumeData['personalInfo']['email'] ?? ''} | ',
                          style: bodyStyle,
                        ),
                        pw.Text(
                          '${resumeData['personalInfo']['phone'] ?? ''} | ',
                          style: bodyStyle,
                        ),
                        pw.Text(
                          resumeData['personalInfo']['address'] ?? '',
                          style: bodyStyle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Professional Summary
              if (resumeData['summary'] != null &&
                  resumeData['summary'].isNotEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Professional Summary', style: sectionStyle),
                      pw.SizedBox(height: 8),
                      pw.Text(resumeData['summary'], style: bodyStyle),
                    ],
                  ),
                ),

              // Work Experience
              if (resumeData['experiences'] != null &&
                  resumeData['experiences'].isNotEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Work Experience', style: sectionStyle),
                      pw.SizedBox(height: 8),
                      ...resumeData['experiences'].map<pw.Widget>((exp) {
                        return pw.Container(
                          padding: const pw.EdgeInsets.only(bottom: 12),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                exp['jobTitle'] ?? '',
                                style: subheaderStyle,
                              ),
                              pw.Text(exp['company'] ?? '', style: bodyStyle),
                              pw.Text(exp['duration'] ?? '', style: bodyStyle),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                exp['description'] ?? '',
                                style: bodyStyle,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),

              // Education
              if (resumeData['education'] != null &&
                  resumeData['education'].isNotEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Education', style: sectionStyle),
                      pw.SizedBox(height: 8),
                      ...resumeData['education'].map<pw.Widget>((edu) {
                        return pw.Container(
                          padding: const pw.EdgeInsets.only(bottom: 12),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                edu['degree'] ?? '',
                                style: subheaderStyle,
                              ),
                              pw.Text(
                                edu['institution'] ?? '',
                                style: bodyStyle,
                              ),
                              pw.Text(edu['year'] ?? '', style: bodyStyle),
                              if (edu['description'] != null &&
                                  edu['description'].isNotEmpty)
                                pw.Text(
                                  edu['description'] ?? '',
                                  style: bodyStyle,
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),

              // Skills
              if (resumeData['skills'] != null &&
                  resumeData['skills'].isNotEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Skills', style: sectionStyle),
                      pw.SizedBox(height: 8),
                      pw.Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            resumeData['skills'].map<pw.Widget>((skill) {
                              return pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(color: PdfColors.black),
                                  borderRadius: const pw.BorderRadius.all(
                                    pw.Radius.circular(4),
                                  ),
                                ),
                                child: pw.Text(skill, style: bodyStyle),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),

              // Languages
              if (resumeData['languages'] != null &&
                  resumeData['languages'].isNotEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Languages', style: sectionStyle),
                      pw.SizedBox(height: 8),
                      pw.Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            resumeData['languages'].map<pw.Widget>((lang) {
                              return pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(color: PdfColors.black),
                                  borderRadius: const pw.BorderRadius.all(
                                    pw.Radius.circular(4),
                                  ),
                                ),
                                child: pw.Text(lang, style: bodyStyle),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),

              // Projects
              if (resumeData['projects'] != null &&
                  resumeData['projects'].isNotEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Projects', style: sectionStyle),
                      pw.SizedBox(height: 8),
                      ...resumeData['projects'].map<pw.Widget>((proj) {
                        return pw.Container(
                          padding: const pw.EdgeInsets.only(bottom: 12),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                proj['title'] ?? '',
                                style: subheaderStyle,
                              ),
                              pw.Text(
                                proj['description'] ?? '',
                                style: bodyStyle,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),

              // Certifications
              if (resumeData['certifications'] != null &&
                  resumeData['certifications'].isNotEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Certifications', style: sectionStyle),
                      pw.SizedBox(height: 8),
                      ...resumeData['certifications'].map<pw.Widget>((cert) {
                        return pw.Container(
                          padding: const pw.EdgeInsets.only(bottom: 12),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                cert['name'] ?? '',
                                style: subheaderStyle,
                              ),
                              pw.Text(
                                cert['organization'] ?? '',
                                style: bodyStyle,
                              ),
                              pw.Text(cert['year'] ?? '', style: bodyStyle),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );

    // Save the PDF file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/resume.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
