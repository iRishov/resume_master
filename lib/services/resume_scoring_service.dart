import 'package:flutter/material.dart';

class ResumeScoringService {
  // Scoring weights for different sections
  static const Map<String, double> _sectionWeights = {
    'personalInfo': 0.10,
    'summary': 0.15,
    'education': 0.15,
    'experience': 0.25,
    'skills': 0.15,
    'projects': 0.10,
    'certifications': 0.05,
    'atsCompatibility': 0.05,
  };

  // Minimum requirements for each section
  static const Map<String, List<String>> _sectionRequirements = {
    'personalInfo': ['fullName', 'email', 'phone', 'address'],
    'summary': ['summary'],
    'education': ['degree', 'institution', 'year', 'description'],
    'experience': ['jobTitle', 'company', 'duration', 'description'],
    'skills': ['skills'],
    'projects': ['title', 'description'],
    'certifications': ['name', 'organization', 'year'],
  };

  // ATS-friendly keywords by industry
  static const Map<String, List<String>> _atsKeywords = {
    'technical': [
      'Python',
      'Java',
      'JavaScript',
      'React',
      'Node.js',
      'SQL',
      'AWS',
      'Docker',
      'Kubernetes',
      'Git',
      'CI/CD',
      'Agile',
      'Scrum',
      'DevOps',
      'Microservices',
      'TypeScript',
      'Angular',
      'Vue.js',
      'MongoDB',
      'PostgreSQL',
      'REST API',
      'GraphQL',
      'Machine Learning',
      'AI',
      'Cloud Computing',
      'Azure',
      'GCP',
      'Linux',
      'Shell Scripting',
    ],
    'business': [
      'Project Management',
      'Strategic Planning',
      'Business Development',
      'Marketing',
      'Sales',
      'Customer Relations',
      'Financial Analysis',
      'Budget Management',
      'Team Leadership',
      'Stakeholder Management',
      'Market Research',
      'Business Strategy',
      'Risk Management',
      'Process Improvement',
      'Data Analysis',
      'Business Intelligence',
      'CRM',
      'ERP',
      'Supply Chain',
      'Operations Management',
    ],
    'design': [
      'UI/UX Design',
      'Adobe Creative Suite',
      'Figma',
      'Sketch',
      'Wireframing',
      'Prototyping',
      'Visual Design',
      'Typography',
      'Color Theory',
      'Responsive Design',
      'User Research',
      'Interaction Design',
      'Information Architecture',
      'Design Systems',
      'Illustration',
      'Motion Graphics',
      '3D Modeling',
      'Brand Identity',
    ],
  };

