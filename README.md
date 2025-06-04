📄 Resume Master

A cross-platform Flutter application designed to help job seekers build, analyze, and optimize their resumes using AI-driven insights and real-time feedback.

📝 Overview

Resume Master is a comprehensive resume building and optimization platform that helps users create professional resumes with AI-powered insights. The application combines modern technology with user-friendly design to make resume creation and optimization accessible to everyone.

🌟 Key Highlights

- Smart Resume Builder: Create professional resumes with guided templates and real-time suggestions
- AI-Powered Analysis: Get instant feedback on your resume's ATS compatibility and content quality
- Multi-Platform Support: Access your resumes from any device (Android, iOS, Web, Windows, macOS)
- Cloud Storage: Securely store and manage multiple versions of your resumes
- Export Options: Download resumes in multiple formats (PDF, DOCX)
- Privacy Focused: Your data is encrypted and stored securely in Firebase

🎯 Target Users

- Job seekers looking to create professional resumes
- Students preparing for their first job application
- Professionals updating their career documents
- Career counselors and HR professionals
- Anyone seeking to improve their resume's effectiveness

💡 Why Resume Master?

- User-Friendly Interface: Intuitive design makes resume creation simple
- Real-Time Feedback: Get instant suggestions for improvement
- ATS Optimization: Ensure your resume passes automated screening
- Cloud Backup: Never lose your resume data
- Cross-Platform: Work on your resume from any device
- Free to Start: Basic features available at no cost

🔄 Development Status

- Current Version: 1.0.0
- Last Updated: March 2024
- Active Development: Yes
- Open Source: Yes

🚀 Features

- Multi-Step Resume Builder: A guided process through various sections like personal information, education, work experience, projects, skills, certifications, and summary, managed primarily through `lib/screens/resume_form_page.dart`.
- Real-Time ATS Analysis: Evaluates your resume's compatibility with Applicant Tracking Systems by analyzing keyword usage and density, with the core logic in `lib/services/resume_scoring_service.dart`.
- Skill Gap Detection: Identifies potential missing skills based on resume content and suggests relevant skills to add, integrated within the resume analysis process in `lib/services/resume_scoring_service.dart`.
- Resume Version Control: Allows users to create, clone, and manage multiple versions of their resume, likely handled through data models in `lib/models/resume.dart` and Firebase services in `lib/services/firebase_service.dart`.
- Job Recommendations: Provides job suggestions potentially based on the skills and experience listed in the resume, which would involve backend logic possibly within `lib/services/firebase_service.dart` or a dedicated service.
- AI-Powered Suggestions: Utilizes GPT APIs for enhancing content, suggesting bullet points, and improving overall resume quality, with integration logic likely in `lib/services/resume_scoring_service.dart` or a separate AI service file.
- Gamification: Incorporates elements like earning badges and tracking progress to motivate users, which would involve UI components and state management, possibly reflected in screens like `lib/screens/home.dart` or profile related files.
- Admin Panel: A separate interface for administrators to manage templates, monitor user activity, and analyze resume statistics, likely residing in dedicated admin-specific files or sections not detailed in the main project structure for the user-facing app.

🛠️ Tech Stack

- Frontend: Flutter framework for cross-platform development, utilizing Provider for state management (`provider: ^6.1.1`).
- Backend: Firebase for various backend services:
  - Authentication (`firebase_auth: ^4.15.3`) for user management (login, signup, etc.).
  - Cloud Firestore (`cloud_firestore: ^4.13.6`) for storing structured data like resume details.
  - Storage (`firebase_storage: ^11.5.6`) for storing files, possibly resume exports.
- AI/NLP: Integration with GPT APIs for intelligent resume analysis and suggestions.
- PDF Generation: Flutter packages like `pdf: ^3.10.7` and `printing` (often used together, though `printing` is not explicitly listed in dependencies but is commonly used with `pdf`) for generating PDF versions of resumes.
- Other Key Dependencies:
  - `google_sign_in: ^6.1.6`: For Google Sign-In functionality.
  - `intl: ^0.19.0`: For internationalization and localization.
  - `path_provider: ^2.1.1`: For accessing file system paths.
  - `share_plus: ^7.2.1`: For sharing functionality.
  - `image_picker: ^1.0.5`: For picking images, potentially for profile pictures or resume elements.
  - `flutter_spinkit: ^5.2.0`: For loading indicators.
  - `flutter_svg: ^2.0.9`: For rendering SVG images.
  - `url_launcher: ^6.2.2`: For launching URLs.

