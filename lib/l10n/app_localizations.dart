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