  // Calculate total score and provide feedback
  Map<String, dynamic> calculateScore(Map<String, dynamic> resumeData) {
    try {
      final Map<String, dynamic> scores = {};
      final Map<String, List<String>> suggestions = {};
      final Map<String, List<String>> strengths = {};
      final Map<String, Map<String, dynamic>> detailedFeedback = {};

      // Calculate section scores
      for (final section in _sectionWeights.keys) {
        if (section == 'atsCompatibility') continue;
        try {
          // Special handling for experience section
          if (section == 'experience') {
            final sectionData = resumeData['experiences'];
            if (sectionData == null) {
              scores[section] = 0.0;
              suggestions[section] = ['Missing experience section'];
              strengths[section] = [];
              continue;
            }
            scores[section] = _scoreExperience(sectionData as List<dynamic>?);
          } else {
            final sectionData = resumeData[section];
            if (sectionData == null) {
              scores[section] = 0.0;
              suggestions[section] = ['Missing $section section'];
              strengths[section] = [];
              continue;
            }

            double sectionScore = 0.0;
            switch (section) {
              case 'personalInfo':
                sectionScore = _scorePersonalInfo(
                  sectionData as Map<String, dynamic>?,
                );
                break;
              case 'summary':
                sectionScore = _scoreSummary(sectionData as String?);
                break;
              case 'education':
                sectionScore = _scoreEducation(sectionData as List<dynamic>?);
                break;
              case 'skills':
                sectionScore = _scoreSkills(sectionData as List<dynamic>?);
                break;
              case 'projects':
                sectionScore = _scoreProjects(sectionData as List<dynamic>?);
                break;
              case 'certifications':
                sectionScore = _scoreCertifications(
                  sectionData as List<dynamic>?,
                );
                break;
            }
            scores[section] = sectionScore;
          }

          // Generate suggestions and strengths
          final feedback = _generateSectionFeedback(
            section,
            resumeData,
            scores[section] as double,
          );
          suggestions[section] = feedback['suggestions']!;
          strengths[section] = feedback['strengths']!;

          detailedFeedback[section] = {
            'score': scores[section],
            'suggestions': suggestions[section],
            'strengths': strengths[section],
          };
        } catch (e) {
          debugPrint('Error calculating score for section $section: $e');
          scores[section] = 0.0;
          suggestions[section] = ['Error analyzing this section'];
          strengths[section] = [];
        }
      }

      // Calculate ATS compatibility
      final atsResult = _calculateATSScore(resumeData);
      scores['atsCompatibility'] = atsResult['score'];
      suggestions['atsCompatibility'] = atsResult['suggestions'];
      strengths['atsCompatibility'] = atsResult['strengths'];
      detailedFeedback['atsCompatibility'] = {
        'score': atsResult['score'],
        'suggestions': atsResult['suggestions'],
        'strengths': atsResult['strengths'],
      };

      // Calculate total score as simple average of all section scores
      double totalScore = 0.0;
      int sectionCount = 0;
      for (final section in _sectionWeights.keys) {
        final score = (scores[section] as num?)?.toDouble() ?? 0.0;
        totalScore += score;
        sectionCount++;
      }

      // Calculate average score and convert to percentage
      totalScore = sectionCount > 0 ? (totalScore / sectionCount) * 100 : 0;
      totalScore = totalScore.clamp(0.0, 100.0).roundToDouble();

      // Add overall suggestions based on total score
      if (totalScore < 60) {
        suggestions['overall'] = [
          'You\'re on the right track! Let\'s enhance your resume to make it stand out.',
          'Your resume has a good foundation. Here are some ways to make it even better:',
          '• Add more details to each section to showcase your achievements',
          '• Include industry-specific keywords to improve visibility',
          '• Consider adding certifications to demonstrate your expertise',
          'Remember: Every great resume starts somewhere. These improvements will help you shine!',
        ];
      } else if (totalScore < 80) {
        suggestions['overall'] = [
          'Great job! Your resume is already quite strong.',
          'To make it even more impressive, consider:',
          '• Adding specific achievements with numbers and metrics',
          '• Enhancing your skills section with relevant keywords',
          '• Including industry-specific certifications',
          '• Optimizing for ATS systems to increase visibility',
          'You\'re almost there! These small improvements will make a big difference.',
        ];
      } else {
        suggestions['overall'] = [
          'Excellent work! Your resume is already very strong.',
          'To maintain its high quality:',
          '• Keep adding industry-specific keywords as you gain experience',
          '• Regularly update your information and achievements',
          '• Maintain your certifications and add new ones',
          '• Continue to refine your descriptions with specific metrics',
          'You\'re doing great! Keep up the good work!',
        ];
      }

      return {
        'totalScore': totalScore,
        'sectionScores': scores,
        'suggestions': suggestions,
        'strengths': strengths,
        'atsCompatibility': atsResult['score'],
        'overallFeedback': {
          'detailedFeedback': detailedFeedback,
          'encouragement': _generateEncouragement(totalScore),
        },
      };
    } catch (e) {
      debugPrint('Error calculating resume score: $e');
      return {
        'totalScore': 0.0,
        'sectionScores': {},
        'suggestions': {
          'overall': ['Error analyzing resume'],
        },
        'strengths': {},
        'atsCompatibility': 0.0,
        'overallFeedback': {'detailedFeedback': {}, 'error': e.toString()},
      };
    }
  }

  // Generate feedback for a section
  Map<String, List<String>> _generateSectionFeedback(
    String section,
    Map<String, dynamic> resumeData,
    double score,
  ) {
    final suggestions = <String>[];
    final strengths = <String>[];

    try {
      switch (section) {
        case 'personalInfo':
          _generatePersonalInfoFeedback(
            resumeData['personalInfo'],
            suggestions,
            strengths,
          );
          break;
        case 'summary':
          _generateSummaryFeedback(
            resumeData['summary'],
            suggestions,
            strengths,
          );
          break;
        case 'education':
          _generateEducationFeedback(
            resumeData['education'],
            suggestions,
            strengths,
          );
          break;
        case 'experience':
          _generateExperienceFeedback(
            resumeData['experiences'],
            suggestions,
            strengths,
          );
          break;
        case 'skills':
          _generateSkillsFeedback(resumeData['skills'], suggestions, strengths);
          break;
        case 'projects':
          _generateProjectsFeedback(
            resumeData['projects'],
            suggestions,
            strengths,
          );
          break;
        case 'certifications':
          _generateCertificationsFeedback(
            resumeData['certifications'],
            suggestions,
            strengths,
          );
          break;
      }
    } catch (e) {
      debugPrint('Error generating feedback for $section: $e');
      suggestions.add('Error analyzing section: ${e.toString()}');
    }

    return {'suggestions': suggestions, 'strengths': strengths};
  }

  // Helper functions for scoring sections
  double _scorePersonalInfo(Map<String, dynamic>? personalInfo) {
    if (personalInfo == null) return 0.0;

    final requiredFields = _sectionRequirements['personalInfo']!;
    double filledFields = 0.0;

    for (final field in requiredFields) {
      if (personalInfo[field]?.toString().trim().isNotEmpty == true) {
        filledFields++;
      }
    }

    // Bonus points for additional fields
    final additionalFields = ['linkedin', 'github', 'portfolio', 'website'];
    for (final field in additionalFields) {
      if (personalInfo[field]?.toString().trim().isNotEmpty == true) {
        filledFields += 0.5;
      }
    }

    return filledFields / requiredFields.length;
  }

