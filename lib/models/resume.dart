import 'package:cloud_firestore/cloud_firestore.dart';
import 'experience.dart';
import 'education.dart';
import 'project.dart';
import 'certification.dart';

class Resume {
  String id;
  String userId;
  Map<String, dynamic> personalInfo;
  String summary;
  String objective;
  List<String> skills;
  List<String> languages;
  List<Experience> experiences;
  List<Education> education;
  List<Project> projects;
  List<Certification> certifications;
  String hobbies;
  DateTime? createdAt;
  DateTime? updatedAt;
  String title;

  Resume({
    this.id = '',
    required this.userId,
    required this.personalInfo,
    required this.summary,
    required this.objective,
    required this.skills,
    required this.languages,
    required this.experiences,
    required this.education,
    required this.projects,
    required this.certifications,
    required this.hobbies,
    this.createdAt,
    this.updatedAt,
    required this.title,
  });

  factory Resume.fromMap(Map<String, dynamic> map, {String id = ''}) => Resume(
    id: id,
    userId: map['userId'] ?? '',
    personalInfo: Map<String, dynamic>.from(map['personalInfo'] ?? {}),
    summary: map['summary'] ?? '',
    objective: map['objective'] ?? '',
    skills: List<String>.from(map['skills'] ?? []),
    languages: List<String>.from(map['languages'] ?? []),
    experiences:
        (map['experiences'] as List? ?? [])
            .map((e) => Experience.fromMap(e))
            .toList(),
    education:
        (map['education'] as List? ?? [])
            .map((e) => Education.fromMap(e))
            .toList(),
    projects:
        (map['projects'] as List? ?? [])
            .map((e) => Project.fromMap(e))
            .toList(),
    certifications:
        (map['certifications'] as List? ?? [])
            .map((e) => Certification.fromMap(e))
            .toList(),
    hobbies: map['hobbies'] ?? '',
    createdAt:
        map['createdAt'] != null
            ? (map['createdAt'] is Timestamp
                ? (map['createdAt'] as Timestamp).toDate()
                : map['createdAt'])
            : null,
    updatedAt:
        map['updatedAt'] != null
            ? (map['updatedAt'] is Timestamp
                ? (map['updatedAt'] as Timestamp).toDate()
                : map['updatedAt'])
            : null,
    title: map['title'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'personalInfo': personalInfo,
    'summary': summary,
    'objective': objective,
    'skills': skills,
    'languages': languages,
    'experiences': experiences.map((e) => e.toMap()).toList(),
    'education': education.map((e) => e.toMap()).toList(),
    'projects': projects.map((e) => e.toMap()).toList(),
    'certifications': certifications.map((e) => e.toMap()).toList(),
    'hobbies': hobbies,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'title': title,
  };
}
