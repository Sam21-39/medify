# Medify - Project Structure Documentation

## Overview

Complete MVP setup for Medify - Medicine Reminder & Tracker application with Clean Architecture, BLoC state management, and ObjectBox database.

## ✅ Completed Setup

### 1. Project Initialization

- ✅ Flutter project created with FVM (v3.35.5)
- ✅ Organization: `com.medify`
- ✅ Platforms: iOS, Android

### 2. Dependencies Configured

All packages installed and configured in `pubspec.yaml`:

**State Management:**

- `flutter_bloc: ^8.1.6` - BLoC/Cubit pattern
- `equatable: ^2.0.7` - Value equality

**Database:**

- `objectbox: ^4.0.3` - Local NoSQL database
- `objectbox_flutter_libs: ^4.0.3` - Flutter bindings
- `build_runner: ^2.4.14` - Code generation
- `objectbox_generator: ^4.0.3` - ObjectBox code gen

**Dependency Injection:**

- `get_it: ^8.0.3` - Service locator

**Notifications:**

- `flutter_local_notifications: ^18.0.1`
- `timezone: ^0.10.0`
- `permission_handler: ^11.3.1`

**UI & Utilities:**

- `google_fonts: ^6.2.1` - Nunito font
- `intl: ^0.20.1` - Date/time formatting
- `path_provider: ^2.1.5` - File system paths
- `path: ^1.9.0` - Path manipulation

### 3. Clean Architecture Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart          ✅ Teal & Green color palette
│   │   ├── app_sizes.dart           ✅ Spacing & sizing constants
│   │   └── app_strings.dart         ✅ All string constants
│   ├── themes/
│   │   └── app_theme.dart           ✅ Light/Dark themes with Nunito
│   ├── utils/
│   │   ├── date_time_utils.dart     ✅ Date/time helpers
│   │   └── validators.dart          ✅ Form validation
│   ├── widgets/
│   │   ├── custom_button.dart       ✅ Reusable buttons
│   │   ├── custom_text_field.dart   ✅ Text input
│   │   ├── empty_state.dart         ✅ Empty state widget
│   │   └── loading_indicator.dart   ✅ Loading widget
│   └── di/
│       └── injection_container.dart  ✅ GetIt setup
├── data/
│   ├── datasources/
│   │   └── objectbox_service.dart   ✅ ObjectBox initialization
│   ├── models/
│   │   ├── medicine_model.dart      ✅ Medicine ObjectBox entity
│   │   └── medicine_log_model.dart  ✅ Log ObjectBox entity
│   └── repositories/
│       ├── medicine_repository_impl.dart     ✅ Medicine repo
│       └── medicine_log_repository_impl.dart ✅ Log repo
├── domain/
│   ├── entities/
│   │   ├── medicine.dart            ✅ Medicine entity
│   │   └── medicine_log.dart        ✅ Log entity with status enum
│   └── repositories/
│       ├── medicine_repository.dart         ✅ Medicine interface
│       └── medicine_log_repository.dart     ✅ Log interface
├── presentation/
│   ├── blocs/
│   │   ├── medicine/
│   │   │   ├── medicine_cubit.dart  ✅ Medicine state management
│   │   │   └── medicine_state.dart  ✅ Medicine states
│   │   └── medicine_log/
│   │       ├── medicine_log_cubit.dart ✅ Log state management
│   │       └── medicine_log_state.dart ✅ Log states
│   ├── pages/
│   │   └── home_page.dart           ✅ Placeholder home page
│   └── widgets/
│       └── (page-specific widgets)  ⏳ To be created
├── main.dart                         ✅ App entry with DI & BLoC setup
└── objectbox.g.dart                  ✅ Generated ObjectBox code
```

### 4. Core Features Implemented

#### Data Models

- **Medicine Entity/Model:**

  - ID, name, dosage
  - Reminder times (as seconds since midnight)
  - Active status, notes
  - Created/updated timestamps

- **MedicineLog Entity/Model:**
  - Medicine reference
  - Scheduled/taken times
  - Status (pending, taken, missed, skipped, snoozed)
  - Notes, timestamps

#### Repository Layer

- **Medicine Repository:**

  - CRUD operations
  - Get all/active medicines
  - Toggle active status
  - Stream support for real-time updates

- **MedicineLog Repository:**
  - Log management
  - Get by medicine ID, date, today
  - Mark as taken/skipped/missed
  - Snooze functionality
  - Get overdue/pending logs
  - Stream support

#### State Management

- **MedicineCubit:**

  - Load medicines (all/active)
  - Add/update/delete medicine
  - Toggle status
  - Watch medicines stream

- **MedicineLogCubit:**
  - Load logs (today/by date/by medicine)
  - Add log, mark status
  - Snooze log
  - Load overdue/pending
  - Watch logs stream

#### Theme System

- **Light & Dark Modes:**
  - Teal primary color (#009688)
  - Green secondary color (#4CAF50)
  - Nunito font family (Regular, SemiBold, Bold)
  - Accessible button sizes (min 44px tap targets)
  - Consistent border radius (12px cards, 24px buttons)

### 5. Configuration Files

- ✅ `.gitignore` - Includes FVM, ObjectBox generated files
- ✅ `README.md` - Comprehensive project documentation
- ✅ `PROJECT_STRUCTURE.md` - This file
- ✅ `objectbox-model.json` - ObjectBox schema

## 🎯 Next Steps (Phase 1 Completion)

### Immediate Todo:

1. **Medicine List Screen**

   - Display all medicines in a list/grid
   - FAB to add new medicine
   - Tap to edit, swipe to delete
   - Visual active/inactive indicators

2. **Add/Edit Medicine Screen**

   - Form with name, dosage fields
   - Time picker for reminder times
   - Notes field (optional)
   - Save/cancel actions

3. **Medicine Card Widget**

   - Display medicine info
   - Show next reminder time
   - Quick action buttons

4. **Today's Schedule Screen**
   - List of today's reminders
   - Time-sorted display
   - Quick actions: Taken/Snooze/Skip
   - Progress indicator

### Phase 2 (Weeks 3-4):

- Notification service implementation
- Schedule reminders on medicine creation
- Handle notification actions
- Basic history view

### Phase 3 (Weeks 5-6):

- Onboarding flow
- Settings page (dark mode toggle, etc.)
- App polish and animations
- Accessibility testing

## 📝 Development Commands

```bash
# Get dependencies
fvm flutter pub get