  double _scoreSummary(String? summary) {
    if (summary == null || summary.trim().isEmpty) return 0.0;

    double totalScore = 0.0;
    final words = summary.trim().split(' ');

    // Base score based on length
    if (words.length < 50) {
      totalScore = 0.3;
    } else if (words.length < 100) {
      totalScore = 0.6;
    } else if (words.length < 150) {
      totalScore = 0.8;
    } else {
      totalScore = 1.0;
    }

    // Check for key elements
    final keyElements = {
      'experience': 'years of experience',
      'skills': 'key skills',
      'achievement': 'specific achievements',
      'goal': 'career goals',
      'value': 'value proposition',
    };

    int foundElements = 0;
    for (final element in keyElements.entries) {
      if (summary.toLowerCase().contains(element.key)) {
        foundElements++;
      }
    }

    // Bonus for key elements
    if (foundElements >= 4) {
      totalScore += 0.2;
    } else if (foundElements >= 2) {
      totalScore += 0.1;
    }

    // Check for action verbs
    final actionVerbs = [
      'achieved',
      'developed',
      'implemented',
      'managed',
      'led',
      'created',
      'improved',
      'increased',
      'reduced',
      'optimized',
    ];
    int actionVerbCount = 0;
    for (final verb in actionVerbs) {
      if (summary.toLowerCase().contains(verb)) {
        actionVerbCount++;
      }
    }

    // Bonus for action verbs
    if (actionVerbCount >= 3) {
      totalScore += 0.1;
    }

    return totalScore.clamp(0.0, 1.0);
  }

  double _scoreEducation(List<dynamic>? education) {
    if (education == null || education.isEmpty) return 0.0;

    double totalScore = 0.0;
    final requiredFields = _sectionRequirements['education']!;

    for (final edu in education) {
      if (edu is! Map<String, dynamic>) continue;

      double fieldScore = 0.0;
      for (final field in requiredFields) {
        if (edu[field]?.toString().trim().isNotEmpty == true) {
          fieldScore += 1.0;
        }
      }

      // Enhanced scoring for description
      final description = edu['description']?.toString() ?? '';
      final wordCount = description.split(' ').length;

      if (wordCount > 100) {
        fieldScore += 0.3; // Bonus for very detailed description
      } else if (wordCount > 50) {
        fieldScore += 0.2; // Bonus for detailed description
      } else if (wordCount > 25) {
        fieldScore += 0.1; // Small bonus for basic description
      }

      // Bonus for relevant coursework
      if (description.toLowerCase().contains('coursework') ||
          description.toLowerCase().contains('courses') ||
          description.toLowerCase().contains('relevant classes')) {
        fieldScore += 0.2;
      }

      // Bonus for academic achievements
      if (description.toLowerCase().contains('gpa') ||
          description.toLowerCase().contains('honors') ||
          description.toLowerCase().contains('dean\'s list') ||
          description.toLowerCase().contains('scholarship')) {
        fieldScore += 0.2;
      }

      // Bonus for relevant projects
      if (description.toLowerCase().contains('project') ||
          description.toLowerCase().contains('thesis') ||
          description.toLowerCase().contains('research')) {
        fieldScore += 0.2;
      }

      // Calculate score for this education entry
      final educationScore = (fieldScore / (requiredFields.length + 0.9)).clamp(
        0.0,
        1.0,
      );
      totalScore += educationScore;
    }

    // Enhanced bonus for multiple education entries
    final educationCount = education.length;
    if (educationCount > 2) {
      totalScore = (totalScore + 0.3).clamp(
        0.0,
        1.0,
      ); // Maximum bonus for 3+ entries
    } else if (educationCount > 1) {
      totalScore = (totalScore + 0.2).clamp(0.0, 1.0); // Bonus for 2 entries
    }

    return education.isEmpty ? 0.0 : totalScore / education.length;
  }