📋 Prerequisites

Before running this project, make sure you have the following installed:

1. Flutter SDK (version 3.19.0 or higher)

   - Download from: https://flutter.dev/docs/get-started/install
   - Add Flutter to your PATH
   - Verify installation: `flutter doctor`

2. Android Studio or VS Code

   - Android Studio: https://developer.android.com/studio
   - VS Code: https://code.visualstudio.com/
   - Install Flutter and Dart plugins

3. Firebase CLI

   - Install using npm: `npm install -g firebase-tools`
   - Login to Firebase: `firebase login`
   - Initialize Firebase: `firebase init`

4. Google Cloud SDK (for Google Sign-In functionality)
   - Download from: https://cloud.google.com/sdk/docs/install
   - Initialize: `gcloud init`

🚀 Project Setup

1. Clone the repository

   ```bash
   git clone [your-repository-url]
   cd resume_master
   ```

2. Install dependencies

   ```bash
   flutter pub get
   ```

3. Firebase Setup

   - Create a new Firebase project at https://console.firebase.google.com/
   - Enable Authentication with Email/Password and Google Sign-In
   - Enable Cloud Firestore
   - Enable Storage
   - Download `google-services.json` and place it in `android/app/`
   - Download `GoogleService-Info.plist` and place it in `ios/Runner/`

4. Configure Google Sign-In
   - Go to Google Cloud Console
   - Enable Google Sign-In API
   - Configure OAuth consent screen
   - Add SHA-1 and SHA-256 fingerprints to Firebase project
   - Get SHA-1: `cd android && ./gradlew signingReport`

📦 Dependencies

The project uses the following main dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  firebase_storage: ^11.5.6
  google_sign_in: ^6.1.6
  provider: ^6.1.1
  intl: ^0.19.0
  pdf: ^3.10.7
  path_provider: ^2.1.1
  share_plus: ^7.2.1
  image_picker: ^1.0.5
  flutter_spinkit: ^5.2.0
  flutter_svg: ^2.0.9
  url_launcher: ^6.2.2
