import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Vet2U'**
  String get appTitle;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back,'**
  String get welcomeBack;

  /// No description provided for @yourPetsSafeHands.
  ///
  /// In en, this message translates to:
  /// **'Your pets are in safe hands'**
  String get yourPetsSafeHands;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @quickSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Quick snapshot of your pets & visits'**
  String get quickSnapshot;

  /// No description provided for @activePets.
  ///
  /// In en, this message translates to:
  /// **'Active Pets'**
  String get activePets;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @jumpToTasks.
  ///
  /// In en, this message translates to:
  /// **'Jump directly to the most common tasks'**
  String get jumpToTasks;

  /// No description provided for @scheduleVetCare.
  ///
  /// In en, this message translates to:
  /// **'Schedule veterinary care'**
  String get scheduleVetCare;

  /// No description provided for @managePetProfiles.
  ///
  /// In en, this message translates to:
  /// **'Manage pet profiles'**
  String get managePetProfiles;

  /// No description provided for @followVetVisit.
  ///
  /// In en, this message translates to:
  /// **'Follow your vet visit'**
  String get followVetVisit;

  /// No description provided for @trackService.
  ///
  /// In en, this message translates to:
  /// **'Track Service'**
  String get trackService;

  /// No description provided for @viewPastTreatments.
  ///
  /// In en, this message translates to:
  /// **'View past treatments'**
  String get viewPastTreatments;

  /// No description provided for @downloadTreatmentDocs.
  ///
  /// In en, this message translates to:
  /// **'Download treatment documents'**
  String get downloadTreatmentDocs;

  /// No description provided for @medicalDocuments.
  ///
  /// In en, this message translates to:
  /// **'Medical Documents'**
  String get medicalDocuments;

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

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @switchToLightMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to Light Mode'**
  String get switchToLightMode;

  /// No description provided for @switchToDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to Dark Mode'**
  String get switchToDarkMode;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @emergencyRequest.
  ///
  /// In en, this message translates to:
  /// **'Emergency Request'**
  String get emergencyRequest;

  /// No description provided for @selectPetNeedingCare.
  ///
  /// In en, this message translates to:
  /// **'Select the pet needing emergency care:'**
  String get selectPetNeedingCare;

  /// No description provided for @choosePet.
  ///
  /// In en, this message translates to:
  /// **'Choose a pet'**
  String get choosePet;

  /// No description provided for @describeEmergency.
  ///
  /// In en, this message translates to:
  /// **'Describe the emergency:'**
  String get describeEmergency;

  /// No description provided for @describeSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Describe symptoms, injuries, or urgent situation...'**
  String get describeSymptoms;

  /// No description provided for @shareLocationResponders.
  ///
  /// In en, this message translates to:
  /// **'Share my current location with emergency responders'**
  String get shareLocationResponders;

  /// No description provided for @emergencyWarning.
  ///
  /// In en, this message translates to:
  /// **'Emergency services will be dispatched immediately. This is for life-threatening situations only.'**
  String get emergencyWarning;

  /// No description provided for @sendEmergencyRequest.
  ///
  /// In en, this message translates to:
  /// **'Send Emergency Request'**
  String get sendEmergencyRequest;

  /// No description provided for @pleaseSelectPet.
  ///
  /// In en, this message translates to:
  /// **'Please select a pet'**
  String get pleaseSelectPet;

  /// No description provided for @pleaseDescribeEmergency.
  ///
  /// In en, this message translates to:
  /// **'Please describe the emergency'**
  String get pleaseDescribeEmergency;

  /// No description provided for @emergencyRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Emergency request sent! Help is on the way.'**
  String get emergencyRequestSent;

  /// No description provided for @failedSendEmergency.
  ///
  /// In en, this message translates to:
  /// **'Failed to send emergency request'**
  String get failedSendEmergency;

  /// No description provided for @medicalHistory.
  ///
  /// In en, this message translates to:
  /// **'Medical History'**
  String get medicalHistory;

  /// No description provided for @noMedicalRecords.
  ///
  /// In en, this message translates to:
  /// **'No medical records found'**
  String get noMedicalRecords;

  /// No description provided for @diagnosis.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis'**
  String get diagnosis;

  /// No description provided for @treatment.
  ///
  /// In en, this message translates to:
  /// **'Treatment'**
  String get treatment;

  /// No description provided for @prescription.
  ///
  /// In en, this message translates to:
  /// **'Prescription'**
  String get prescription;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @updateDetails.
  ///
  /// In en, this message translates to:
  /// **'Update your details'**
  String get updateDetails;

  /// No description provided for @contactNumber.
  ///
  /// In en, this message translates to:
  /// **'Contact number'**
  String get contactNumber;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @notificationsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Notifications, privacy'**
  String get notificationsPrivacy;

  /// No description provided for @settingsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Settings coming soon'**
  String get settingsComingSoon;

  /// No description provided for @selectDriver.
  ///
  /// In en, this message translates to:
  /// **'Select Driver'**
  String get selectDriver;

  /// No description provided for @closeApp.
  ///
  /// In en, this message translates to:
  /// **'Close App'**
  String get closeApp;

  /// No description provided for @serviceForToday.
  ///
  /// In en, this message translates to:
  /// **'Service for Today'**
  String get serviceForToday;

  /// No description provided for @notificationsAndReminders.
  ///
  /// In en, this message translates to:
  /// **'Notifications & Reminders'**
  String get notificationsAndReminders;

  /// No description provided for @receiveReminders.
  ///
  /// In en, this message translates to:
  /// **'Receive reminders for vaccinations, checkups, follow-ups, and mobile clinic arrivals'**
  String get receiveReminders;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @pleaseAddPetFirst.
  ///
  /// In en, this message translates to:
  /// **'Please add a pet first'**
  String get pleaseAddPetFirst;

  /// No description provided for @emergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency (Urgent)'**
  String get emergency;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @pets.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get pets;

  /// No description provided for @book.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get book;

  /// No description provided for @appointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get appointments;

  /// No description provided for @treatments.
  ///
  /// In en, this message translates to:
  /// **'Treatments'**
  String get treatments;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @bookAppointment.
  ///
  /// In en, this message translates to:
  /// **'Book Appointment'**
  String get bookAppointment;

  /// No description provided for @scheduleVisit.
  ///
  /// In en, this message translates to:
  /// **'Schedule a Visit'**
  String get scheduleVisit;

  /// No description provided for @bookVetCare.
  ///
  /// In en, this message translates to:
  /// **'Book veterinary care for your pet'**
  String get bookVetCare;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// No description provided for @selectService.
  ///
  /// In en, this message translates to:
  /// **'Select Service'**
  String get selectService;

  /// No description provided for @chooseService.
  ///
  /// In en, this message translates to:
  /// **'Choose a service'**
  String get chooseService;

  /// No description provided for @selectDoctor.
  ///
  /// In en, this message translates to:
  /// **'Select Doctor'**
  String get selectDoctor;

  /// No description provided for @chooseDoctor.
  ///
  /// In en, this message translates to:
  /// **'Choose a doctor'**
  String get chooseDoctor;

  /// No description provided for @selectPet.
  ///
  /// In en, this message translates to:
  /// **'Select Pet'**
  String get selectPet;

  /// No description provided for @urgencyLevel.
  ///
  /// In en, this message translates to:
  /// **'Urgency Level'**
  String get urgencyLevel;

  /// No description provided for @appointmentLocation.
  ///
  /// In en, this message translates to:
  /// **'Appointment Location *'**
  String get appointmentLocation;

  /// No description provided for @locationDescription.
  ///
  /// In en, this message translates to:
  /// **'Select the location where the vet service will be provided. This helps the driver navigate to your location.'**
  String get locationDescription;

  /// No description provided for @clickMapIcon.
  ///
  /// In en, this message translates to:
  /// **'Click the map icon to select location *'**
  String get clickMapIcon;

  /// No description provided for @selectedLocation.
  ///
  /// In en, this message translates to:
  /// **'Selected Location'**
  String get selectedLocation;

  /// No description provided for @locationRequired.
  ///
  /// In en, this message translates to:
  /// **'Location is required for the driver to find you'**
  String get locationRequired;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get descriptionOptional;

  /// No description provided for @bookAppointmentButton.
  ///
  /// In en, this message translates to:
  /// **'Book Appointment'**
  String get bookAppointmentButton;

  /// No description provided for @pleaseSelectServiceTimePetDoctor.
  ///
  /// In en, this message translates to:
  /// **'Please select service, time, pet, and doctor'**
  String get pleaseSelectServiceTimePetDoctor;

  /// No description provided for @pleaseSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Please select a location for the appointment'**
  String get pleaseSelectLocation;

  /// No description provided for @pleaseLoginFirst.
  ///
  /// In en, this message translates to:
  /// **'Please login first'**
  String get pleaseLoginFirst;

  /// No description provided for @appointmentBookedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Appointment booked successfully!'**
  String get appointmentBookedSuccessfully;

  /// No description provided for @failedToBookAppointment.
  ///
  /// In en, this message translates to:
  /// **'Failed to book appointment'**
  String get failedToBookAppointment;

  /// No description provided for @routine.
  ///
  /// In en, this message translates to:
  /// **'Routine'**
  String get routine;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @shareCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Share current location'**
  String get shareCurrentLocation;

  /// No description provided for @getCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Get current location'**
  String get getCurrentLocation;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @noDoctorsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No doctors available'**
  String get noDoctorsAvailable;

  /// No description provided for @dr.
  ///
  /// In en, this message translates to:
  /// **'Dr.'**
  String get dr;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @at.
  ///
  /// In en, this message translates to:
  /// **'at'**
  String get at;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