  double _scoreExperience(List<dynamic>? experiences) {
    if (experiences == null || experiences.isEmpty) return 0.0;

    double totalScore = 0.0;
    final requiredFields = _sectionRequirements['experience']!;

    for (final exp in experiences) {
      if (exp is! Map<String, dynamic>) continue;

      double fieldScore = 0.0;
      // Check required fields
      for (final field in requiredFields) {
        if (exp[field]?.toString().trim().isNotEmpty == true) {
          fieldScore += 1.0;
        }
      }

      // Enhanced scoring based on description quality
      final description = exp['description']?.toString() ?? '';
      final wordCount = description.split(' ').length;

      // More granular scoring for description length
      if (wordCount > 150) {
        fieldScore += 0.4; // Bonus for very detailed descriptions
      } else if (wordCount > 100) {
        fieldScore += 0.3; // Bonus for detailed descriptions
      } else if (wordCount > 50) {
        fieldScore += 0.2; // Bonus for good descriptions
      } else if (wordCount > 25) {
        fieldScore += 0.1; // Small bonus for basic descriptions
      }

      // Enhanced quantifiable achievements scoring
      final metricsPattern = RegExp(
        r'\d+%|\$\d+|\d+x|\d+% increase|\d+% growth|\d+% reduction|\d+% improvement',
      );
      final metricsCount =
          metricsPattern.allMatches(description.toLowerCase()).length;
      if (metricsCount >= 3) {
        fieldScore += 0.3; // Bonus for multiple metrics
      } else if (metricsCount > 0) {
        fieldScore += 0.2; // Bonus for some metrics
      }

      // Enhanced action verbs scoring
      final actionVerbs = [
        'achieved',
        'developed',
        'implemented',
        'managed',
        'led',
        'created',
        'improved',
        'increased',
        'reduced',
        'optimized',
        'delivered',
        'executed',
        'established',
        'launched',
        'spearheaded',
        'pioneered',
        'transformed',
        'streamlined',
        'enhanced',
        'maximized',
      ];
      int actionVerbCount = 0;
      for (final verb in actionVerbs) {
        if (description.toLowerCase().contains(verb)) {
          actionVerbCount++;
        }
      }
      if (actionVerbCount >= 5) {
        fieldScore += 0.3; // Bonus for extensive use of action verbs
      } else if (actionVerbCount >= 3) {
        fieldScore += 0.2; // Bonus for good use of action verbs
      } else if (actionVerbCount > 0) {
        fieldScore += 0.1; // Small bonus for some action verbs
      }

      // Bonus for technical skills mentioned
      final technicalSkills = _atsKeywords['technical']!;
      int technicalSkillCount = 0;
      for (final skill in technicalSkills) {
        if (description.toLowerCase().contains(skill.toLowerCase())) {
          technicalSkillCount++;
        }
      }
      if (technicalSkillCount >= 3) {
        fieldScore += 0.2; // Bonus for multiple technical skills
      } else if (technicalSkillCount > 0) {
        fieldScore += 0.1; // Small bonus for some technical skills
      }

      // Calculate score for this experience (normalized to 0-1)
      final experienceScore = (fieldScore / (requiredFields.length + 1.2))
          .clamp(0.0, 1.0);
      totalScore += experienceScore;
    }

    // Enhanced bonus for multiple experiences
    final experienceCount = experiences.length;
    if (experienceCount > 5) {
      totalScore = (totalScore + 0.4).clamp(
        0.0,
        1.0,
      ); // Maximum bonus for 6+ experiences
    } else if (experienceCount > 3) {
      totalScore = (totalScore + 0.3).clamp(
        0.0,
        1.0,
      ); // Bonus for 4-5 experiences
    } else if (experienceCount > 1) {
      totalScore = (totalScore + (experienceCount - 1) * 0.1).clamp(
        0.0,
        1.0,
      ); // Progressive bonus
    }

    // Calculate final score (normalized to 0-1)
    final finalScore =
        experiences.isEmpty ? 0.0 : totalScore / experiences.length;
    return finalScore.clamp(0.0, 1.0);
  }

  double _scoreSkills(List<dynamic>? skills) {
    if (skills == null || skills.isEmpty) return 0.0;

    double totalScore = 0.0;
    final skillCount = skills.length;

    // Base score based on number of skills
    if (skillCount < 5) {
      totalScore = 0.3;
    } else if (skillCount < 10) {
      totalScore = 0.6;
    } else if (skillCount < 15) {
      totalScore = 0.8;
    } else {
      totalScore = 1.0;
    }

    // Check for technical skills
    int technicalSkillCount = 0;
    for (final skill in skills) {
      final skillStr = skill.toString().toLowerCase();
      if (_atsKeywords['technical']!.any(
        (k) => skillStr.contains(k.toLowerCase()),
      )) {
        technicalSkillCount++;
      }
    }

    // Bonus for technical skills
    if (technicalSkillCount >= 5) {
      totalScore += 0.2;
    } else if (technicalSkillCount >= 3) {
      totalScore += 0.1;
    }

    // Check for soft skills
    int softSkillCount = 0;
    for (final skill in skills) {
      final skillStr = skill.toString().toLowerCase();
      if (_atsKeywords['business']!.any(
        (k) => skillStr.contains(k.toLowerCase()),
      )) {
        softSkillCount++;
      }
    }

    // Bonus for soft skills
    if (softSkillCount >= 3) {
      totalScore += 0.1;
    }

    return totalScore.clamp(0.0, 1.0);
  }