# Run ObjectBox code generation (after model changes)
fvm flutter pub run build_runner build --delete-conflicting-outputs

# Analyze code
fvm flutter analyze

# Run app
fvm flutter run

# Build iOS
fvm flutter build ios

# Build Android
fvm flutter build apk
```

## 🧪 Testing Strategy

### Unit Tests (To be created):

- Repository tests with mocked ObjectBox
- Cubit tests with mocked repositories
- Entity/Model conversion tests
- Utility function tests

### Widget Tests (To be created):

- Custom widget tests
- Page widget tests
- Integration tests

### Manual Testing:

- Accessibility (VoiceOver, TalkBack)
- Dark mode compatibility
- Different screen sizes
- Edge cases (empty states, errors)

## 🎨 Design Tokens

### Colors

- Primary: `#009688` (Teal)
- Primary Light: `#4DB6AC`
- Primary Dark: `#00695C`
- Secondary: `#4CAF50` (Green)
- Success: Green (taken)
- Warning: Orange (pending)
- Error: `#EF5350` (soft red - missed)

### Typography

- Font: Nunito
- Display Large: 32px Bold
- Headline: 20px SemiBold
- Title: 18px SemiBold
- Body: 16px Regular (minimum)
- Label: 16px SemiBold

### Spacing

- XS: 4px
- S: 8px
- M: 16px
- L: 24px
- XL: 32px

### Sizing

- Button Height: 56px (large: 64px, small: 44px)
- Min Tap Target: 44px
- Icon: 24px (S: 16px, L: 32px, XL: 48px)
- Card Radius: 12px
- Button Radius: 24px

## 📚 Key Architecture Decisions

1. **Clean Architecture**: Separation of concerns for maintainability
2. **BLoC Pattern**: Predictable state management
3. **ObjectBox**: Fast local-first database
4. **GetIt**: Simple dependency injection
5. **Repository Pattern**: Abstract data sources
6. **Stream Support**: Real-time UI updates
7. **Nunito Font**: Accessible, friendly typography
8. **Teal/Green**: Calming, medical-appropriate colors

## 🔒 Code Quality

- ✅ Zero analyzer issues
- ✅ Consistent naming conventions
- ✅ Comprehensive documentation
- ✅ Null safety enabled
- ✅ Type-safe throughout

---

**Status**: Phase 1 Foundation Complete ✅
**Next**: Build UI screens and user flows
**Version**: 1.0.0+1
**Last Updated**: 2025-10-14
