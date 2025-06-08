# Resume Master

A cross-platform Flutter application designed to help job seekers build, analyze, and optimize their resumes using AI-driven insights and real-time feedback.

## Overview

Resume Master is a comprehensive resume building and optimization platform that helps users create professional resumes with AI-powered insights. The application combines modern technology with user-friendly design to make resume creation and optimization accessible to everyone.

## Key Features

- Smart Resume Builder: Create professional resumes with guided templates and real-time suggestions
- AI-Powered Analysis: Get instant feedback on your resume's ATS compatibility and content quality
- Multi-Platform Support: Access your resumes from any device (Android, iOS, Web, Windows, macOS)
- Cloud Storage: Securely store and manage multiple versions of your resumes
- Export Options: Download resumes in multiple formats (PDF, DOCX)
- Privacy Focused: Your data is encrypted and stored securely in Firebase
- Real-time Progress Tracking: Visual indicators for resume completion
- Smart Keyboard Handling: Optimized form navigation and input experience
- Responsive Design: Adapts to different screen sizes and orientations
- Offline Support: Basic functionality available without internet connection

## Tech Stack

- Frontend: Flutter framework
- State Management: Provider
- Backend: Firebase
  - Authentication
  - Cloud Firestore
  - Storage
- PDF Generation: pdf package
- Local Storage: Shared Preferences
- UI Components: Material Design 3

## Project Structure

```
lib/
├── main.dart                  # Application entry point
├── screens/                   # UI screens
│   ├── user/                 # User-facing screens
│   │   ├── home.dart         # Dashboard
│   │   ├── profile_page.dart # Profile management
│   │   ├── resume_form_page.dart # Resume creation/editing
│   │   ├── resume_preview.dart # Resume preview
│   │   └── resume_score_screen.dart # Resume analysis
│   └── auth/                 # Authentication screens
│       ├── login.dart
│       ├── signup.dart
│       └── forgot_password.dart
├── services/                  # Business logic
│   ├── firebase_service.dart # Firebase operations
│   ├── resume_scoring_service.dart # Resume analysis
│   └── pdf_service.dart      # PDF generation
├── models/                    # Data models
│   ├── resume.dart           # Resume model
│   ├── experience.dart       # Experience model
│   ├── education.dart        # Education model
│   ├── project.dart          # Project model
│   └── certification.dart    # Certification model
├── widgets/                   # Reusable components
│   ├── form_fields.dart      # Custom form fields
│   ├── experience_card.dart  # Experience card
│   ├── education_card.dart   # Education card
│   ├── project_card.dart     # Project card
│   └── certification_card.dart # Certification card
└── theme/                     # App theming
    ├── colors.dart
    └── typography.dart
```

## Data Schema

### Resume Model

```dart
class Resume {
String id;
String userId;
Map<String, dynamic> personalInfo; // name, email, phone, etc.
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
}
```

### Experience Model

     ```dart

class Experience {
String jobTitle;
String company;
String duration;
String description;
DateTime? startDate;
DateTime? endDate;
bool isCurrent;
}

````

### Education Model

   ```dart
class Education {
  String degree;
  String institution;
  String year;
  String description;
  String fieldOfStudy;
  String grade;
}
````

### Project Model

```dart
class Project {
  String title;
  String description;
  String technologies;
  String duration;
  String url;
}
```

### Certification Model

```dart
class Certification {
  String name;
  String organization;
  String year;
  String credentialId;
  String url;
}
```

## Getting Started

1. Clone the repository
2. Install dependencies: `flutter pub get`
3. Configure Firebase
4. Run the app: `flutter run`

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting pull requests.

## Support

For support, email support@resumemaster.com or join our Discord community.