  double _scoreProjects(List<dynamic>? projects) {
    if (projects == null || projects.isEmpty) return 0.0;

    double totalScore = 0.0;
    final requiredFields = _sectionRequirements['projects']!;

    for (final project in projects) {
      if (project is! Map<String, dynamic>) continue;

      double fieldScore = 0.0;
      for (final field in requiredFields) {
        if (project[field]?.toString().trim().isNotEmpty == true) {
          fieldScore += 1.0;
        }
      }

      // Enhanced scoring for description
      final description = project['description']?.toString() ?? '';
      final wordCount = description.split(' ').length;

      if (wordCount > 150) {
        fieldScore += 0.4; // Bonus for very detailed description
      } else if (wordCount > 100) {
        fieldScore += 0.3; // Bonus for detailed description
      } else if (wordCount > 50) {
        fieldScore += 0.2; // Bonus for good description
      } else if (wordCount > 25) {
        fieldScore += 0.1; // Small bonus for basic description
      }

      // Bonus for technical details
      final technicalSkills = _atsKeywords['technical']!;
      int technicalSkillCount = 0;
      for (final skill in technicalSkills) {
        if (description.toLowerCase().contains(skill.toLowerCase())) {
          technicalSkillCount++;
        }
      }
      if (technicalSkillCount >= 3) {
        fieldScore += 0.3; // Bonus for multiple technical skills
      } else if (technicalSkillCount > 0) {
        fieldScore += 0.2; // Bonus for some technical skills
      }

      // Bonus for quantifiable results
      final metricsPattern = RegExp(
        r'\d+%|\$\d+|\d+x|\d+% increase|\d+% growth|\d+% reduction|\d+% improvement',
      );
      final metricsCount =
          metricsPattern.allMatches(description.toLowerCase()).length;
      if (metricsCount >= 2) {
        fieldScore += 0.3; // Bonus for multiple metrics
      } else if (metricsCount > 0) {
        fieldScore += 0.2; // Bonus for some metrics
      }

      // Bonus for action verbs
      final actionVerbs = [
        'achieved',
        'developed',
        'implemented',
        'managed',
        'led',
        'created',
        'improved',
        'increased',
        'reduced',
        'optimized',
        'delivered',
        'executed',
        'established',
        'launched',
        'spearheaded',
        'pioneered',
        'transformed',
      ];
      int actionVerbCount = 0;
      for (final verb in actionVerbs) {
        if (description.toLowerCase().contains(verb)) {
          actionVerbCount++;
        }
      }
      if (actionVerbCount >= 3) {
        fieldScore += 0.2; // Bonus for multiple action verbs
      } else if (actionVerbCount > 0) {
        fieldScore += 0.1; // Small bonus for some action verbs
      }

      // Calculate score for this project
      final projectScore = (fieldScore / (requiredFields.length + 1.2)).clamp(
        0.0,
        1.0,
      );
      totalScore += projectScore;
    }

    // Enhanced bonus for multiple projects
    final projectCount = projects.length;
    if (projectCount > 3) {
      totalScore = (totalScore + 0.4).clamp(
        0.0,
        1.0,
      ); // Maximum bonus for 4+ projects
    } else if (projectCount > 1) {
      totalScore = (totalScore + (projectCount - 1) * 0.15).clamp(
        0.0,
        1.0,
      ); // Progressive bonus
    }

    return projects.isEmpty ? 0.0 : totalScore / projects.length;
  }

  double _scoreCertifications(List<dynamic>? certifications) {
    if (certifications == null || certifications.isEmpty) return 0.0;

    double totalScore = 0.0;
    final requiredFields = _sectionRequirements['certifications']!;

    for (final cert in certifications) {
      if (cert is! Map<String, dynamic>) continue;

      double fieldScore = 0.0;
      for (final field in requiredFields) {
        if (cert[field]?.toString().trim().isNotEmpty == true) {
          fieldScore += 1.0;
        }
      }
      totalScore += fieldScore / requiredFields.length;
    }

    // Bonus for multiple certifications
    final certCount = certifications.length;
    if (certCount > 1) {
      totalScore = (totalScore + (certCount - 1) * 0.1).clamp(0.0, 1.0);
    }

    return certifications.isEmpty ? 0.0 : totalScore / certifications.length;
  }

  // Enhanced ATS scoring
  Map<String, dynamic> _calculateATSScore(Map<String, dynamic> resumeData) {
    try {
      final skills = resumeData['skills'] as List<dynamic>? ?? [];
      final summary = resumeData['summary']?.toString() ?? '';
      final experiences = resumeData['experiences'] as List<dynamic>? ?? [];
      final projects = resumeData['projects'] as List<dynamic>? ?? [];

      // Combine all text for keyword matching
      final allText = [
        ...skills.map((s) => s.toString().toLowerCase()),
        summary.toLowerCase(),
        ...experiences.map((e) {
          if (e is Map<String, dynamic>) {
            return e['description']?.toString().toLowerCase() ?? '';
          }
          return '';
        }),
        ...projects.map((p) {
          if (p is Map<String, dynamic>) {
            return p['description']?.toString().toLowerCase() ?? '';
          }
          return '';
        }),
      ].join(' ');

      // Count matching keywords by industry
      Map<String, int> industryMatches = {};
      Map<String, int> industryTotals = {};
      int totalMatches = 0;
      int totalKeywords = 0;

      for (final industry in _atsKeywords.keys) {
        int matches = 0;
        for (final keyword in _atsKeywords[industry]!) {
          totalKeywords++;
          if (allText.contains(keyword.toLowerCase())) {
            matches++;
            totalMatches++;
          }
        }
        industryMatches[industry] = matches;
        industryTotals[industry] = _atsKeywords[industry]!.length;
      }

      // Calculate overall ATS score
      double atsScore =
          totalKeywords > 0 ? (totalMatches / totalKeywords) * 100 : 0;

      // Generate ATS-specific feedback
      List<String> suggestions = [];
      List<String> strengths = [];

      // Add industry-specific feedback
      for (final industry in _atsKeywords.keys) {
        final matches = industryMatches[industry] ?? 0;
        final total = industryTotals[industry] ?? 0;
        final matchPercentage = total > 0 ? (matches / total) * 100 : 0;

        if (matchPercentage < 30) {
          suggestions.add('Add more ${industry} industry keywords');
        } else if (matchPercentage > 70) {
          strengths.add('Strong ${industry} industry keyword coverage');
        }
      }

      // Add general ATS feedback
      if (atsScore < 30) {
        suggestions.addAll([
          'Include more industry-specific keywords',
          'Add technical skills and tools',
          'Use standard section headings',
          'Avoid complex formatting',
        ]);
      } else if (atsScore > 70) {
        strengths.addAll([
          'Good keyword optimization',
          'Strong industry relevance',
          'Well-structured content',
        ]);
      }

      return {
        'score': atsScore,
        'suggestions': suggestions,
        'strengths': strengths,
        'industryMatches': industryMatches,
      };
    } catch (e) {
      debugPrint('Error in _calculateATSScore: $e');
      return {
        'score': 0.0,
        'suggestions': ['Error analyzing ATS compatibility'],
        'strengths': [],
        'industryMatches': {},
      };
    }
  }

