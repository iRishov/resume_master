# 📄 Resume Master

A cross-platform Flutter application designed to help job seekers build, analyze, and optimize their resumes using AI-driven insights and real-time feedback.

## 📝 Overview

Resume Master is a comprehensive resume building and optimization platform that helps users create professional resumes with AI-powered insights. The application combines modern technology with user-friendly design to make resume creation and optimization accessible to everyone.

### 🌟 Key Highlights

- **Smart Resume Builder**: Create professional resumes with guided templates and real-time suggestions
- **AI-Powered Analysis**: Get instant feedback on your resume's ATS compatibility and content quality
- **Multi-Platform Support**: Access your resumes from any device (Android, iOS, Web, Windows, macOS)
- **Cloud Storage**: Securely store and manage multiple versions of your resumes
- **Export Options**: Download resumes in multiple formats (PDF, DOCX)
- **Privacy Focused**: Your data is encrypted and stored securely in Firebase

### 🎯 Target Users

- Job seekers looking to create professional resumes
- Students preparing for their first job application
- Professionals updating their career documents
- Career counselors and HR professionals
- Anyone seeking to improve their resume's effectiveness

### 💡 Why Resume Master?

- **User-Friendly Interface**: Intuitive design makes resume creation simple
- **Real-Time Feedback**: Get instant suggestions for improvement
- **ATS Optimization**: Ensure your resume passes automated screening
- **Cloud Backup**: Never lose your resume data
- **Cross-Platform**: Work on your resume from any device
- **Free to Start**: Basic features available at no cost

### 🔄 Development Status

- **Current Version**: 1.0.0
- **Last Updated**: March 2024
- **Active Development**: Yes
- **Open Source**: Yes

## 🚀 Features

- **Multi-Step Resume Builder**: Input personal information, education, work experience, projects, skills, certifications, and summary.
- **Real-Time ATS Analysis**: Evaluate your resume's compatibility with Applicant Tracking Systems.
- **Skill Gap Detection**: Identify missing skills and receive suggestions to enhance your resume.
- **Resume Version Control**: Create, clone, and manage multiple versions of your resume.
- **Job Recommendations**: Receive job suggestions based on your resume content.
- **AI-Powered Suggestions**: Utilize GPT integration for content improvements and bullet point generation.
- **Gamification**: Earn badges and track progress to stay motivated.
- **Admin Panel**: Manage templates, monitor user activity, and analyze resume statistics.

## 🛠️ Tech Stack

- **Frontend**: Flutter with Provider for state management
- **Backend**: Firebase (Authentication, Firestore, Storage)
- **AI/NLP**: Integration with GPT APIs
- **PDF Generation**: Flutter packages like `pdf` and `printing`

## 📋 Prerequisites

Before running this project, make sure you have the following installed:

1. **Flutter SDK** (version 3.19.0 or higher)
   - Download from: https://flutter.dev/docs/get-started/install
   - Add Flutter to your PATH
   - Verify installation: `flutter doctor`

2. **Android Studio** or **VS Code**
   - Android Studio: https://developer.android.com/studio
   - VS Code: https://code.visualstudio.com/
   - Install Flutter and Dart plugins

3. **Firebase CLI**
   - Install using npm: `npm install -g firebase-tools`
   - Login to Firebase: `firebase login`
   - Initialize Firebase: `firebase init`

4. **Google Cloud SDK** (for Google Sign-In functionality)
   - Download from: https://cloud.google.com/sdk/docs/install
   - Initialize: `gcloud init`

## 🚀 Project Setup

1. **Clone the repository**
   ```bash
   git clone [your-repository-url]
   cd resume_master
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project at https://console.firebase.google.com/
   - Enable Authentication with Email/Password and Google Sign-In
   - Enable Cloud Firestore
   - Enable Storage
   - Download `google-services.json` and place it in `android/app/`
   - Download `GoogleService-Info.plist` and place it in `ios/Runner/`

4. **Configure Google Sign-In**
   - Go to Google Cloud Console
   - Enable Google Sign-In API
   - Configure OAuth consent screen
   - Add SHA-1 and SHA-256 fingerprints to Firebase project
   - Get SHA-1: `cd android && ./gradlew signingReport`

## 📦 Dependencies

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

## 🏃‍♂️ Running the App

1. **Connect a device or start an emulator**
   ```bash
   flutter devices  # List available devices
   flutter emulators --launch <emulator_id>  # Launch emulator
   ```

2. **Run the app**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── main.dart                 # Entry point
├── screens/                  # UI screens
│   ├── home.dart            # Home screen
│   ├── profile_page.dart    # User profile
│   ├── resume_editor.dart   # Resume creation/editing
│   ├── resume_preview.dart  # Resume preview
│   └── startup.dart         # Initial screen
├── services/                # Business logic
│   ├── auth_service.dart    # Authentication
│   ├── firebase_service.dart # Firebase operations
│   └── database.dart        # Database operations
├── models/                  # Data models
│   └── resume_model.dart    # Resume data structure
└── widgets/                 # Reusable components
    ├── resume_card.dart     # Resume card widget
    └── resume_form.dart     # Form components
```

## 🔧 Troubleshooting

1. **Firebase Configuration Issues**
   - Ensure `google-services.json` and `GoogleService-Info.plist` are properly placed
   - Verify Firebase project settings match the configuration files
   - Check Firebase console for any service disruptions

2. **Google Sign-In Issues**
   - Check SHA-1 and SHA-256 fingerprints in Firebase console
   - Verify OAuth consent screen configuration
   - Ensure Google Sign-In API is enabled
   - Check if test users are added (if in testing)

3. **Build Issues**
   - Run `flutter clean`
   - Run `flutter pub get`
   - Ensure all dependencies are compatible
   - Check Flutter version compatibility
   - Clear build cache: `flutter clean && flutter pub get`

4. **Common Runtime Issues**
   - Check internet connectivity
   - Verify Firebase project is active
   - Ensure all required permissions are granted
   - Check device compatibility

## 📱 Platform Support

- Android (API level 21 and above)
- iOS (iOS 11.0 and above)
- Web (Chrome, Firefox, Safari)
- Windows (Windows 10 and above)
- macOS (macOS 10.14 and above)

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

For any issues or questions:
- Create an issue in the repository
- Contact the development team
- Check the [FAQ](docs/FAQ.md) for common questions
