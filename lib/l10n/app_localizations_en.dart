// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Medify';

  @override
  String get appTagline => 'Never Miss Your Medicine';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get done => 'Done';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get next => 'Next';

  @override
  String get noProfileYet => 'No profile yet.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get tryingAgain => 'Trying…';

  @override
  String get whoIsPhoneFor => 'Who is this phone for?';

  @override
  String get rolePatient => 'Patient';

  @override
  String get rolePatientDesc => 'Track my own doses';

  @override
  String get roleCaregiver => 'Caregiver';

  @override
  String get roleCaregiverDesc => 'Help someone else take their medicine';

  @override
  String get whoAreYouHelping => 'Who are you helping?';

  @override
  String get medicineOpenFailed => 'Could not open that medicine';

  @override
  String get addPatientProfileFirst => 'Add a patient profile first';

  @override
  String get onboardingTitle1 => 'Welcome to Medify';

  @override
  String get onboardingDesc1 => 'Your personal medicine reminder and tracker';

  @override
  String get onboardingTitle2 => 'Never Miss a Dose';

  @override
  String get onboardingDesc2 => 'Get timely reminders for all your medications';

  @override
  String get onboardingTitle3 => 'Track Your Progress';

  @override
  String get onboardingDesc3 =>
      'Keep track of your medication history and adherence';

  @override
  String get getStarted => 'Get Started';

  @override
  String get medicines => 'Medicines';

  @override
  String get addMedicine => 'Add Medicine';

  @override
  String get editMedicine => 'Edit Medicine';

  @override
  String get deleteMedicine => 'Delete Medicine';

  @override
  String get medicineName => 'Medicine Name';

  @override
  String get dosage => 'Dosage';

  @override
  String get schedule => 'Schedule';

  @override
  String get notes => 'Notes';

  @override
  String get noMedicines => 'No medicines added yet';

  @override
  String get addYourFirstMedicine => 'Add your first medicine';

  @override
  String get tapPlusToAddMedicine => 'Tap + to add your first medicine';

  @override
  String get addMenuManual => 'Manual entry';

  @override
  String get addMenuVoice => 'Voice input';

  @override
  String get voiceInputTitle => 'Voice input';

  @override
  String get voiceTapToSpeak => 'Tap the microphone and say your medicine';

  @override
  String get voiceListening =>
      'Listening… tap the microphone when you are done';

  @override
  String get voiceExample =>
      'For example: Paracetamol 500 mg twice a day after food for 5 days';

  @override
  String get voicePermissionDenied =>
      'Microphone or speech permission is off. Turn it on in Settings, or enter the medicine manually.';

  @override
  String get voiceUnavailable =>
      'Voice input is not available on this device. Enter the medicine manually.';

  @override
  String get voiceNoSpeech =>
      'We did not catch that. Tap the microphone to try again.';

  @override
  String get voiceEnterManually => 'Enter manually';

  @override
  String get voiceReviewBanner => 'Review voice entry. Nothing saved yet.';

  @override
  String get voiceDurationDays => 'Duration (days)';

  @override
  String get voiceStartListening => 'Start listening';

  @override
  String get voiceStop => 'Stop';

  @override
  String get reminders => 'Reminders';

  @override
  String get todaysSchedule => 'Today\'s Schedule';

  @override
  String get upcomingReminders => 'Upcoming Reminders';

  @override
  String get noReminders => 'No reminders for today';

  @override
  String get allCaughtUp => 'You\'re all caught up!';

  @override
  String get markAsTaken => 'Mark as Taken';

  @override
  String get taken => 'Taken';

  @override
  String get snooze => 'Snooze';

  @override
  String get skip => 'Skip';

  @override
  String get undo => 'Undo';

  @override
  String get morning => 'Morning';

  @override
  String get afternoon => 'Afternoon';

  @override
  String get evening => 'Evening';

  @override
  String get night => 'Night';

  @override
  String get daily => 'Daily';

  @override
  String get today => 'Today';

  @override
  String get statistics => 'Statistics';

  @override
  String get pending => 'Pending';

  @override
  String get missed => 'Missed';

  @override
  String get completed => 'Completed';

  @override
  String get snoozed => 'Snoozed';

  @override
  String get notificationPermission => 'Notification Permission';

  @override
  String get notificationPermissionDesc =>
      'We need notification permission to remind you about your medicines';

  @override
  String get grantPermission => 'Grant Permission';

  @override
  String get notificationTitle => 'Time to take your medicine';

  @override
  String get errorGeneric => 'Something went wrong';

  @override
  String get errorNoInternet => 'No internet connection';

  @override
  String get errorInvalidInput => 'Please check your input';

  @override
  String get errorMedicineNameRequired => 'Medicine name is required';

  @override
  String get errorDosageRequired => 'Dosage is required';

  @override
  String get errorScheduleRequired => 'At least one time is required';

  @override
  String get snooze15min => '15 minutes';

  @override
  String get snooze30min => '30 minutes';

  @override
  String get snooze1hour => '1 hour';

  @override
  String get deleteConfirmation => 'Delete Confirmation';

  @override
  String get deleteMedicineConfirmation =>
      'Are you sure you want to delete this medicine?';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get english => 'English';

  @override
  String get hindi => 'Hindi';

  @override
  String get bengali => 'Bengali';

  @override
  String get aboutDialogDesc =>
      'Medify helps you stay on track with your medications through timely reminders and comprehensive tracking.';

  @override
  String get copyrightNotice => '© 2025 Medify. All rights reserved.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appSection => 'App';

  @override
  String get notificationsSection => 'Notifications';

  @override
  String get aboutSection => 'About';

  @override
  String get speakReminder => 'Speak reminder';

  @override
  String get speakReminderDesc => 'Medicine name and time, up to 3 times';

  @override
  String get resetAllSettings => 'Reset All Settings';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get selectTheme => 'Select Theme';

  @override
  String get themeLightDesc => 'Bright and clean';

  @override
  String get themeDarkDesc => 'Easy on the eyes';

  @override
  String get themeSystemDesc => 'Follow device settings';

  @override
  String get snoozeDuration => 'Snooze Duration';

  @override
  String get selectSnoozeDuration => 'Select Snooze Duration';

  @override
  String snoozeMinutes(int count) {
    return '$count minutes';
  }

  @override
  String get snoozeOneHour => '1 hour';

  @override
  String get snoozeQuick => 'Quick reminder';

  @override
  String get snoozeStandard => 'Standard delay';

  @override
  String get snoozeLong => 'Longer break';

  @override
  String get achievements => 'Achievements';

  @override
  String get achievementsDesc => 'View your unlocked badges and progress';

  @override
  String get version => 'Version';

  @override
  String get resetSettings => 'Reset Settings';

  @override
  String get resetSettingsConfirm =>
      'Are you sure you want to reset all settings to default values?';

  @override
  String get reset => 'Reset';

  @override
  String get settingsResetDone => 'Settings reset to default';

  @override
  String get historyTitle => 'History';

  @override
  String get refresh => 'Refresh';

  @override
  String get filter => 'Filter';

  @override
  String get historyExported => 'History exported successfully!';

  @override
  String get exporting => 'Exporting...';

  @override
  String get historyLoadError => 'Error loading history';

  @override
  String get noLogs => 'No Logs';

  @override
  String get noLogsMatchFilters => 'No logs match your filters';

  @override
  String get noMedicinesForDate => 'No medicines scheduled for this date';

  @override
  String get activeFilters => 'Active Filters:';

  @override
  String get clearAll => 'Clear All';

  @override
  String takenAt(String time) {
    return 'Taken at $time';
  }

  @override
  String get filterHistory => 'Filter History';

  @override
  String get medicineFilterLabel => 'Medicine:';

  @override
  String get allMedicines => 'All Medicines';

  @override
  String get statusFilterLabel => 'Status:';

  @override
  String get allStatuses => 'All Statuses';

  @override
  String get apply => 'Apply';

  @override
  String get skipped => 'Skipped';
}