  // Add missing feedback generation methods
  void _generatePersonalInfoFeedback(
    Map<String, dynamic>? personalInfo,
    List<String> suggestions,
    List<String> strengths,
  ) {
    if (personalInfo == null) {
      suggestions.add(
        'Let\'s start by adding your basic information. This will help recruiters connect with you!',
      );
      return;
    }

    final requiredFields = _sectionRequirements['personalInfo']!;
    int filledFields = 0;

    for (final field in requiredFields) {
      if (personalInfo[field]?.toString().trim().isNotEmpty == true) {
        filledFields++;
      } else {
        switch (field) {
          case 'fullName':
            suggestions.add(
              'Adding your full name will make your resume more personal and professional',
            );
            break;
          case 'email':
            suggestions.add(
              'Include a professional email address so recruiters can easily reach you',
            );
            break;
          case 'phone':
            suggestions.add(
              'Add your phone number to make it convenient for recruiters to contact you',
            );
            break;
          case 'address':
            suggestions.add(
              'Include your location to help recruiters understand your availability',
            );
            break;
        }
      }
    }

    if (filledFields == requiredFields.length) {
      strengths.add(
        'Perfect! Your contact information is complete and professional. Great job!',
      );
    } else if (filledFields > 0) {
      strengths.add(
        'Good start! You\'ve included some contact information. Let\'s complete the rest!',
      );
    }

    // Check for additional fields
    final additionalFields = {
      'linkedin': 'LinkedIn profile',
      'github': 'GitHub profile',
      'portfolio': 'Portfolio website',
      'website': 'Personal website',
    };

    int additionalFieldsCount = 0;
    for (final entry in additionalFields.entries) {
      if (personalInfo[entry.key]?.toString().trim().isNotEmpty == true) {
        additionalFieldsCount++;
        strengths.add(
          'Excellent! Your ${entry.value} helps showcase your professional presence',
        );
      }
    }

    if (additionalFieldsCount > 0) {
      strengths.add(
        'Great job including ${additionalFieldsCount} professional profile${additionalFieldsCount > 1 ? 's' : ''}!',
      );
    }
  }

  void _generateSummaryFeedback(
    String? summary,
    List<String> suggestions,
    List<String> strengths,
  ) {
    if (summary == null || summary.trim().isEmpty) {
      suggestions.add(
        'Let\'s add a compelling professional summary to grab recruiters\' attention!',
      );
      return;
    }

    final words = summary.trim().split(' ');
    if (words.length < 50) {
      suggestions.add(
        'Your summary is a good start! Consider expanding it to 50-150 words to better showcase your qualifications',
      );
    } else if (words.length > 150) {
      suggestions.add(
        'Your summary is detailed! Consider making it more concise (50-150 words) to keep recruiters engaged',
      );
    } else {
      strengths.add(
        'Perfect! Your summary length is ideal for capturing attention. Well done!',
      );
    }

    // Check for key elements
    final keyElements = {
      'experience': 'years of experience',
      'skills': 'key skills',
      'achievement': 'specific achievements',
      'goal': 'career goals',
      'value': 'value proposition',
    };

    int foundElements = 0;
    for (final element in keyElements.entries) {
      if (summary.toLowerCase().contains(element.key)) {
        foundElements++;
        strengths.add('Great job highlighting your ${element.value}!');
      } else {
        suggestions.add(
          'Consider mentioning your ${element.value} to make your summary even more impactful',
        );
      }
    }

    if (foundElements >= 3) {
      strengths.add(
        'Excellent! Your summary effectively communicates your professional value',
      );
    } else if (foundElements > 0) {
      strengths.add(
        'Good start! Your summary includes some key elements. Let\'s add more!',
      );
    }
  }

  void _generateEducationFeedback(
    List<dynamic>? education,
    List<String> suggestions,
    List<String> strengths,
  ) {
    if (education == null || education.isEmpty) {
      suggestions.add(
        'Let\'s add your educational background to showcase your academic achievements!',
      );
      return;
    }

    if (education.length > 1) {
      strengths.add(
        'Excellent! Multiple education entries show your commitment to learning. Great job!',
      );
    }

    for (final edu in education) {
      if (edu is! Map<String, dynamic>) continue;

      final requiredFields = _sectionRequirements['education']!;
      for (final field in requiredFields) {
        if (edu[field]?.toString().trim().isEmpty == true) {
          switch (field) {
            case 'degree':
              suggestions.add(
                'Adding your degree will highlight your academic qualifications',
              );
              break;
            case 'institution':
              suggestions.add(
                'Include your educational institution to establish credibility',
              );
              break;
            case 'year':
              suggestions.add(
                'Adding your graduation year will show your educational timeline',
              );
              break;
            case 'description':
              suggestions.add(
                'Consider adding relevant coursework or achievements to strengthen this section',
              );
              break;
          }
        }
      }

      final description = edu['description']?.toString() ?? '';
      if (description.split(' ').length > 30) {
        strengths.add(
          'Excellent! Your education description provides valuable context. Well done!',
        );
      }
    }
  }

