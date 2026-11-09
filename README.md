# Medify - Medicine Reminder & Tracker

Never miss your medicine with Medify, a simple and accessible medicine reminder app designed for everyone, especially elderly users.

## ✨ Status: Ready for Play Store Submission! 🎉

**Current Version:** 1.0.0  
**Status:** ✅ Production Ready with Professional UI & Branding

### What's Working

- ✅ Complete Medicine CRUD operations
- ✅ Medicine intake timing (before/after food, etc.)
- ✅ Today's Schedule with progress tracking
- ✅ Local notifications (iOS & Android, foreground & background)
- ✅ Onboarding flow for first-time users
- ✅ Settings page with theme & notification preferences
- ✅ Beautiful Teal-themed UI with Nunito typography
- ✅ Today's Summary Card with gradient background
- ✅ Accessibility-first design (44px tap targets, high contrast)
- ✅ Light & Dark mode support with persistence
- ✅ Native splash screen with Medify branding
- ✅ Custom app icon and notification icon
- ✅ Professional Android branding

## 📚 Documentation

### Quick Links

- **[Privacy Policy](PRIVACY_POLICY.md)** - App privacy policy (hosted at [GitHub Pages](https://sumit-piston.github.io/medify/PRIVACY_POLICY))

### Play Store Deployment Guides

All deployment documentation is in [`docs/`](docs/):

- **[Build Success Summary](docs/BUILD_SUCCESS_SUMMARY.md)** - 🎉 Complete guide for Play Store upload
- **[Play Store Submission Guide](docs/PLAY_STORE_SUBMISSION_GUIDE.md)** - Detailed step-by-step submission process
- **[Play Store Checklist](docs/PLAY_STORE_CHECKLIST.md)** - Complete pre-launch checklist
- **[Quick Start Release](docs/QUICK_START_RELEASE.md)** - Fast-track release build guide
- **[Step-by-Step Guide](docs/STEP_BY_STEP_GUIDE.md)** - Interactive deployment walkthrough
- **[Keystore Setup](docs/KEYSTORE_SETUP_INSTRUCTIONS.md)** - App signing and keystore management

### Technical Documentation

- **[Project Structure](docs/PROJECT_STRUCTURE.md)** - Architecture and folder organization
- **[GitHub Pages Setup](docs/GITHUB_PAGES_SETUP.md)** - Privacy policy hosting instructions

## 🎯 Features

- **Medicine Management**: Add, edit, and delete medications easily with intake timing options
- **Smart Reminders**: Get timely notifications for all your medications (foreground & background)
- **Today's Schedule**: View all doses for today with progress tracking
- **Progress Visualization**: See your adherence with progress bars and percentages
- **Today's Summary Card**: Beautiful gradient card showing next dose and progress
- **Onboarding Flow**: Friendly 3-screen introduction for first-time users
- **Settings & Preferences**: Customize theme, notifications, and snooze duration
- **Accessibility**: Large buttons (56px), clear typography, and high contrast
- **Dark Mode**: Full dark mode support with Teal color scheme and theme persistence
- **Native Splash Screen**: Professional branded splash screen (light & dark)
- **Offline First**: All data stored locally with ObjectBox - 100% privacy-focused

## 🏗️ Architecture

This project follows **Clean Architecture** principles with clear separation of concerns:

```
lib/
├── core/
│   ├── constants/      # App-wide constants (colors, sizes, strings)
│   ├── themes/         # Theme configuration with Nunito font
│   ├── utils/          # Utility functions (date/time, validators)
│   ├── widgets/        # Reusable UI components
│   └── di/             # Dependency injection setup
├── data/
│   ├── datasources/    # ObjectBox service
│   ├── models/         # ObjectBox data models
│   └── repositories/   # Repository implementations
├── domain/
│   ├── entities/       # Business entities
│   ├── repositories/   # Repository interfaces
│   └── usecases/       # Business logic use cases
└── presentation/
    ├── blocs/          # BLoC/Cubit state management
    ├── pages/          # App screens
    └── widgets/        # Page-specific widgets
```

## 🛠️ Tech Stack

- **Flutter SDK**: 3.35.5
- **State Management**: BLoC/Cubit pattern
- **Local Database**: ObjectBox
- **Dependency Injection**: GetIt
- **Local Notifications**: flutter_local_notifications
- **Font**: Nunito (via Google Fonts)

## 📦 Dependencies

### Core

- `flutter_bloc` - State management
- `equatable` - Value equality
- `get_it` - Service locator

### Data

- `objectbox` - Local database
- `objectbox_flutter_libs` - ObjectBox Flutter support
- `path_provider` - File system paths

### UI

- `google_fonts` - Nunito font family
- `cupertino_icons` - iOS-style icons

### Utilities

- `intl` - Internationalization and date formatting
- `flutter_local_notifications` - Push notifications
- `timezone` - Timezone support
- `permission_handler` - App permissions
- `shared_preferences` - Local preferences storage

### Dev Tools

- `build_runner` - Code generation
- `objectbox_generator` - ObjectBox entity generation
- `flutter_native_splash` - Splash screen generation
- `flutter_launcher_icons` - App icon generation

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.9.2 or higher
- FVM (Flutter Version Manager) - recommended
- Xcode (for iOS development)
- Android Studio (for Android development)

### Installation

1. **Clone the repository**

   ```bash
   git clone <your-repo-url>
   cd medify
   ```

2. **Use FVM (if installed)**

   ```bash
   fvm use 3.35.5
   ```

3. **Install dependencies**

   ```bash
   fvm flutter pub get
   # or without FVM
   flutter pub get
   ```

4. **Run ObjectBox code generation**

   ```bash
   fvm flutter pub run build_runner build --delete-conflicting-outputs
   ```

5. **Run the app**
   ```bash
   fvm flutter run
   # or without FVM
   flutter run
   ```

## 🎨 Design System

### Colors (Per Design Spec)

- **Primary Teal 500**: #14B8A6 - Main brand color
- **Primary Teal 400**: #2DD4BF - Interactive/Light states
- **Primary Teal 600**: #0D9488 - Pressed states
- **Success Green**: #10B981 - Taken medications
- **Warning Amber**: #F59E0B - Upcoming/Pending reminders
- **Error Red**: #EF4444 - Missed doses
- **Info Blue**: #3B82F6 - General information

### Typography (Per Design Spec)

- **Font Family**: Nunito (via Google Fonts)
- **H1**: 28px Bold - Page titles
- **H2**: 24px SemiBold - Section headers
- **H3**: 20px SemiBold - Card titles
- **Body Large**: 18px Regular - Important text
- **Body Medium**: 16px Regular - Primary content
- **Body Small**: 14px Regular - Secondary text
- **Caption**: 12px Regular - Labels, hints

### Spacing (4px base unit)

- **4px**: Micro spacing (icons and text)
- **8px**: Small spacing (related elements)
- **16px**: Medium spacing (sections, screen margins)
- **24px**: Large spacing (major sections)
- **32px**: Extra large spacing (page tops/bottoms)

### Accessibility

- **Minimum tap target**: 44px × 44px
- **Button height**: 56px
- **High contrast ratios**: 4.5:1 for normal text, 3:1 for large
- **Border radius**: Cards 16px, Buttons 12px, Inputs 8px
- **VoiceOver/TalkBack**: Fully compatible

## 📱 Development Phases

### Phase 1: Core MVP ✅ **COMPLETE!**

- [x] Project setup with FVM, BLoC, ObjectBox
- [x] Professional theme system with Nunito font
- [x] Clean architecture structure
- [x] Medicine CRUD operations with validation
- [x] Medicine intake timing field (before/after food, etc.)
- [x] List and form screens with custom widgets
- [x] Notification system integration (foreground & background)
- [x] Reminder scheduling with timezone support
- [x] Today's Schedule page with progress tracking
- [x] Medicine logging (taken, missed, skipped)
- [x] Today's Summary Card with gradient background
- [x] Bottom navigation
- [x] Light/dark theme with persistence
- [x] UI Design System (100% spec compliant)
- [x] Onboarding flow (3 screens)
- [x] Settings page (theme, notifications, snooze preferences)
- [x] Native splash screen (light & dark modes)
- [x] Android branding (app icon, name, notification icon)

### Phase 2: Enhanced Features 🚀 **NEXT UP**

- [ ] Notification actions (Taken, Snooze, Skip buttons)
- [ ] Time-based sections (Morning/Afternoon/Evening/Night)
- [ ] Medicine history view with calendar
- [ ] Statistics dashboard with charts
- [ ] Adherence streak tracking & rewards
- [ ] Empty state illustrations
- [ ] Enhanced notification styling
- [ ] Widget for home screen (optional)

### Phase 3: Polish & Release ✅ **READY!**

- [x] App store branding (icon, splash)
- [ ] App store assets (screenshots, feature graphic)
- [ ] Privacy Policy & Terms of Service
- [ ] Unit and widget tests
- [ ] Integration tests
- [ ] App store submission (Play Store first)
- [ ] Performance optimization
- [ ] Accessibility audit with screen reader

## 🧪 Testing

```bash
# Run tests
flutter test

# Run tests with coverage
flutter test --coverage
```

## 📝 Code Generation

When you modify ObjectBox entities, run:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 🤝 Contributing

This is a personal project, but suggestions and feedback are welcome!

## 📄 License

This project is private and not licensed for public use.

## 👤 Author

**Sumit Pal**

---

Built with ❤️ using Flutter
