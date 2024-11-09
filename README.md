# DiaryKuh - Your Personal Digital Diary App

## Description

DiaryKuh is a digital diary application that enables users to record their daily experiences through text notes, photos, and voice recordings.

## Key Features

- 📝 Text Notes
- 📸 Photo Diary
- 🎤 Voice Notes
- 🔐 Authentication
- 🌓 Dark/Light Theme
- 💾 Offline Storage

## Project Structure

```bash
lib/
│
├── common/                           # Reusable components and widgets
│   ├── custom_form_button.dart       # Custom button widget for forms
│   ├── custom_input_field.dart       # Custom input field widget for forms
│   ├── page_header.dart              # Common header widget for pages
│   └── page_heading.dart             # Common heading widget for pages
│
├── data/                             # Data layer containing data sources
│   └── database_helper.dart          # SQLite database helper for local storage
│
├── models/                           # Data models or entities
│   ├── note_model.dart               # Model class for diary notes
│   └── user_model.dart               # Model class for user data
│
├── presentation/                     # UI layer containing all app screens
│   ├── auth/                         # Authentication-related screens
│   │   ├── forget_password_page.dart # Password recovery screen
│   │   ├── login_page.dart           # Login screen
│   │   └── signup_page.dart          # Registration screen
│   │
│   ├── home/                         # Home screen-related files
│   │   └── home_page.dart            # Main home screen of the app
│   │
│   ├── note/                         # Note management screens
│   │   ├── note_detail_page.dart     # Note details/viewing screen
│   │   └── note_page.dart            # Note creation/editing screen
│   │
│   ├── photo/                        # Photo diary-related screens
│   │   ├── photo_detail_page.dart    # Photo viewing screen
│   │   └── photo_page.dart           # Photo capture/upload screen
│   │
│   ├── splash/                       # Splash screen
│   │   └── splash_page.dart          # Initial loading screen
│   │
│   └── voice/                        # Voice note-related screens
│       └── voice_page.dart           # Voice recording/playback screen
│
├── routes/                           # Navigation and routing
│   └── routes.dart                   # Route definitions and navigation logic
│
├── utils/                            # Utility classes and helpers
│   ├── color_utils.dart              # Color constants and theme colors
│   ├── theme_manager.dart            # Theme management utilities
│   └── firebase_options.dart         # Firebase configuration options
│
└── main.dart                         # Application entry point


```

## Technical Specifications

### Prerequisites

- Flutter SDK: ^3.0.0
- Dart SDK: ^2.17.0
- Android Studio / VS Code
- iOS Simulator / Android Emulator

### Dependencies

dependencies:
flutter:
sdk: flutter
sqflite: ^2.0.0 # Local database
provider: ^6.0.0 # State management
firebase_core: ^2.0.0 # Firebase core
firebase_auth: ^4.0.0 # Authentication
image_picker: ^0.8.0 # Image capture/selection
audio_recorder: ^1.0.0 # Voice recording
path_provider: ^2.0.0 # File system access

## Installation

1. Clone the repository:

```bash
   git clone https://github.com/jodypangaribuan/diarykuh.git
```

2. Navigate to project directory:

```bash
   cd diarykuh
```

3. Install dependencies:

```bash
   flutter pub get
```

4. Run the app:

```bash
   flutter run
```

## Architecture

The app follows a clean architecture pattern with clear separation of concerns:

- **Data Layer**: Handles data operations and persistence
- **Domain Layer**: Contains business logic and models
- **Presentation Layer**: Manages UI and user interactions

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

## Contact

Jody Pangaribuan - [@jodypangaribuan](https://github.com/jodypangaribuan)
Project Link: [https://github.com/jodypangaribuan/diarykuh](https://github.com/jodypangaribuan/diarykuh)