```

🏃‍♂️ Running the App

1. Connect a device or start an emulator

   ```bash
   flutter devices   List available devices
   flutter emulators --launch <emulator_id>   Launch emulator
   ```

2. Run the app

   ```bash
   flutter run
   ```

📁 Project Structure

```
lib/
├── main.dart                  Application entry point and initial setup
├── screens/                   Contains the main UI screens of the application
│   ├── home.dart             The main dashboard or home screen
│   ├── profile_page.dart     Screen for user profile management
│   ├── resume_form_page.dart  Multi-step form for creating and editing resumes
│   ├── resume_preview.dart   Screen to preview the generated resume
│   ├── resume_score_screen.dart  Screen displaying the resume score and feedback
│   ├── login.dart             User login screen
│   ├── signup.dart            User signup screen
│   ├── startup.dart           Initial startup screen (e.g., checking auth status)
│   ├── splash.dart            Splash screen
│   └── forgot_password.dart   Forgot password screen
├── services/                  Houses business logic, APIs, and external interactions
│   ├── auth_service.dart     Handles user authentication operations
│   ├── firebase_service.dart  Provides methods for interacting with Firebase services
│   ├── pdf_service.dart       Manages PDF generation for resumes
│   ├── resume_scoring_service.dart  Contains the logic for scoring resumes and providing feedback
│   └── database.dart         Abstract layer for database operations (can be using Firebase internally)
├── models/                    Defines the data structures used throughout the application
│   ├── resume.dart            Data model for a resume, including all its sections
│   ├── experience.dart        Data model for a work experience entry
│   ├── education.dart         Data model for an education entry
│   ├── project.dart           Data model for a project entry
│   └── certification.dart     Data model for a certification entry
├── widgets/                   Reusable UI components used across different screens
│   ├── bottom_nav_bar.dart    Custom bottom navigation bar
│   ├── skill_widgets.dart     Widgets specifically for skill selection and display
│   ├── certification_card.dart  Widget to display and edit a single certification entry
│   ├── project_card.dart      Widget to display and edit a single project entry
│   ├── education_card.dart    Widget to display and edit a single education entry
│   ├── experience_card.dart   Widget to display and edit a single work experience entry
│   └── form_fields.dart       Reusable custom form fields
└── theme/                     Defines the application's theme, colors, and typography
```

📊 Resume Scoring Logic

The application includes a comprehensive resume scoring system to provide users with feedback on their resume's effectiveness and ATS compatibility. The core logic resides in the `lib/services/resume_scoring_service.dart` file.

How Scoring Works:

1. Section Weights: Different sections of the resume are assigned specific weights (`_sectionWeights`) to determine their contribution to the overall score. Sections like 'experience' and 'skills' typically have higher weights.
   ```dart
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
   ```
2. Section Scoring: Each individual section of the resume is evaluated based on its completeness and content details:
   - Completeness: Points are awarded based on whether the required fields for that section are filled out. The `_sectionRequirements` map defines the essential fields for each section.
     ```dart
     static const Map<String, List<String>> _sectionRequirements = {
       'personalInfo': ['fullName', 'email', 'phone', 'address'],
       'summary': ['summary'],
       'education': ['degree', 'institution', 'year', 'description'], // Description adds value but might not be strictly required for a basic score
       'experience': ['jobTitle', 'company', 'duration', 'description'], // Description adds value
       'skills': ['skills'], // Presence of skills list
       'projects': ['title', 'description'], // Description adds value
       'certifications': ['name', 'organization', 'year'],
     };
     ```
   - For sections with lists (Experience, Education, Projects, Certifications), the score considers if the list is not empty and if individual entries within the list have their required fields filled. The presence of optional details (like descriptions) also adds points.
   - Some sections may receive bonus points for having multiple entries (e.g., more than one education or experience). The exact point division per field and bonus logic is implemented within the scoring service methods (e.g., `_scoreExperience`, `_scoreEducation`, etc.).
3. ATS Compatibility Scoring: This score assesses how well the resume is optimized for Applicant Tracking Systems. It does this by analyzing the resume text for the presence and relevance of industry-specific keywords defined in the `_atsKeywords` map. A higher density and better match to relevant keywords result in a higher ATS score.
   ```dart
   static const Map<String, List<String>> _atsKeywords = {
     'technical': [...],
     'business': [...],
     'design': [...],
   };
   ```
4. Total Score Calculation: The final resume score (out of 100) is calculated as a weighted average of the scores from all individual sections (including ATS compatibility), using the weights defined in `_sectionWeights`. The formula is essentially:
   `Total Score = Σ (Section Score * Section Weight) / Σ (Section Weight)` (then scaled to 100).
5. Feedback Generation: Based on the scores, the service generates detailed feedback, including specific suggestions for improvement for each section and overall tips to enhance the resume's impact. It also highlights the strengths of the current resume.

This scoring system is designed to provide actionable insights to help users create resumes that are both informative for recruiters and optimized for automated screening tools.

🔧 Troubleshooting

1. Firebase Configuration Issues

   - Ensure `google-services.json` and `GoogleService-Info.plist` are properly placed
   - Verify Firebase project settings match the configuration files
   - Check Firebase console for any service disruptions

2. Google Sign-In Issues

   - Check SHA-1 and SHA-256 fingerprints in Firebase console
   - Verify OAuth consent screen configuration
   - Ensure Google Sign-In API is enabled
   - Check if test users are added (if in testing)

3. Build Issues

   - Run `flutter clean`
   - Run `flutter pub get`
   - Ensure all dependencies are compatible
   - Check Flutter version compatibility
   - Clear build cache: `flutter clean && flutter pub get`

4. Common Runtime Issues
   - Check internet connectivity
   - Verify Firebase project is active
   - Ensure all required permissions are granted
   - Check device compatibility

📱 Platform Support

- Android (API level 21 and above)
- iOS (iOS 11.0 and above)
- Web (Chrome, Firefox, Safari)
- Windows (Windows 10 and above)
- macOS (macOS 10.14 and above)

🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request
