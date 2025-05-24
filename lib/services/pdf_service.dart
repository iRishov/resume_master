import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class PDFService {
  static Future<File> generateResumePDF(Map<String, dynamic> resumeData) async {
    final pdf = pw.Document();

    final headerStyle = pw.TextStyle(
      fontSize: 24,
      fontWeight: pw.FontWeight.bold,
    );
    final subheaderStyle = pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
    );
    final sectionStyle = pw.TextStyle(
      fontSize: 16,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blue900,
    );
    final bodyStyle = pw.TextStyle(fontSize: 11, color: PdfColors.black);

    pw.Widget sectionDivider() =>
        pw.Divider(thickness: 1, color: PdfColors.grey);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Text(
                resumeData['personalInfo']['fullName'] ?? '',
                style: headerStyle,
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                "${resumeData['personalInfo']['email'] ?? ''} | "
                "${resumeData['personalInfo']['phone'] ?? ''} | "
                "${resumeData['personalInfo']['address'] ?? ''}",
                style: bodyStyle,
              ),
              pw.SizedBox(height: 10),
              sectionDivider(),

              // Summary
              if (resumeData['summary']?.isNotEmpty ?? false)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Professional Summary', style: sectionStyle),
                    pw.SizedBox(height: 6),
                    pw.Text(resumeData['summary'], style: bodyStyle),
                    pw.SizedBox(height: 10),
                    sectionDivider(),
                  ],
                ),

              // Work Experience
              if (resumeData['experiences']?.isNotEmpty ?? false)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Work Experience', style: sectionStyle),
                    pw.SizedBox(height: 6),
                    ...resumeData['experiences'].map<pw.Widget>((exp) {
                      return pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 10),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              exp['jobTitle'] ?? '',
                              style: subheaderStyle,
                            ),
                            pw.Text(
                              "${exp['company'] ?? ''} | ${exp['duration'] ?? ''}",
                              style: bodyStyle,
                            ),
                            if (exp['description'] != null &&
                                exp['description'].isNotEmpty)
                              pw.Bullet(
                                text: exp['description'],
                                style: bodyStyle,
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    sectionDivider(),
                  ],
                ),

              // Education
              if (resumeData['education']?.isNotEmpty ?? false)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Education', style: sectionStyle),
                    pw.SizedBox(height: 6),
                    ...resumeData['education'].map<pw.Widget>((edu) {
                      return pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 10),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(edu['degree'] ?? '', style: subheaderStyle),
                            pw.Text(
                              "${edu['institution'] ?? ''} | ${edu['year'] ?? ''}",
                              style: bodyStyle,
                            ),
                            if (edu['description']?.isNotEmpty ?? false)
                              pw.Bullet(
                                text: edu['description'],
                                style: bodyStyle,
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    sectionDivider(),
                  ],
                ),

              // Skills
              if (resumeData['skills']?.isNotEmpty ?? false)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Skills', style: sectionStyle),
                    pw.SizedBox(height: 6),
                    pw.Text(resumeData['skills'].join(', '), style: bodyStyle),
                    pw.SizedBox(height: 10),
                    sectionDivider(),
                  ],
                ),

              // Languages
              if (resumeData['languages']?.isNotEmpty ?? false)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Languages', style: sectionStyle),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      resumeData['languages'].join(', '),
                      style: bodyStyle,
                    ),
                    pw.SizedBox(height: 10),
                    sectionDivider(),
                  ],
                ),

              // Projects
              if (resumeData['projects']?.isNotEmpty ?? false)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Projects', style: sectionStyle),
                    pw.SizedBox(height: 6),
                    ...resumeData['projects'].map<pw.Widget>((proj) {
                      return pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 10),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(proj['title'] ?? '', style: subheaderStyle),
                            if (proj['description']?.isNotEmpty ?? false)
                              pw.Bullet(
                                text: proj['description'],
                                style: bodyStyle,
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    sectionDivider(),
                  ],
                ),

              // Certifications
              if (resumeData['certifications']?.isNotEmpty ?? false)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Certifications', style: sectionStyle),
                    pw.SizedBox(height: 6),
                    ...resumeData['certifications'].map<pw.Widget>((cert) {
                      return pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 10),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(cert['name'] ?? '', style: subheaderStyle),
                            pw.Text(
                              "${cert['organization'] ?? ''} | ${cert['year'] ?? ''}",
                              style: bodyStyle,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
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
}
