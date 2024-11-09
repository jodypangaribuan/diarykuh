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
├── common/
│   ├── custom_form_button.dart
│   ├── custom_input_field.dart
│   ├── page_header.dart
│   └── page_heading.dart
├── data/
│   └── database_helper.dart
├── models/
│   ├── note_model.dart
│   └── user_model.dart
├── presentation/
│   ├── auth/
│   │   ├── forget_password_page.dart
│   │   ├── login_page.dart
│   │   └── signup_page.dart
│   ├── home/
│   │   └── home_page.dart
│   ├── note/
│   │   ├── note_detail_page.dart
│   │   └── note_page.dart
│   ├── photo/
│   │   ├── photo_detail_page.dart
│   │   └── photo_page.dart
│   ├── splash/
│   │   └── splash_page.dart
│   └── voice/
│       └── voice_page.dart
├── routes/
│   └── routes.dart
├── utils/
│   ├── color_utils.dart
│   ├── theme_manager.dart
│   └── firebase_options.dart
└── main.dart

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
   git clone https://github.com/yourusername/diarykuh.git

2. Navigate to project directory:
   cd diarykuh

3. Install dependencies:
   flutter pub get

4. Run the app:
   flutter run

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

Your Name - [@yourusername](https://twitter.com/yourusername)
Project Link: [https://github.com/yourusername/diarykuh](https://github.com/yourusername/diarykuh)
