# Resume Master

A professional resume creation and management application built with Flutter, featuring both job_seeker and recruiter interfaces.

## Why Use This App?

1. **Professional Resume Creation**

   - Create ATS-friendly resumes that stand out to employers
   - Multiple professional templates to choose from
   - Real-time resume scoring and improvement suggestions
   - Export to PDF format for easy sharing

2. **Career Management**

   - Track your job applications in one place
   - Receive job recommendations based on your profile
   - Keep your professional information up-to-date
   - Manage multiple versions of your resume

3. **Recruiter Benefits**

   - Post job listings with detailed requirements
   - Access to a pool of qualified candidates
   - Streamlined application review process
   - Direct communication with applicants

4. **job_seeker-Friendly Interface**
   - Intuitive design for easy navigation
   - Step-by-step resume building process
   - Mobile-first approach for on-the-go updates
   - Cross-platform availability (Web, Android, iOS)

## Technology Stack

- **Framework**: Flutter
- **Language**: Dart (SDK version >=3.7.2)
- **Backend**: Firebase
- **Database**: Cloud Firestore
- **Authentication**: Firebase Auth
- **Storage**: Firebase Storage

## Features

### job_seeker Features

1. **Authentication**

   - Email/Password login
   - Google Sign-in
   - Secure job_seeker registration

2. **Resume Management**

   - Create and edit professional resumes
   - Multiple resume templates
   - PDF export functionality
   - Resume scoring system

3. **Profile Management**

   - Personal information management
   - Education history
   - Work experience
   - Certifications
   - Projects

4. **Job Search**
   - Browse available jobs
   - Apply to positions
   - Track applications

### Recruiter Features

1. **Authentication**

   - Dedicated recruiter login
   - Secure registration

2. **Job Management**

   - Post new job listings
   - Edit existing job posts
   - View applications

3. **Profile Management**
   - Company information
   - Recruiter profile settings

## Database Structure

### Collections

1. **Job Seeker**

   - Personal information
   - Authentication details
   - Profile settings

2. **Resumes**

   - Personal details
   - Education history
   - Work experience
   - Skills
   - Certifications
   - Projects

3. **Jobs**

   - Job title
   - Company details
   - Requirements
   - Location
   - Salary
   - Posted date

4. **Applications**
   - Job reference
   - Applicant details
   - Application status
   - Applied date

## File Structure

```
lib/
├── screens/                    # UI Screens and Pages
│   ├── splash.dart            # Splash screen with animations
│   ├── startup.dart           # Initial app screen with job_seeker/recruiter choice
│   ├── job_seeker/                  # job_seeker-specific screens
│   │   ├── home.dart         # Main job_seeker dashboard
│   │   ├── login.dart        # job_seeker authentication
│   │   ├── signup.dart       # job_seeker registration
│   │   ├── profile_page.dart # job_seeker profile management
│   │   └── resume_score.dart # Resume analysis and scoring
│   └── recruiter/            # Recruiter-specific screens
│       ├── recruiter_home.dart      # Recruiter dashboard
│       ├── recruiter_login.dart     # Recruiter authentication
│       ├── recruiter_signup.dart    # Recruiter registration
│       ├── recruiter_profile.dart   # Recruiter profile management
│       └── job_posting_page.dart    # Job posting interface
│
├── services/                  # Business Logic and Services
│   ├── auth_service.dart     # Authentication and job_seeker management
│   ├── firebase_service.dart # Firebase configuration and setup
│   ├── pdf_service.dart      # PDF generation and handling
│   ├── resume_scoring_service.dart # Resume analysis and scoring logic
│   └── database.dart         # Database operations and queries
│
├── models/                   # Data Models
│   ├── resume.dart          # Resume data structure
│   ├── experience.dart      # Work experience model
│   ├── certification.dart   # Certification model
│   ├── project.dart        # Project model
│   └── education.dart      # Education model
│
├── widgets/                 # Reusable UI Components
│   ├── experience_card.dart    # Work experience display card
│   ├── education_card.dart     # Education history card
│   ├── certification_card.dart # Certification display card
│   ├── project_card.dart       # Project showcase card
│   ├── skill_widgets.dart      # Skills display and management
│   ├── bottom_nav_bar.dart     # Navigation bar component
│   └── form_fields.dart        # Custom form input fields
│
├── theme/                  # App Theming
│   └── app_theme.dart     # Theme configuration and styles
│
└── main.dart              # Application entry point

```

### Architecture Overview

The application follows a clean architecture pattern with:

1. **Presentation Layer** (screens/ and widgets/)

   - UI components and screens
   - job_seeker interaction handling
   - State management