  void _generateExperienceFeedback(
    List<dynamic>? experiences,
    List<String> suggestions,
    List<String> strengths,
  ) {
    if (experiences == null || experiences.isEmpty) {
      suggestions.add(
        'Let\'s add your work experience to showcase your professional journey!',
      );
      return;
    }

    if (experiences.length > 1) {
      strengths.add(
        'Excellent! Multiple experiences demonstrate your career progression. Great job!',
      );
    }

    for (final exp in experiences) {
      if (exp is! Map<String, dynamic>) continue;

      final requiredFields = _sectionRequirements['experience']!;
      for (final field in requiredFields) {
        if (exp[field]?.toString().trim().isEmpty == true) {
          switch (field) {
            case 'jobTitle':
              suggestions.add(
                'Adding your job title will clearly communicate your role',
              );
              break;
            case 'company':
              suggestions.add(
                'Include the company name to establish your professional background',
              );
              break;
            case 'duration':
              suggestions.add(
                'Specify your employment duration to show your experience timeline',
              );
              break;
            case 'description':
              suggestions.add(
                'Add detailed responsibilities and achievements to showcase your impact',
              );
              break;
          }
        }
      }

      final description = exp['description']?.toString() ?? '';

      // Check description length
      if (description.split(' ').length < 50) {
        suggestions.add(
          'Your experience description is a good start! Consider adding more details about your achievements and metrics',
        );
      } else {
        strengths.add(
          'Excellent! Your detailed experience description effectively showcases your contributions. Well done!',
        );
      }

      // Check for quantifiable achievements
      if (description.toLowerCase().contains(
        RegExp(r'\d+%|\$\d+|\d+x|\d+% increase'),
      )) {
        strengths.add(
          'Great job including quantifiable achievements! This really strengthens your experience section',
        );
      } else {
        suggestions.add(
          'Consider adding specific metrics and numbers to quantify your achievements (e.g., "increased sales by 25%")',
        );
      }
    }
  }

  void _generateSkillsFeedback(
    List<dynamic>? skills,
    List<String> suggestions,
    List<String> strengths,
  ) {
    if (skills == null || skills.isEmpty) {
      suggestions.add('Let\'s add your skills to showcase your capabilities!');
      return;
    }

    final skillCount = skills.length;
    if (skillCount < 5) {
      suggestions.add(
        'You\'ve started listing your skills! Consider adding more (aim for 10-15) to better represent your capabilities',
      );
    } else if (skillCount > 15) {
      strengths.add(
        'Excellent! Your comprehensive skills list demonstrates broad expertise. Great job!',
      );
    } else {
      strengths.add(
        'Good job! Your skills list effectively represents your capabilities',
      );
    }

    bool hasTechnical = false;
    bool hasSoft = false;
    for (final skill in skills) {
      final skillStr = skill.toString().toLowerCase();
      if (_atsKeywords['technical']!.any(
        (k) => skillStr.contains(k.toLowerCase()),
      )) {
        hasTechnical = true;
      }
      if (_atsKeywords['business']!.any(
        (k) => skillStr.contains(k.toLowerCase()),
      )) {
        hasSoft = true;
      }
    }

    if (hasTechnical)
      strengths.add(
        'Great job including technical skills! This will help with ATS compatibility',
      );
    if (hasSoft)
      strengths.add(
        'Excellent! You\'ve included valuable soft skills. This shows your well-rounded abilities',
      );
    if (!hasTechnical)
      suggestions.add(
        'Consider adding technical skills relevant to your industry to improve ATS compatibility',
      );
    if (!hasSoft)
      suggestions.add(
        'Think about including soft skills like communication and leadership to show your well-rounded abilities',
      );
  }

  void _generateProjectsFeedback(
    List<dynamic>? projects,
    List<String> suggestions,
    List<String> strengths,
  ) {
    if (projects == null || projects.isEmpty) {
      suggestions.add(
        'Let\'s add your projects to demonstrate your practical experience!',
      );
      return;
    }

    if (projects.length > 1) {
      strengths.add(
        'Excellent! Multiple projects showcase your diverse experience. Great job!',
      );
    }

    for (final project in projects) {
      if (project is! Map<String, dynamic>) continue;

      final requiredFields = _sectionRequirements['projects']!;
      for (final field in requiredFields) {
        if (project[field]?.toString().trim().isEmpty == true) {
          switch (field) {
            case 'title':
              suggestions.add(
                'Adding a clear project title will highlight your work',
              );
              break;
            case 'description':
              suggestions.add(
                'Include a detailed project description to showcase your contributions',
              );
              break;
          }
        }
      }

      final description = project['description']?.toString() ?? '';
      if (description.split(' ').length < 50) {
        suggestions.add(
          'Your project description is a good start! Consider adding more details about your role and outcomes',
        );
      } else {
        strengths.add(
          'Excellent! Your detailed project description effectively communicates your contributions. Well done!',
        );
      }
    }
  }

