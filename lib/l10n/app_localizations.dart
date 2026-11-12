import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Medify'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Never Miss Your Medicine'**
  String get appTagline;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @noProfileYet.
  ///
  /// In en, this message translates to:
  /// **'No profile yet.'**
  String get noProfileYet;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @tryingAgain.
  ///
  /// In en, this message translates to:
  /// **'Trying…'**
  String get tryingAgain;

  /// No description provided for @whoIsPhoneFor.
  ///
  /// In en, this message translates to:
  /// **'Who is this phone for?'**
  String get whoIsPhoneFor;

  /// No description provided for @rolePatient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get rolePatient;

  /// No description provided for @rolePatientDesc.
  ///
  /// In en, this message translates to:
  /// **'Track my own doses'**
  String get rolePatientDesc;

  /// No description provided for @roleCaregiver.
  ///
  /// In en, this message translates to:
  /// **'Caregiver'**
  String get roleCaregiver;

  /// No description provided for @roleCaregiverDesc.
  ///
  /// In en, this message translates to:
  /// **'Help someone else take their medicine'**
  String get roleCaregiverDesc;

  /// No description provided for @whoAreYouHelping.
  ///
  /// In en, this message translates to:
  /// **'Who are you helping?'**
  String get whoAreYouHelping;

  /// No description provided for @medicineOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open that medicine'**
  String get medicineOpenFailed;

  /// No description provided for @addPatientProfileFirst.
  ///
  /// In en, this message translates to:
  /// **'Add a patient profile first'**
  String get addPatientProfileFirst;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Medify'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Your personal medicine reminder and tracker'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Never Miss a Dose'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'Get timely reminders for all your medications'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Track Your Progress'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'Keep track of your medication history and adherence'**
  String get onboardingDesc3;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @medicines.
  ///
  /// In en, this message translates to:
  /// **'Medicines'**
  String get medicines;

  /// No description provided for @addMedicine.
  ///
  /// In en, this message translates to:
  /// **'Add Medicine'**
  String get addMedicine;

  /// No description provided for @editMedicine.
  ///
  /// In en, this message translates to:
  /// **'Edit Medicine'**
  String get editMedicine;

  /// No description provided for @deleteMedicine.
  ///
  /// In en, this message translates to:
  /// **'Delete Medicine'**
  String get deleteMedicine;

  /// No description provided for @medicineName.
  ///
  /// In en, this message translates to:
  /// **'Medicine Name'**
  String get medicineName;

  /// No description provided for @dosage.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get dosage;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @noMedicines.
  ///
  /// In en, this message translates to:
  /// **'No medicines added yet'**
  String get noMedicines;

  /// No description provided for @addYourFirstMedicine.
  ///
  /// In en, this message translates to:
  /// **'Add your first medicine'**
  String get addYourFirstMedicine;

  /// No description provided for @firstMedicineAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add a medicine'**
  String get firstMedicineAddAction;

  /// No description provided for @firstMedicineLaterAction.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get firstMedicineLaterAction;

  /// No description provided for @tapPlusToAddMedicine.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first medicine'**
  String get tapPlusToAddMedicine;

  /// No description provided for @addMenuManual.
  ///
  /// In en, this message translates to:
  /// **'Manual entry'**
  String get addMenuManual;

  /// No description provided for @addMenuVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice input'**
  String get addMenuVoice;

  /// No description provided for @voiceInputTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice input'**
  String get voiceInputTitle;

  /// No description provided for @voiceTapToSpeak.
  ///
  /// In en, this message translates to:
  /// **'Tap the microphone and say your medicine'**
  String get voiceTapToSpeak;

  /// No description provided for @voiceListening.
  ///
  /// In en, this message translates to:
  /// **'Listening… tap the microphone when you are done'**
  String get voiceListening;

  /// No description provided for @voiceExample.
  ///
  /// In en, this message translates to:
  /// **'For example: Paracetamol 500 mg twice a day after food for 5 days'**
  String get voiceExample;

  /// No description provided for @voicePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone or speech permission is off. Turn it on in Settings, or enter the medicine manually.'**
  String get voicePermissionDenied;

  /// No description provided for @voiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice input is not available on this device. Enter the medicine manually.'**
  String get voiceUnavailable;

  /// No description provided for @voiceNoSpeech.
  ///
  /// In en, this message translates to:
  /// **'We did not catch that. Tap the microphone to try again.'**
  String get voiceNoSpeech;

  /// No description provided for @voiceEnterManually.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get voiceEnterManually;

  /// No description provided for @voiceReviewBanner.
  ///
  /// In en, this message translates to:
  /// **'Review voice entry. Nothing saved yet.'**
  String get voiceReviewBanner;

  /// No description provided for @voiceDurationDays.
  ///
  /// In en, this message translates to:
  /// **'Duration (days)'**
  String get voiceDurationDays;

  /// No description provided for @voiceStartListening.
  ///
  /// In en, this message translates to:
  /// **'Start listening'**
  String get voiceStartListening;

  /// No description provided for @voiceStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get voiceStop;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @todaysSchedule.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Schedule'**
  String get todaysSchedule;

  /// No description provided for @upcomingReminders.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Reminders'**
  String get upcomingReminders;

  /// No description provided for @noReminders.
  ///
  /// In en, this message translates to:
  /// **'No reminders for today'**
  String get noReminders;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up!'**
  String get allCaughtUp;

  /// No description provided for @markAsTaken.
  ///
  /// In en, this message translates to:
  /// **'Mark as Taken'**
  String get markAsTaken;

  /// No description provided for @taken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get taken;

  /// No description provided for @snooze.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get snooze;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @afternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get afternoon;

  /// No description provided for @evening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get evening;

  /// No description provided for @night.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get night;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @missed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get missed;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @snoozed.
  ///
  /// In en, this message translates to:
  /// **'Snoozed'**
  String get snoozed;

  /// No description provided for @notificationPermission.
  ///
  /// In en, this message translates to:
  /// **'Notification Permission'**
  String get notificationPermission;

  /// No description provided for @notificationPermissionDesc.
  ///
  /// In en, this message translates to:
  /// **'We need notification permission to remind you about your medicines'**
  String get notificationPermissionDesc;

  /// No description provided for @grantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get grantPermission;

  /// No description provided for @notificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to take your medicine'**
  String get notificationTitle;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorGeneric;

  /// No description provided for @errorNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get errorNoInternet;

  /// No description provided for @errorInvalidInput.
  ///
  /// In en, this message translates to:
  /// **'Please check your input'**
  String get errorInvalidInput;

  /// No description provided for @errorMedicineNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Medicine name is required'**
  String get errorMedicineNameRequired;

  /// No description provided for @errorDosageRequired.
  ///
  /// In en, this message translates to:
  /// **'Dosage is required'**
  String get errorDosageRequired;

  /// No description provided for @errorScheduleRequired.
  ///
  /// In en, this message translates to:
  /// **'At least one time is required'**
  String get errorScheduleRequired;

  /// No description provided for @snooze15min.
  ///
  /// In en, this message translates to:
  /// **'15 minutes'**
  String get snooze15min;

  /// No description provided for @snooze30min.
  ///
  /// In en, this message translates to:
  /// **'30 minutes'**
  String get snooze30min;

  /// No description provided for @snooze1hour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get snooze1hour;

  /// No description provided for @deleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete Confirmation'**
  String get deleteConfirmation;

  /// No description provided for @deleteMedicineConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this medicine?'**
  String get deleteMedicineConfirmation;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @bengali.
  ///
  /// In en, this message translates to:
  /// **'Bengali'**
  String get bengali;

  /// No description provided for @aboutDialogDesc.
  ///
  /// In en, this message translates to:
  /// **'Medify helps you stay on track with your medications through timely reminders and comprehensive tracking.'**
  String get aboutDialogDesc;

  /// No description provided for @copyrightNotice.
  ///
  /// In en, this message translates to:
  /// **'© 2025 Medify. All rights reserved.'**
  String get copyrightNotice;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @appSection.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get appSection;

  /// No description provided for @notificationsSection.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsSection;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @speakReminder.
  ///
  /// In en, this message translates to:
  /// **'Speak reminder'**
  String get speakReminder;

  /// No description provided for @speakReminderDesc.
  ///
  /// In en, this message translates to:
  /// **'Medicine name and time, up to 3 times'**
  String get speakReminderDesc;

  /// No description provided for @resetAllSettings.
  ///
  /// In en, this message translates to:
  /// **'Reset All Settings'**
  String get resetAllSettings;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @selectTheme.
  ///
  /// In en, this message translates to:
  /// **'Select Theme'**
  String get selectTheme;

  /// No description provided for @themeLightDesc.
  ///
  /// In en, this message translates to:
  /// **'Bright and clean'**
  String get themeLightDesc;

  /// No description provided for @themeDarkDesc.
  ///
  /// In en, this message translates to:
  /// **'Easy on the eyes'**
  String get themeDarkDesc;

  /// No description provided for @themeSystemDesc.
  ///
  /// In en, this message translates to:
  /// **'Follow device settings'**
  String get themeSystemDesc;

  /// No description provided for @snoozeDuration.
  ///
  /// In en, this message translates to:
  /// **'Snooze Duration'**
  String get snoozeDuration;

  /// No description provided for @selectSnoozeDuration.
  ///
  /// In en, this message translates to:
  /// **'Select Snooze Duration'**
  String get selectSnoozeDuration;

  /// No description provided for @snoozeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes'**
  String snoozeMinutes(int count);

  /// No description provided for @snoozeOneHour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get snoozeOneHour;

  /// No description provided for @snoozeQuick.
  ///
  /// In en, this message translates to:
  /// **'Quick reminder'**
  String get snoozeQuick;

  /// No description provided for @snoozeStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard delay'**
  String get snoozeStandard;

  /// No description provided for @snoozeLong.
  ///
  /// In en, this message translates to:
  /// **'Longer break'**
  String get snoozeLong;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @achievementsDesc.
  ///
  /// In en, this message translates to:
  /// **'View your unlocked badges and progress'**
  String get achievementsDesc;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @resetSettings.
  ///
  /// In en, this message translates to:
  /// **'Reset Settings'**
  String get resetSettings;

  /// No description provided for @resetSettingsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset all settings to default values?'**
  String get resetSettingsConfirm;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @settingsResetDone.
  ///
  /// In en, this message translates to:
  /// **'Settings reset to default'**
  String get settingsResetDone;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @historyExported.
  ///
  /// In en, this message translates to:
  /// **'History exported successfully!'**
  String get historyExported;

  /// No description provided for @exporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting...'**
  String get exporting;

  /// No description provided for @historyLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading history'**
  String get historyLoadError;

  /// No description provided for @noLogs.
  ///
  /// In en, this message translates to:
  /// **'No Logs'**
  String get noLogs;

  /// No description provided for @noLogsMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No logs match your filters'**
  String get noLogsMatchFilters;

  /// No description provided for @noMedicinesForDate.
  ///
  /// In en, this message translates to:
  /// **'No medicines scheduled for this date'**
  String get noMedicinesForDate;

  /// No description provided for @activeFilters.
  ///
  /// In en, this message translates to:
  /// **'Active Filters:'**
  String get activeFilters;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @takenAt.
  ///
  /// In en, this message translates to:
  /// **'Taken at {time}'**
  String takenAt(String time);

  /// No description provided for @filterHistory.
  ///
  /// In en, this message translates to:
  /// **'Filter History'**
  String get filterHistory;

  /// No description provided for @medicineFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Medicine:'**
  String get medicineFilterLabel;

  /// No description provided for @allMedicines.
  ///
  /// In en, this message translates to:
  /// **'All Medicines'**
  String get allMedicines;

  /// No description provided for @statusFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Status:'**
  String get statusFilterLabel;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All Statuses'**
  String get allStatuses;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @skipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skipped;

  /// No description provided for @trackStock.
  ///
  /// In en, this message translates to:
  /// **'Track stock'**
  String get trackStock;

  /// No description provided for @trackStockHint.
  ///
  /// In en, this message translates to:
  /// **'Track medicine stock and get refill reminders'**
  String get trackStockHint;

  /// No description provided for @stockTakenHelper.
  ///
  /// In en, this message translates to:
  /// **'Stock goes down when you mark a dose Taken.'**
  String get stockTakenHelper;

  /// No description provided for @stockEditHelper.
  ///
  /// In en, this message translates to:
  /// **'Stock changes only through Taken and I refilled, not here.'**
  String get stockEditHelper;

  /// No description provided for @refillButton.
  ///
  /// In en, this message translates to:
  /// **'I refilled'**
  String get refillButton;

  /// No description provided for @refillDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Refill stock'**
  String get refillDialogTitle;

  /// No description provided for @refillQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity in stock'**
  String get refillQuantityLabel;

  /// No description provided for @refillInvalidQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter a quantity of 0 or more.'**
  String get refillInvalidQuantity;

  /// No description provided for @refillSaved.
  ///
  /// In en, this message translates to:
  /// **'Stock updated.'**
  String get refillSaved;

  /// No description provided for @refillFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update stock.'**
  String get refillFailed;

  /// No description provided for @skipReasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Why skip this dose?'**
  String get skipReasonTitle;

  /// No description provided for @skipReasonFeltUnwell.
  ///
  /// In en, this message translates to:
  /// **'Felt unwell'**
  String get skipReasonFeltUnwell;

  /// No description provided for @skipReasonSideEffects.
  ///
  /// In en, this message translates to:
  /// **'Side effects'**
  String get skipReasonSideEffects;

  /// No description provided for @skipReasonRanOut.
  ///
  /// In en, this message translates to:
  /// **'Ran out'**
  String get skipReasonRanOut;

  /// No description provided for @skipReasonDoctorAdvised.
  ///
  /// In en, this message translates to:
  /// **'Doctor advised'**
  String get skipReasonDoctorAdvised;

  /// No description provided for @skipReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get skipReasonOther;

  /// No description provided for @skipWithoutReason.
  ///
  /// In en, this message translates to:
  /// **'Skip without reason'**
  String get skipWithoutReason;

  /// No description provided for @pauseMedicine.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseMedicine;

  /// No description provided for @resumeMedicine.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeMedicine;

  /// No description provided for @stopMedicine.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopMedicine;

  /// No description provided for @stoppedLabel.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get stoppedLabel;

  /// No description provided for @stopMedicineTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop this medicine?'**
  String get stopMedicineTitle;

  /// No description provided for @stopMedicineBody.
  ///
  /// In en, this message translates to:
  /// **'Future doses and reminders are removed. Past history is kept.'**
  String get stopMedicineBody;

  /// No description provided for @stopReasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Why? (optional)'**
  String get stopReasonTitle;

  /// No description provided for @stopReasonCourseFinished.
  ///
  /// In en, this message translates to:
  /// **'Course finished'**
  String get stopReasonCourseFinished;

  /// No description provided for @stopReasonDoctorStopped.
  ///
  /// In en, this message translates to:
  /// **'Doctor stopped it'**
  String get stopReasonDoctorStopped;

  /// No description provided for @stopReasonSideEffects.
  ///
  /// In en, this message translates to:
  /// **'Side effects'**
  String get stopReasonSideEffects;

  /// No description provided for @stopReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get stopReasonOther;

  /// No description provided for @stopMedicineButton.
  ///
  /// In en, this message translates to:
  /// **'Stop medicine'**
  String get stopMedicineButton;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get deleteAllData;

  /// No description provided for @deleteExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export your history first?'**
  String get deleteExportTitle;

  /// No description provided for @deleteExportBody.
  ///
  /// In en, this message translates to:
  /// **'Deleting removes all medicines, doses, history and settings from this phone. Medify has no cloud copy, so this cannot be undone.'**
  String get deleteExportBody;

  /// No description provided for @exportHistory.
  ///
  /// In en, this message translates to:
  /// **'Export history'**
  String get exportHistory;

  /// No description provided for @continueWithoutExport.
  ///
  /// In en, this message translates to:
  /// **'Continue without export'**
  String get continueWithoutExport;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete everything?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm. This cannot be undone.'**
  String get deleteConfirmBody;

  /// No description provided for @deleteConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get deleteConfirmHint;

  /// No description provided for @deleteAllDataConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get deleteAllDataConfirm;

  /// No description provided for @deleteDataFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete data. Nothing was removed.'**
  String get deleteDataFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