2. **Business Logic Layer** (services/)

   - Authentication logic
   - Data processing
   - PDF generation
   - Resume scoring

3. **Data Layer** (models/)

   - Data structures
   - Model definitions
   - Data validation

4. **Infrastructure Layer**
   - Firebase integration
   - Database operations
   - File handling

## Data Schema

### Resume Model

```dart
{
  id: String,                    // Unique identifier
  job_seekerId: String,                // Reference to job_seeker
  personalInfo: {               // Personal information
    fullName: String,
    email: String,
    phone: String,
    address: String,
    city: String,
    state: String,
    country: String,
    zipCode: String,
    linkedinUrl: String,
    githubUrl: String,
    portfolioUrl: String,
    profilePicture: String
  },
  summary: String,              // Professional summary
  objective: String,            // Career objective
  skills: List<String>,        // Technical and soft skills
  languages: List<String>,     // Language proficiencies
  experiences: List<Experience>, // Work experience
  education: List<Education>,   // Educational background
  projects: List<Project>,      // Project portfolio
  certifications: List<Certification>, // Professional certifications
  hobbies: String,             // Personal interests
  createdAt: DateTime,         // Creation timestamp
  updatedAt: DateTime,         // Last update timestamp
  title: String                // Resume title
}
```

### Experience Model

```dart
{
  jobTitle: String,     // Job position/title
  company: String,      // Company name
  duration: String,     // Employment duration
  description: String   // Job responsibilities and achievements
}
```

### Education Model

```dart
{
  degree: String,       // Degree or qualification
  institution: String,  // Educational institution
  year: String,        // Year of completion
  description: String  // Additional details or achievements
}
```

### Certification Model

```dart
{
  name: String,         // Certification name
  organization: String, // Issuing organization
  year: String         // Year of certification
}
```

### Project Model

```dart
{
  title: String,       // Project title
  description: String  // Project description and details
}
```

### Database Collections

1. **job_seekers**

   ```dart
   {
     uid: String,              // Firebase Auth UID
     email: String,            // job_seeker email
     displayName: String,      // job_seeker's full name
     photoURL: String,         // Profile picture URL
     role: String,            // 'job_seeker' or 'recruiter'
     createdAt: DateTime,     // Account creation date
     lastLogin: DateTime      // Last login timestamp
   }
   ```

2. **resumes**

   ```dart
   {
     id: String,              // Auto-generated ID
     job_seekerId: String,          // Reference to job_seeker
     title: String,           // Resume title
     content: Resume,         // Resume data structure
     isPublic: Boolean,       // Visibility setting
     createdAt: DateTime,     // Creation date
     updatedAt: DateTime,     // Last update date
     template: String,        // Selected template
     score: Number           // Resume score
   }
   ```

3. **jobs**

   ```dart
   {
     id: String,              // Auto-generated ID
     recruiterId: String,     // Reference to recruiter
     title: String,           // Job title
     company: String,         // Company name
     location: String,        // Job location
     type: String,           // Full-time, Part-time, etc.
     description: String,     // Job description
     requirements: List<String>, // Job requirements
     salary: String,         // Salary range
     postedAt: DateTime,     // Posting date
     deadline: DateTime,     // Application deadline
     status: String         // Active, Closed, etc.
   }
   ```

4. **applications**
   ```dart
   {
     id: String,              // Auto-generated ID
     jobId: String,           // Reference to job
     job_seekerId: String,          // Reference to applicant
     resumeId: String,        // Reference to resume
     status: String,          // Applied, Reviewed, etc.
     appliedAt: DateTime,     // Application date
     updatedAt: DateTime      // Last status update
   }
   ```

### Database Relationships

1. **job_seeker to Resume**: One-to-Many

   - A job_seeker can have multiple resumes
   - Each resume belongs to one job_seeker

2. **job_seeker to Application**: One-to-Many

   - A job_seeker can submit multiple applications
   - Each application belongs to one job_seeker

3. **Job to Application**: One-to-Many

   - A job can receive multiple applications
   - Each application is for one job

4. **Resume to Application**: One-to-Many
   - A resume can be used for multiple applications
   - Each application uses one resume

## Getting Started

1. Clone the repository
2. Install Flutter SDK (version >=3.7.2)
3. Run `flutter pub get` to install dependencies
4. Configure Firebase project and add necessary credentials
5. Run the app using `flutter run`

## Platform Support

- Android
- iOS
- Web

## Security

- Firebase Authentication for secure job_seeker management
- Secure data storage in Cloud Firestore
- Protected API keys and sensitive information
- Role-based access control for job_seekers and recruiters