  void _generateCertificationsFeedback(
    List<dynamic>? certifications,
    List<String> suggestions,
    List<String> strengths,
  ) {
    if (certifications == null || certifications.isEmpty) {
      suggestions.add(
        'Let\'s add your certifications to demonstrate your commitment to professional development!',
      );
      return;
    }

    if (certifications.length > 1) {
      strengths.add(
        'Excellent! Multiple certifications show your dedication to continuous learning. Great job!',
      );
    }

    for (final cert in certifications) {
      if (cert is! Map<String, dynamic>) continue;

      final requiredFields = _sectionRequirements['certifications']!;
      for (final field in requiredFields) {
        if (cert[field]?.toString().trim().isEmpty == true) {
          switch (field) {
            case 'name':
              suggestions.add(
                'Adding the certification name will highlight your credentials',
              );
              break;
            case 'organization':
              suggestions.add(
                'Include the certifying organization to establish credibility',
              );
              break;
            case 'year':
              suggestions.add(
                'Adding the certification year will show its relevance',
              );
              break;
          }
        }
      }
    }
  }

  String _generateEncouragement(double score) {
    if (score < 60) {
      return 'Don\'t worry! Every great resume starts with a foundation. We\'ll help you build it up step by step.';
    } else if (score < 80) {
      return 'You\'re doing great! Your resume is already quite strong. Let\'s make it even better!';
    } else {
      return 'Outstanding work! Your resume is already very impressive. Keep up the excellent work!';
    }
  }

  // Helper function to get color based on score
  Color _getScoreColor(double score) {
    // Using Material Design 3 color palette with better contrast
    if (score >= 90) {
      return const Color(0xFF1B5E20); // Dark Green - Excellent
    } else if (score >= 80) {
      return const Color(0xFF2E7D32); // Green - Very Good
    } else if (score >= 70) {
      return const Color(0xFF43A047); // Light Green - Good
    } else if (score >= 60) {
      return const Color(0xFFF57F17); // Amber - Average
    } else if (score >= 50) {
      return const Color(0xFFE65100); // Deep Orange - Below Average
    } else if (score >= 40) {
      return const Color(0xFFD84315); // Deep Orange - Poor
    } else {
      return const Color(0xFFB71C1C); // Dark Red - Very Poor
    }
  }

  // Helper function to get text color based on background color
  Color _getTextColor(Color backgroundColor) {
    // Calculate relative luminance
    final luminance =
        (0.299 * backgroundColor.red +
            0.587 * backgroundColor.green +
            0.114 * backgroundColor.blue) /
        255;
    // Return white for dark backgrounds, black for light backgrounds
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  // Helper function to get section color based on score
  Color _getSectionColor(double score) {
    // Using a more subtle color palette for sections
    if (score >= 90) {
      return const Color(0xFFE8F5E9); // Light Green Background
    } else if (score >= 80) {
      return const Color(0xFFF1F8E9); // Very Light Green Background
    } else if (score >= 70) {
      return const Color(0xFFF9FBE7); // Light Lime Background
    } else if (score >= 60) {
      return const Color(0xFFFFFDE7); // Light Yellow Background
    } else if (score >= 50) {
      return const Color(0xFFFFF3E0); // Light Amber Background
    } else if (score >= 40) {
      return const Color(0xFFFFEBEE); // Light Red Background
    } else {
      return const Color(0xFFFFEBEE); // Light Red Background
    }
  }

  // Helper function to get progress indicator color based on score
  Color _getProgressColor(double score) {
    // Using a gradient of colors for progress indicators
    if (score >= 90) {
      return const Color(0xFF1B5E20); // Dark Green
    } else if (score >= 80) {
      return const Color(0xFF2E7D32); // Green
    } else if (score >= 70) {
      return const Color(0xFF43A047); // Light Green
    } else if (score >= 60) {
      return const Color(0xFFF57F17); // Amber
    } else if (score >= 50) {
      return const Color(0xFFE65100); // Deep Orange
    } else if (score >= 40) {
      return const Color(0xFFD84315); // Deep Orange
    } else {
      return const Color(0xFFB71C1C); // Dark Red
    }
  }

  // Helper function to get border color based on score
  Color _getBorderColor(double score) {
    // Using subtle border colors
    if (score >= 90) {
      return const Color(0xFF81C784); // Light Green Border
    } else if (score >= 80) {
      return const Color(0xFFA5D6A7); // Very Light Green Border
    } else if (score >= 70) {
      return const Color(0xFFC5E1A5); // Light Lime Border
    } else if (score >= 60) {
      return const Color(0xFFFFF59D); // Light Yellow Border
    } else if (score >= 50) {
      return const Color(0xFFFFE082); // Light Amber Border
    } else if (score >= 40) {
      return const Color(0xFFFFAB91); // Light Orange Border
    } else {
      return const Color(0xFFEF9A9A); // Light Red Border
    }
  }
}
