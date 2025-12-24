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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
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
  /// **'Emergency'**
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

  /// No description provided for @emergencyResponseStarted.
  ///
  /// In en, this message translates to:
  /// **'Emergency response started'**
  String get emergencyResponseStarted;

  /// No description provided for @failedToStartEmergencyResponse.
  ///
  /// In en, this message translates to:
  /// **'Failed to start emergency response'**
  String get failedToStartEmergencyResponse;

  /// No description provided for @emergencyCaseCompleted.
  ///
  /// In en, this message translates to:
  /// **'Emergency case completed'**
  String get emergencyCaseCompleted;

  /// No description provided for @failedToCompleteEmergencyCase.
  ///
  /// In en, this message translates to:
  /// **'Failed to complete emergency case'**
  String get failedToCompleteEmergencyCase;

  /// No description provided for @emergencyCases.
  ///
  /// In en, this message translates to:
  /// **'Emergency Cases'**
  String get emergencyCases;

  /// No description provided for @emergencyText.
  ///
  /// In en, this message translates to:
  /// **'EMERGENCY'**
  String get emergencyText;

  /// No description provided for @petId.
  ///
  /// In en, this message translates to:
  /// **'Pet ID'**
  String get petId;

  /// No description provided for @caseStatus.
  ///
  /// In en, this message translates to:
  /// **'Case'**
  String get caseStatus;

  /// No description provided for @startResponse.
  ///
  /// In en, this message translates to:
  /// **'Start Response'**
  String get startResponse;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @errorLoadingUsers.
  ///
  /// In en, this message translates to:
  /// **'Error loading users'**
  String get errorLoadingUsers;

  /// No description provided for @userAlreadyHasRole.
  ///
  /// In en, this message translates to:
  /// **'User already has this role'**
  String get userAlreadyHasRole;

  /// No description provided for @confirmRoleChange.
  ///
  /// In en, this message translates to:
  /// **'Confirm Role Change'**
  String get confirmRoleChange;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @userRoleUpdated.
  ///
  /// In en, this message translates to:
  /// **'User role updated to'**
  String get userRoleUpdated;

  /// No description provided for @errorUpdatingRole.
  ///
  /// In en, this message translates to:
  /// **'Error updating role'**
  String get errorUpdatingRole;

  /// No description provided for @cannotDeleteOwnAccount.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete your own account'**
  String get cannotDeleteOwnAccount;

  /// No description provided for @deleteUser.
  ///
  /// In en, this message translates to:
  /// **'Delete User'**
  String get deleteUser;

  /// No description provided for @areYouSureDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete'**
  String get areYouSureDelete;

  /// No description provided for @hasBeenDeleted.
  ///
  /// In en, this message translates to:
  /// **'has been deleted'**
  String get hasBeenDeleted;

  /// No description provided for @errorDeletingUser.
  ///
  /// In en, this message translates to:
  /// **'Error deleting user'**
  String get errorDeletingUser;

  /// No description provided for @linkDoctorToDriver.
  ///
  /// In en, this message translates to:
  /// **'Link Doctor to Driver'**
  String get linkDoctorToDriver;

  /// No description provided for @couldNotLaunchGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Could not launch Google Maps'**
  String get couldNotLaunchGoogleMaps;

  /// No description provided for @couldNotOpenGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Could not open Google Maps'**
  String get couldNotOpenGoogleMaps;

  /// No description provided for @navigation.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get navigation;

  /// No description provided for @selectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get selectLocation;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use Current Location'**
  String get useCurrentLocation;

  /// No description provided for @confirmLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get confirmLocation;

  /// No description provided for @viewInGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'View in Google Maps'**
  String get viewInGoogleMaps;

  /// No description provided for @selectYourRole.
  ///
  /// In en, this message translates to:
  /// **'Select your role'**
  String get selectYourRole;

  /// No description provided for @cannotDeleteDoctorWithActiveLink.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete doctor with active driver link. Unlink first.'**
  String get cannotDeleteDoctorWithActiveLink;

  /// No description provided for @cannotDeleteDriverWithActiveLink.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete driver with active doctor link. Unlink first.'**
  String get cannotDeleteDriverWithActiveLink;

  /// No description provided for @permanentDeleteWarning.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove the user and cannot be undone.'**
  String get permanentDeleteWarning;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @noAvailableDriversInArea.
  ///
  /// In en, this message translates to:
  /// **'No available drivers in the same area'**
  String get noAvailableDriversInArea;

  /// No description provided for @welcomeUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome,'**
  String get welcomeUser;

  /// No description provided for @selectRoleToContinue.
  ///
  /// In en, this message translates to:
  /// **'Please select your role to continue:'**
  String get selectRoleToContinue;

  /// No description provided for @serviceArea.
  ///
  /// In en, this message translates to:
  /// **'Service Area'**
  String get serviceArea;

  /// No description provided for @serviceAreaRequired.
  ///
  /// In en, this message translates to:
  /// **'Service Area *'**
  String get serviceAreaRequired;

  /// No description provided for @selectServiceArea.
  ///
  /// In en, this message translates to:
  /// **'Select your service area'**
  String get selectServiceArea;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @doctorProfile.
  ///
  /// In en, this message translates to:
  /// **'Doctor Profile'**
  String get doctorProfile;

  /// No description provided for @editDoctorProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Doctor Profile'**
  String get editDoctorProfile;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @letsSetUpYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Let\'s set up your account'**
  String get letsSetUpYourAccount;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @enterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterYourFullName;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @min6Characters.
  ///
  /// In en, this message translates to:
  /// **'Min 6 characters'**
  String get min6Characters;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @petOwner.
  ///
  /// In en, this message translates to:
  /// **'Pet Owner'**
  String get petOwner;

  /// No description provided for @veterinarian.
  ///
  /// In en, this message translates to:
  /// **'Veterinarian'**
  String get veterinarian;

  /// No description provided for @driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver;

  /// No description provided for @administrator.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get administrator;

  /// No description provided for @selectYourServiceArea.
  ///
  /// In en, this message translates to:
  /// **'Select your service area'**
  String get selectYourServiceArea;

  /// No description provided for @pleaseSelectServiceArea.
  ///
  /// In en, this message translates to:
  /// **'Please select a service area'**
  String get pleaseSelectServiceArea;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @google.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get google;

  /// No description provided for @facebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get facebook;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @pleaseEnterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get pleaseEnterYourFullName;

  /// No description provided for @pleaseEnterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterYourEmail;

  /// No description provided for @pleaseEnterValidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get pleaseEnterValidEmailAddress;

  /// No description provided for @passwordMustBeAtLeast6Characters.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters long'**
  String get passwordMustBeAtLeast6Characters;

  /// No description provided for @pleaseSelectServiceAreaForYourRole.
  ///
  /// In en, this message translates to:
  /// **'Please select a service area for your role'**
  String get pleaseSelectServiceAreaForYourRole;

  /// No description provided for @welcomeBackToVet2U.
  ///
  /// In en, this message translates to:
  /// **'Welcome back to Vet2U'**
  String get welcomeBackToVet2U;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @pleaseEnterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterYourPassword;

  /// No description provided for @selectAreaWhereYouWillProvideServices.
  ///
  /// In en, this message translates to:
  /// **'Select the area where you will provide services:'**
  String get selectAreaWhereYouWillProvideServices;

  /// No description provided for @pleaseSelectSpecies.
  ///
  /// In en, this message translates to:
  /// **'Please select species'**
  String get pleaseSelectSpecies;

  /// No description provided for @pleaseEnterPetName.
  ///
  /// In en, this message translates to:
  /// **'Please enter pet name'**
  String get pleaseEnterPetName;

  /// No description provided for @noDoctorsAvailableAtTheMomentPleaseCheckBackLater.
  ///
  /// In en, this message translates to:
  /// **'No doctors available at the moment. Please check back later.'**
  String get noDoctorsAvailableAtTheMomentPleaseCheckBackLater;

  /// No description provided for @availableTeams.
  ///
  /// In en, this message translates to:
  /// **'Available Teams'**
  String get availableTeams;

  /// No description provided for @doctorsAvailableForHomeVisits.
  ///
  /// In en, this message translates to:
  /// **'doctor(s) available for home visits'**
  String get doctorsAvailableForHomeVisits;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @chooseHowYouWouldLikeToPayForThisAppointment.
  ///
  /// In en, this message translates to:
  /// **'Choose how you would like to pay for this appointment'**
  String get chooseHowYouWouldLikeToPayForThisAppointment;

  /// No description provided for @payOnline.
  ///
  /// In en, this message translates to:
  /// **'Pay Online'**
  String get payOnline;

  /// No description provided for @securePaymentWithCard.
  ///
  /// In en, this message translates to:
  /// **'Secure payment with card'**
  String get securePaymentWithCard;

  /// No description provided for @payOnArrival.
  ///
  /// In en, this message translates to:
  /// **'Pay on Arrival'**
  String get payOnArrival;

  /// No description provided for @payCashWhenServiceIsProvided.
  ///
  /// In en, this message translates to:
  /// **'Pay cash when service is provided'**
  String get payCashWhenServiceIsProvided;

  /// No description provided for @pleaseCaptureYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Please capture your location'**
  String get pleaseCaptureYourLocation;

  /// No description provided for @vet2UDashboard.
  ///
  /// In en, this message translates to:
  /// **'Vet2U Dashboard'**
  String get vet2UDashboard;

  /// No description provided for @bookAVisit.
  ///
  /// In en, this message translates to:
  /// **'Book a visit'**
  String get bookAVisit;

  /// No description provided for @addYourFirstPet.
  ///
  /// In en, this message translates to:
  /// **'Add your first pet'**
  String get addYourFirstPet;

  /// No description provided for @addPet.
  ///
  /// In en, this message translates to:
  /// **'Add Pet'**
  String get addPet;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @failedToSendEmergencyRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to send emergency request'**
  String get failedToSendEmergencyRequest;

  /// No description provided for @myPets.
  ///
  /// In en, this message translates to:
  /// **'My Pets'**
  String get myPets;

  /// No description provided for @noPetsRegisteredYet.
  ///
  /// In en, this message translates to:
  /// **'No pets registered yet'**
  String get noPetsRegisteredYet;

  /// No description provided for @addYourPetsToBookAppointments.
  ///
  /// In en, this message translates to:
  /// **'Add your pets to book appointments and manage their care'**
  String get addYourPetsToBookAppointments;

  /// No description provided for @addYourFirstPetButton.
  ///
  /// In en, this message translates to:
  /// **'Add Your First Pet'**
  String get addYourFirstPetButton;

  /// No description provided for @addPetButton.
  ///
  /// In en, this message translates to:
  /// **'Add Pet'**
  String get addPetButton;

  /// No description provided for @loadingYourDashboard.
  ///
  /// In en, this message translates to:
  /// **'Loading your dashboard...'**
  String get loadingYourDashboard;

  /// No description provided for @usingDefaultLocation.
  ///
  /// In en, this message translates to:
  /// **'Using default location. You can still select a location on the map.'**
  String get usingDefaultLocation;

  /// No description provided for @errorGettingCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Error getting current location'**
  String errorGettingCurrentLocation(Object error);

  /// No description provided for @startNavigation.
  ///
  /// In en, this message translates to:
  /// **'Start Navigation'**
  String get startNavigation;

  /// No description provided for @tapOnTheMapToSelectALocation.
  ///
  /// In en, this message translates to:
  /// **'Tap on the map to select a location'**
  String get tapOnTheMapToSelectALocation;

  /// No description provided for @completePayment.
  ///
  /// In en, this message translates to:
  /// **'Complete Payment'**
  String get completePayment;

  /// No description provided for @paymentSummary.
  ///
  /// In en, this message translates to:
  /// **'Payment Summary'**
  String get paymentSummary;

  /// No description provided for @cardDetails.
  ///
  /// In en, this message translates to:
  /// **'Card Details'**
  String get cardDetails;

  /// No description provided for @youWillPayInCash.
  ///
  /// In en, this message translates to:
  /// **'You will pay in cash when the service is delivered.'**
  String get youWillPayInCash;

  /// No description provided for @yourPaymentInformationIsSecure.
  ///
  /// In en, this message translates to:
  /// **'Your payment information is secure'**
  String get yourPaymentInformationIsSecure;

  /// No description provided for @paymentFailedPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Payment failed. Please try again.'**
  String get paymentFailedPleaseTryAgain;

  /// No description provided for @paymentError.
  ///
  /// In en, this message translates to:
  /// **'Payment error: {error}'**
  String paymentError(Object error);

  /// No description provided for @paymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentHistory;

  /// No description provided for @invoice.
  ///
  /// In en, this message translates to:
  /// **'INVOICE'**
  String get invoice;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @serviceDetails.
  ///
  /// In en, this message translates to:
  /// **'Service Details'**
  String get serviceDetails;

  /// No description provided for @paymentBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Payment Breakdown'**
  String get paymentBreakdown;

  /// No description provided for @paymentInformation.
  ///
  /// In en, this message translates to:
  /// **'Payment Information'**
  String get paymentInformation;

  /// No description provided for @downloadInvoice.
  ///
  /// In en, this message translates to:
  /// **'Download Invoice'**
  String get downloadInvoice;

  /// No description provided for @requestRefund.
  ///
  /// In en, this message translates to:
  /// **'Request Refund'**
  String get requestRefund;

  /// No description provided for @retryPayment.
  ///
  /// In en, this message translates to:
  /// **'Retry Payment'**
  String get retryPayment;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @invoiceDownloadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Invoice downloaded successfully'**
  String get invoiceDownloadedSuccessfully;

  /// No description provided for @failedToDownloadInvoice.
  ///
  /// In en, this message translates to:
  /// **'Failed to download invoice: {error}'**
  String failedToDownloadInvoice(Object error);

  /// No description provided for @requestRefundTitle.
  ///
  /// In en, this message translates to:
  /// **'Request Refund'**
  String get requestRefundTitle;

  /// No description provided for @areYouSureYouWantToRequestARefund.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to request a refund for this payment?'**
  String get areYouSureYouWantToRequestARefund;

  /// No description provided for @requestRefundButton.
  ///
  /// In en, this message translates to:
  /// **'Request Refund'**
  String get requestRefundButton;

  /// No description provided for @supportContactFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Support contact feature coming soon. Please call our support line.'**
  String get supportContactFeatureComingSoon;

  /// No description provided for @myAppointments.
  ///
  /// In en, this message translates to:
  /// **'My Appointments'**
  String get myAppointments;

  /// No description provided for @past.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get past;

  /// No description provided for @noAppointments.
  ///
  /// In en, this message translates to:
  /// **'No appointments'**
  String get noAppointments;

  /// No description provided for @noUpcomingAppointments.
  ///
  /// In en, this message translates to:
  /// **'No upcoming appointments'**
  String get noUpcomingAppointments;

  /// No description provided for @noPastAppointments.
  ///
  /// In en, this message translates to:
  /// **'No past appointments'**
  String get noPastAppointments;

  /// No description provided for @cancelAppointment.
  ///
  /// In en, this message translates to:
  /// **'Cancel Appointment'**
  String get cancelAppointment;

  /// No description provided for @areYouSureYouWantToCancelThisAppointment.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this appointment?'**
  String get areYouSureYouWantToCancelThisAppointment;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @yesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get yesCancel;

  /// No description provided for @confirmAppointment.
  ///
  /// In en, this message translates to:
  /// **'Confirm Appointment'**
  String get confirmAppointment;

  /// No description provided for @areYouSureYouWantToConfirmThisAppointment.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to confirm this appointment? It will be added to your calendar after payment.'**
  String get areYouSureYouWantToConfirmThisAppointment;

  /// No description provided for @yesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Yes, Confirm'**
  String get yesConfirm;

  /// No description provided for @appointmentCancelled.
  ///
  /// In en, this message translates to:
  /// **'Appointment cancelled'**
  String get appointmentCancelled;

  /// No description provided for @appointmentConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Appointment confirmed'**
  String get appointmentConfirmed;

  /// No description provided for @appointmentsRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Appointments refreshed'**
  String get appointmentsRefreshed;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @addToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Add to Calendar'**
  String get addToCalendar;

  /// No description provided for @syncedToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Synced to Calendar'**
  String get syncedToCalendar;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @receiveRemindersAndUpdates.
  ///
  /// In en, this message translates to:
  /// **'Receive reminders and updates'**
  String get receiveRemindersAndUpdates;

  /// No description provided for @reminderTypes.
  ///
  /// In en, this message translates to:
  /// **'Reminder Types'**
  String get reminderTypes;

  /// No description provided for @vaccinationReminders.
  ///
  /// In en, this message translates to:
  /// **'Vaccination Reminders'**
  String get vaccinationReminders;

  /// No description provided for @getRemindedAboutUpcomingVaccinations.
  ///
  /// In en, this message translates to:
  /// **'Get reminded about upcoming vaccinations'**
  String get getRemindedAboutUpcomingVaccinations;

  /// No description provided for @checkupReminders.
  ///
  /// In en, this message translates to:
  /// **'Checkup Reminders'**
  String get checkupReminders;

  /// No description provided for @remindersForScheduledVeterinaryCheckups.
  ///
  /// In en, this message translates to:
  /// **'Reminders for scheduled veterinary checkups'**
  String get remindersForScheduledVeterinaryCheckups;

  /// No description provided for @followUpReminders.
  ///
  /// In en, this message translates to:
  /// **'Follow-up Reminders'**
  String get followUpReminders;

  /// No description provided for @remindersForFollowUpAppointments.
  ///
  /// In en, this message translates to:
  /// **'Reminders for follow-up appointments'**
  String get remindersForFollowUpAppointments;

  /// No description provided for @appointmentReminders.
  ///
  /// In en, this message translates to:
  /// **'Appointment Reminders'**
  String get appointmentReminders;

  /// No description provided for @getNotifiedBeforeYourAppointments.
  ///
  /// In en, this message translates to:
  /// **'Get notified before your appointments'**
  String get getNotifiedBeforeYourAppointments;

  /// No description provided for @mobileClinicAlerts.
  ///
  /// In en, this message translates to:
  /// **'Mobile Clinic Alerts'**
  String get mobileClinicAlerts;

  /// No description provided for @notificationsWhenMobileClinicsAreArriving.
  ///
  /// In en, this message translates to:
  /// **'Notifications when mobile clinics are arriving'**
  String get notificationsWhenMobileClinicsAreArriving;

  /// No description provided for @sendTestNotification.
  ///
  /// In en, this message translates to:
  /// **'Send Test Notification'**
  String get sendTestNotification;

  /// No description provided for @testNotificationSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent!'**
  String get testNotificationSent;

  /// No description provided for @testNotificationsHelpYouVerify.
  ///
  /// In en, this message translates to:
  /// **'Test notifications help you verify that your notification settings are working correctly.'**
  String get testNotificationsHelpYouVerify;

  /// No description provided for @vet2U.
  ///
  /// In en, this message translates to:
  /// **'Vet2U'**
  String get vet2U;

  /// No description provided for @yourPetsHealthCompanion.
  ///
  /// In en, this message translates to:
  /// **'Your Pet\'s Health Companion'**
  String get yourPetsHealthCompanion;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @trackDrivers.
  ///
  /// In en, this message translates to:
  /// **'Track Drivers'**
  String get trackDrivers;

  /// No description provided for @selectDistrict.
  ///
  /// In en, this message translates to:
  /// **'Select District'**
  String get selectDistrict;

  /// No description provided for @allSpecialties.
  ///
  /// In en, this message translates to:
  /// **'All Specialties'**
  String get allSpecialties;

  /// No description provided for @generalPractice.
  ///
  /// In en, this message translates to:
  /// **'General Practice'**
  String get generalPractice;

  /// No description provided for @surgery.
  ///
  /// In en, this message translates to:
  /// **'Surgery'**
  String get surgery;

  /// No description provided for @dermatology.
  ///
  /// In en, this message translates to:
  /// **'Dermatology'**
  String get dermatology;

  /// No description provided for @availableOnly.
  ///
  /// In en, this message translates to:
  /// **'Available Only'**
  String get availableOnly;

  /// No description provided for @documentDownloadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Document downloaded successfully'**
  String get documentDownloadedSuccessfully;

  /// No description provided for @failedToDownloadDocument.
  ///
  /// In en, this message translates to:
  /// **'Failed to download document'**
  String failedToDownloadDocument(Object error);

  /// No description provided for @errorDownloadingDocument.
  ///
  /// In en, this message translates to:
  /// **'Error downloading document: {error}'**
  String errorDownloadingDocument(Object error);

  /// No description provided for @documentHistory.
  ///
  /// In en, this message translates to:
  /// **'Document History'**
  String get documentHistory;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @filterByPetOptional.
  ///
  /// In en, this message translates to:
  /// **'Filter by pet (optional)'**
  String get filterByPetOptional;

  /// No description provided for @allPets.
  ///
  /// In en, this message translates to:
  /// **'All pets'**
  String get allPets;

  /// No description provided for @uploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploaded;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @viewHistory.
  ///
  /// In en, this message translates to:
  /// **'View History'**
  String get viewHistory;

  /// No description provided for @driverProfile.
  ///
  /// In en, this message translates to:
  /// **'Driver Profile'**
  String get driverProfile;

  /// No description provided for @editDriverProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Driver Profile'**
  String get editDriverProfile;

  /// No description provided for @driverLicenseNumber.
  ///
  /// In en, this message translates to:
  /// **'Driver License Number'**
  String get driverLicenseNumber;

  /// No description provided for @professionalDriverLicenseNumber.
  ///
  /// In en, this message translates to:
  /// **'Professional driver license number'**
  String get professionalDriverLicenseNumber;

  /// No description provided for @vehicleType.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Type'**
  String get vehicleType;

  /// No description provided for @vehicleTypeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Van, Truck, etc.'**
  String get vehicleTypeHint;

  /// No description provided for @phoneRequiredForDrivers.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required for drivers'**
  String get phoneRequiredForDrivers;

  /// No description provided for @vehicleTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Vehicle type is required'**
  String get vehicleTypeRequired;

  /// No description provided for @updateYourProfessionalInformation.
  ///
  /// In en, this message translates to:
  /// **'Update your professional information'**
  String get updateYourProfessionalInformation;

  /// No description provided for @profilePictureUploadComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Profile picture upload coming soon'**
  String get profilePictureUploadComingSoon;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get changePhoto;

  /// No description provided for @professionalInformation.
  ///
  /// In en, this message translates to:
  /// **'Professional Information'**
  String get professionalInformation;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @enableToChangeYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enable to change your password'**
  String get enableToChangeYourPassword;

  /// No description provided for @yourProfileInformationHelpsUs.
  ///
  /// In en, this message translates to:
  /// **'Your profile information helps us contact you and secure your account.'**
  String get yourProfileInformationHelpsUs;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @updateYourPersonalInformation.
  ///
  /// In en, this message translates to:
  /// **'Update your personal information'**
  String get updateYourPersonalInformation;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @receiveAppointmentRemindersAndUpdates.
  ///
  /// In en, this message translates to:
  /// **'Receive appointment reminders and updates'**
  String get receiveAppointmentRemindersAndUpdates;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @biometricLogin.
  ///
  /// In en, this message translates to:
  /// **'Biometric Login'**
  String get biometricLogin;

  /// No description provided for @useFingerprintOrFaceUnlock.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint or face unlock'**
  String get useFingerprintOrFaceUnlock;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @switchBetweenLightAndDarkThemes.
  ///
  /// In en, this message translates to:
  /// **'Switch between light and dark themes'**
  String get switchBetweenLightAndDarkThemes;

  /// No description provided for @notificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Notification Preferences'**
  String get notificationPreferences;

  /// No description provided for @manageRemindersAndAlerts.
  ///
  /// In en, this message translates to:
  /// **'Manage reminders and alerts'**
  String get manageRemindersAndAlerts;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @areYouSureYouWantToLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get areYouSureYouWantToLogout;

  /// No description provided for @dataExportFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Data export feature coming soon'**
  String get dataExportFeatureComingSoon;

  /// No description provided for @exportMyData.
  ///
  /// In en, this message translates to:
  /// **'Export My Data'**
  String get exportMyData;

  /// No description provided for @accountDeletionFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Account deletion feature coming soon'**
  String get accountDeletionFeatureComingSoon;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @errorPickingImage.
  ///
  /// In en, this message translates to:
  /// **'Error picking image'**
  String get errorPickingImage;

  /// No description provided for @chooseImageSource.
  ///
  /// In en, this message translates to:
  /// **'Choose Image Source'**
  String get chooseImageSource;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @deletePet.
  ///
  /// In en, this message translates to:
  /// **'Delete Pet'**
  String get deletePet;

  /// No description provided for @areYouSureYouWantToDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete'**
  String get areYouSureYouWantToDelete;

  /// No description provided for @petDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'deleted successfully'**
  String get petDeletedSuccessfully;

  /// No description provided for @editPet.
  ///
  /// In en, this message translates to:
  /// **'Edit Pet'**
  String get editPet;

  /// No description provided for @species.
  ///
  /// In en, this message translates to:
  /// **'Species'**
  String get species;

  /// No description provided for @petName.
  ///
  /// In en, this message translates to:
  /// **'Pet Name'**
  String get petName;

  /// No description provided for @breedOptional.
  ///
  /// In en, this message translates to:
  /// **'Breed (Optional)'**
  String get breedOptional;

  /// No description provided for @dateOfBirthOptional.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth (Optional)'**
  String get dateOfBirthOptional;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get notesOptional;

  /// No description provided for @medicalHistorySummaryOptional.
  ///
  /// In en, this message translates to:
  /// **'Medical History Summary (Optional)'**
  String get medicalHistorySummaryOptional;

  /// No description provided for @userNotAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'User not authenticated'**
  String get userNotAuthenticated;

  /// No description provided for @petAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Pet added successfully'**
  String get petAddedSuccessfully;

  /// No description provided for @petUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Pet updated successfully'**
  String get petUpdatedSuccessfully;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @petsRegistered.
  ///
  /// In en, this message translates to:
  /// **'pet(s) registered'**
  String get petsRegistered;

  /// No description provided for @tapAPetToViewOrUpdateItsDetails.
  ///
  /// In en, this message translates to:
  /// **'Tap a pet to view or update its details'**
  String get tapAPetToViewOrUpdateItsDetails;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @medical.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get medical;

  /// No description provided for @id.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get id;

  /// No description provided for @accessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access Denied'**
  String get accessDenied;

  /// No description provided for @youMustBeLinkedToADoctor.
  ///
  /// In en, this message translates to:
  /// **'You must be linked to a doctor before assigning a van'**
  String get youMustBeLinkedToADoctor;

  /// No description provided for @successfullyAssignedVan.
  ///
  /// In en, this message translates to:
  /// **'Successfully assigned van'**
  String get successfullyAssignedVan;

  /// No description provided for @failedToAssignVan.
  ///
  /// In en, this message translates to:
  /// **'Failed to assign van'**
  String get failedToAssignVan;

  /// No description provided for @vanUnassignedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Van unassigned successfully'**
  String get vanUnassignedSuccessfully;

  /// No description provided for @failedToUnassignVan.
  ///
  /// In en, this message translates to:
  /// **'Failed to unassign van'**
  String get failedToUnassignVan;

  /// No description provided for @selectVan.
  ///
  /// In en, this message translates to:
  /// **'Select Van'**
  String get selectVan;

  /// No description provided for @currentlyAssignedVan.
  ///
  /// In en, this message translates to:
  /// **'Currently Assigned Van'**
  String get currentlyAssignedVan;

  /// No description provided for @license.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get license;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @capacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get capacity;

  /// No description provided for @passengers.
  ///
  /// In en, this message translates to:
  /// **'passenger(s)'**
  String get passengers;

  /// No description provided for @availableVans.
  ///
  /// In en, this message translates to:
  /// **'Available Vans'**
  String get availableVans;

  /// No description provided for @noVansAvailableForAssignment.
  ///
  /// In en, this message translates to:
  /// **'No vans available for assignment'**
  String get noVansAvailableForAssignment;

  /// No description provided for @assign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// No description provided for @allVans.
  ///
  /// In en, this message translates to:
  /// **'All Vans'**
  String get allVans;

  /// No description provided for @assignedToYou.
  ///
  /// In en, this message translates to:
  /// **'Assigned to you'**
  String get assignedToYou;

  /// No description provided for @assignedToAnotherDriver.
  ///
  /// In en, this message translates to:
  /// **'Assigned to another driver'**
  String get assignedToAnotherDriver;

  /// No description provided for @unassign.
  ///
  /// In en, this message translates to:
  /// **'Unassign'**
  String get unassign;

  /// No description provided for @noEmergencyCasesAssigned.
  ///
  /// In en, this message translates to:
  /// **'No emergency cases assigned'**
  String get noEmergencyCasesAssigned;

  /// No description provided for @emergencyCasesWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Emergency cases will appear here when assigned'**
  String get emergencyCasesWillAppearHere;

  /// No description provided for @medicalVisit.
  ///
  /// In en, this message translates to:
  /// **'Medical Visit'**
  String get medicalVisit;

  /// No description provided for @noPetsFound.
  ///
  /// In en, this message translates to:
  /// **'No Pets Found'**
  String get noPetsFound;

  /// No description provided for @needToAddPetBeforeBooking.
  ///
  /// In en, this message translates to:
  /// **'You need to add at least one pet before booking an appointment. Would you like to add a pet now?'**
  String get needToAddPetBeforeBooking;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started!'**
  String get getStarted;

  /// No description provided for @addPetProfileToBook.
  ///
  /// In en, this message translates to:
  /// **'Add your pet profile to start booking veterinary services.'**
  String get addPetProfileToBook;

  /// No description provided for @readyToBook.
  ///
  /// In en, this message translates to:
  /// **'Ready to Book?'**
  String get readyToBook;

  /// No description provided for @scheduleVetVisitForPet.
  ///
  /// In en, this message translates to:
  /// **'Schedule a veterinary visit for your pet.'**
  String get scheduleVetVisitForPet;

  /// No description provided for @ourServices.
  ///
  /// In en, this message translates to:
  /// **'Our Services'**
  String get ourServices;

  /// No description provided for @booking.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get booking;

  /// No description provided for @scheduleAVisit.
  ///
  /// In en, this message translates to:
  /// **'Schedule a Visit'**
  String get scheduleAVisit;

  /// No description provided for @records.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get records;

  /// No description provided for @healthRecords.
  ///
  /// In en, this message translates to:
  /// **'Health Records'**
  String get healthRecords;

  /// No description provided for @immediateCare.
  ///
  /// In en, this message translates to:
  /// **'Immediate Care'**
  String get immediateCare;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @managePayments.
  ///
  /// In en, this message translates to:
  /// **'Manage Payments'**
  String get managePayments;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon!'**
  String get comingSoon;

  /// No description provided for @emergencyServicesComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Emergency services coming soon!'**
  String get emergencyServicesComingSoon;

  /// No description provided for @paymentManagementComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Payment management coming soon!'**
  String get paymentManagementComingSoon;

  /// No description provided for @petRegistered.
  ///
  /// In en, this message translates to:
  /// **'Pet Registered'**
  String get petRegistered;

  /// No description provided for @noPetsYet.
  ///
  /// In en, this message translates to:
  /// **'No Pets Yet'**
  String get noPetsYet;

  /// No description provided for @prescriptionsLabResultsAndMore.
  ///
  /// In en, this message translates to:
  /// **'Prescriptions, lab results, and more'**
  String get prescriptionsLabResultsAndMore;

  /// No description provided for @noMedicalDocumentsFound.
  ///
  /// In en, this message translates to:
  /// **'No medical documents found'**
  String get noMedicalDocumentsFound;

  /// No description provided for @documentsUploadedByDoctorWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Documents uploaded by your doctor will appear here'**
  String get documentsUploadedByDoctorWillAppearHere;

  /// No description provided for @uploadedLabel.
  ///
  /// In en, this message translates to:
  /// **'Uploaded:'**
  String get uploadedLabel;

  /// No description provided for @errorLinkingUsers.
  ///
  /// In en, this message translates to:
  /// **'Error linking users'**
  String errorLinkingUsers(Object error);

  /// No description provided for @assignVanToTeam.
  ///
  /// In en, this message translates to:
  /// **'Assign Van to Team'**
  String get assignVanToTeam;

  /// No description provided for @cancelLinking.
  ///
  /// In en, this message translates to:
  /// **'Cancel Linking'**
  String get cancelLinking;

  /// No description provided for @errorAssigningVan.
  ///
  /// In en, this message translates to:
  /// **'Error assigning van: {error}'**
  String errorAssigningVan(Object error);

  /// No description provided for @linkingCancelledNoVanAssigned.
  ///
  /// In en, this message translates to:
  /// **'Linking cancelled - no van assigned'**
  String get linkingCancelledNoVanAssigned;

  /// No description provided for @unlinkedFrom.
  ///
  /// In en, this message translates to:
  /// **'Unlinked {doctorName} from {driverName}'**
  String unlinkedFrom(Object doctorName, Object driverName);

  /// No description provided for @errorUnlinkingUsers.
  ///
  /// In en, this message translates to:
  /// **'Error unlinking users'**
  String errorUnlinkingUsers(Object error);

  /// No description provided for @addNewUser.
  ///
  /// In en, this message translates to:
  /// **'Add New User'**
  String get addNewUser;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @doctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctor;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @areaRequiredForDoctorsDrivers.
  ///
  /// In en, this message translates to:
  /// **'Area is required for doctors and drivers'**
  String get areaRequiredForDoctorsDrivers;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String error(Object error);

  /// No description provided for @confirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get confirmLogout;

  /// No description provided for @errorLoggingOut.
  ///
  /// In en, this message translates to:
  /// **'Error logging out'**
  String errorLoggingOut(Object error);

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @veterinaryServices.
  ///
  /// In en, this message translates to:
  /// **'Veterinary Services'**
  String get veterinaryServices;

  /// No description provided for @ammanJordan.
  ///
  /// In en, this message translates to:
  /// **'Amman, Jordan'**
  String get ammanJordan;

  /// No description provided for @phonePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Phone: +962 XX XXX XXXX'**
  String get phonePlaceholder;

  /// No description provided for @emailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Email: info@vetcare.jo'**
  String get emailPlaceholder;

  /// No description provided for @invoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice #'**
  String get invoiceNumber;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @customerInformation.
  ///
  /// In en, this message translates to:
  /// **'Customer Information'**
  String get customerInformation;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax (16%)'**
  String get tax;

  /// No description provided for @transactionId.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get transactionId;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @noAvailableVans.
  ///
  /// In en, this message translates to:
  /// **'No available vans to assign. Please create vans first.'**
  String get noAvailableVans;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Vet2U'**
  String get welcomeMessage;

  /// No description provided for @languageToggle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageToggle;

  /// No description provided for @pet.
  ///
  /// In en, this message translates to:
  /// **'Pet'**
  String get pet;

  /// No description provided for @medicalRecord.
  ///
  /// In en, this message translates to:
  /// **'Medical Record'**
  String get medicalRecord;

  /// No description provided for @uploadDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload Document'**
  String get uploadDocument;

  /// No description provided for @selectFile.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get selectFile;

  /// No description provided for @accessLevel.
  ///
  /// In en, this message translates to:
  /// **'Access Level'**
  String get accessLevel;

  /// No description provided for @private.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get private;

  /// No description provided for @public.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get public;

  /// No description provided for @restricted.
  ///
  /// In en, this message translates to:
  /// **'Restricted'**
  String get restricted;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @documentUploadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Document uploaded successfully'**
  String get documentUploadedSuccessfully;

  /// No description provided for @failedToUploadDocument.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload document'**
  String get failedToUploadDocument;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @specialization.
  ///
  /// In en, this message translates to:
  /// **'Specialization'**
  String get specialization;

  /// No description provided for @licenseNumber.
  ///
  /// In en, this message translates to:
  /// **'License Number'**
  String get licenseNumber;

  /// No description provided for @yearsOfExperience.
  ///
  /// In en, this message translates to:
  /// **'Years of Experience'**
  String get yearsOfExperience;

  /// No description provided for @professionalBio.
  ///
  /// In en, this message translates to:
  /// **'Professional Bio'**
  String get professionalBio;

  /// No description provided for @enablePasswordChange.
  ///
  /// In en, this message translates to:
  /// **'Enable to change your password'**
  String get enablePasswordChange;

  /// No description provided for @profileInfoHelp.
  ///
  /// In en, this message translates to:
  /// **'Your profile information helps us contact you and secure your account.'**
  String get profileInfoHelp;

  /// No description provided for @tapToSelectFile.
  ///
  /// In en, this message translates to:
  /// **'Tap to select a file'**
  String get tapToSelectFile;

  /// No description provided for @supportedFormats.
  ///
  /// In en, this message translates to:
  /// **'Supported: PDF, JPG, PNG, DOC, DOCX, TXT (Max 10MB)'**
  String get supportedFormats;

  /// No description provided for @linkToMedicalRecord.
  ///
  /// In en, this message translates to:
  /// **'Link to Medical Record (Optional)'**
  String get linkToMedicalRecord;

  /// No description provided for @associateWithRecord.
  ///
  /// In en, this message translates to:
  /// **'Associate this document with a specific medical record'**
  String get associateWithRecord;

  /// No description provided for @noSpecificRecord.
  ///
  /// In en, this message translates to:
  /// **'No specific record'**
  String get noSpecificRecord;

  /// No description provided for @accessLevelDescription.
  ///
  /// In en, this message translates to:
  /// **'Private: Only pet owner and uploader\nPublic: Anyone can view\nRestricted: Only doctors and admins'**
  String get accessLevelDescription;

  /// No description provided for @pleaseSelectFile.
  ///
  /// In en, this message translates to:
  /// **'Please select a file'**
  String get pleaseSelectFile;

  /// No description provided for @errorPickingFile.
  ///
  /// In en, this message translates to:
  /// **'Error picking file'**
  String get errorPickingFile;

  /// No description provided for @errorUploadingDocument.
  ///
  /// In en, this message translates to:
  /// **'Error uploading document'**
  String get errorUploadingDocument;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required for doctors'**
  String get phoneRequired;

  /// No description provided for @specializationRequired.
  ///
  /// In en, this message translates to:
  /// **'Specialization is required'**
  String get specializationRequired;

  /// No description provided for @licenseRequired.
  ///
  /// In en, this message translates to:
  /// **'License number is required'**
  String get licenseRequired;

  /// No description provided for @experienceRequired.
  ///
  /// In en, this message translates to:
  /// **'Years of experience is required'**
  String get experienceRequired;

  /// No description provided for @areaRequired.
  ///
  /// In en, this message translates to:
  /// **'Service area is required'**
  String get areaRequired;

  /// No description provided for @bioRequired.
  ///
  /// In en, this message translates to:
  /// **'Professional bio is required'**
  String get bioRequired;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @invalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get invalidPhoneNumber;

  /// No description provided for @invalidExperience.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number of years'**
  String get invalidExperience;

  /// No description provided for @experienceTooHigh.
  ///
  /// In en, this message translates to:
  /// **'Please enter a realistic number of years'**
  String get experienceTooHigh;

  /// No description provided for @nameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameMinLength;

  /// No description provided for @bioMinLength.
  ///
  /// In en, this message translates to:
  /// **'Bio must be at least 10 characters'**
  String get bioMinLength;

  /// No description provided for @welcomeBackUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}!'**
  String welcomeBackUser(Object name);

  /// No description provided for @trustedPartnerPetCare.
  ///
  /// In en, this message translates to:
  /// **'Your trusted partner in pet care'**
  String get trustedPartnerPetCare;

  /// No description provided for @compassionateVeterinaryCare.
  ///
  /// In en, this message translates to:
  /// **'Providing compassionate veterinary care with professional expertise. Our mobile clinic brings quality healthcare to your doorstep for the comfort and convenience of your beloved pets.'**
  String get compassionateVeterinaryCare;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'4.9/5.0'**
  String get rating;

  /// No description provided for @happyPets.
  ///
  /// In en, this message translates to:
  /// **'1000+ Happy Pets'**
  String get happyPets;

  /// No description provided for @successStories.
  ///
  /// In en, this message translates to:
  /// **'Success Stories'**
  String get successStories;

  /// No description provided for @vetCareClinic.
  ///
  /// In en, this message translates to:
  /// **'VetCare Clinic'**
  String get vetCareClinic;

  /// No description provided for @billTo.
  ///
  /// In en, this message translates to:
  /// **'Bill To'**
  String get billTo;

  /// No description provided for @thankYouVetCare.
  ///
  /// In en, this message translates to:
  /// **'Thank you for choosing VetCare Clinic!'**
  String get thankYouVetCare;

  /// No description provided for @questionsContactSupport.
  ///
  /// In en, this message translates to:
  /// **'For any questions regarding this invoice, please contact our support team.'**
  String get questionsContactSupport;

  /// No description provided for @selectedAddress.
  ///
  /// In en, this message translates to:
  /// **'Selected Address:'**
  String get selectedAddress;

  /// No description provided for @enterAddressManually.
  ///
  /// In en, this message translates to:
  /// **'Enter Address Manually:'**
  String get enterAddressManually;

  /// No description provided for @enterAddressForThisLocation.
  ///
  /// In en, this message translates to:
  /// **'Enter address for this location'**
  String get enterAddressForThisLocation;

  /// No description provided for @noEmail.
  ///
  /// In en, this message translates to:
  /// **'No email'**
  String get noEmail;

  /// No description provided for @savedMyCatEmergency.
  ///
  /// In en, this message translates to:
  /// **'saved my cat\'s life during an emergency. Professional service and quick response!'**
  String get savedMyCatEmergency;

  /// No description provided for @happyPetOwner.
  ///
  /// In en, this message translates to:
  /// **'Happy Pet Owner'**
  String get happyPetOwner;

  /// No description provided for @mobileVetServiceAmazing.
  ///
  /// In en, this message translates to:
  /// **'The mobile vet service is amazing! My dog was so comfortable at home. Highly recommend!'**
  String get mobileVetServiceAmazing;

  /// No description provided for @dogLover.
  ///
  /// In en, this message translates to:
  /// **'Dog Lover'**
  String get dogLover;

  /// No description provided for @affordableProfessionalCaring.
  ///
  /// In en, this message translates to:
  /// **'Affordable, professional, and caring. Vet2U is now my go-to for all my pet\'s needs.'**
  String get affordableProfessionalCaring;

  /// No description provided for @petParent.
  ///
  /// In en, this message translates to:
  /// **'Pet Parent'**
  String get petParent;

  /// No description provided for @scheduleAppointmentForPets.
  ///
  /// In en, this message translates to:
  /// **'Schedule an appointment for your pets'**
  String get scheduleAppointmentForPets;

  /// No description provided for @registerPetsToStartBooking.
  ///
  /// In en, this message translates to:
  /// **'Register your pets to start booking visits.'**
  String get registerPetsToStartBooking;

  /// No description provided for @scheduleAppointments.
  ///
  /// In en, this message translates to:
  /// **'Schedule appointments'**
  String get scheduleAppointments;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @downloadFiles.
  ///
  /// In en, this message translates to:
  /// **'Download files'**
  String get downloadFiles;

  /// No description provided for @urgentCare.
  ///
  /// In en, this message translates to:
  /// **'Urgent care'**
  String get urgentCare;

  /// No description provided for @managePets.
  ///
  /// In en, this message translates to:
  /// **'Manage Pets'**
  String get managePets;

  /// No description provided for @viewAppointments.
  ///
  /// In en, this message translates to:
  /// **'View Appointments'**
  String get viewAppointments;

  /// No description provided for @doctorNamePrefix.
  ///
  /// In en, this message translates to:
  /// **'Dr.'**
  String get doctorNamePrefix;

  /// No description provided for @locationError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String locationError(Object error);

  /// No description provided for @coordinatesFormat.
  ///
  /// In en, this message translates to:
  /// **'Lat: {lat}, Lng: {lng}'**
  String coordinatesFormat(Object lat, Object lng);

  /// No description provided for @locationNotCaptured.
  ///
  /// In en, this message translates to:
  /// **'Location not captured yet'**
  String get locationNotCaptured;

  /// No description provided for @availableTeamsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} teams available for home visits'**
  String availableTeamsCount(Object count);

  /// No description provided for @coordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get coordinates;

  /// No description provided for @doctorNameWithText.
  ///
  /// In en, this message translates to:
  /// **'Dr. {name}'**
  String doctorNameWithText(Object name);

  /// No description provided for @linkedWithDoctor.
  ///
  /// In en, this message translates to:
  /// **'Successfully linked with Dr. {doctorName}'**
  String linkedWithDoctor(Object doctorName);

  /// No description provided for @vanAssignedTo.
  ///
  /// In en, this message translates to:
  /// **'Van \"{vanName}\" assigned to Dr. {doctorName} and {driverName}'**
  String vanAssignedTo(Object doctorName, Object driverName, Object vanName);

  /// No description provided for @teamDoctorDriver.
  ///
  /// In en, this message translates to:
  /// **'Team: Dr. {doctorName} & {driverName}'**
  String teamDoctorDriver(Object doctorName, Object driverName);

  /// No description provided for @doctorAndDriverLinked.
  ///
  /// In en, this message translates to:
  /// **'Dr. {doctorName} and {driverName} have been linked. You must assign them to a van to complete the process.'**
  String doctorAndDriverLinked(Object doctorName, Object driverName);

  /// No description provided for @successfullyLinkedDoctor.
  ///
  /// In en, this message translates to:
  /// **'Successfully linked Dr. {doctorName} to {driverName} and assigned van \"{vanName}\"'**
  String successfullyLinkedDoctor(
    Object doctorName,
    Object driverName,
    Object vanName,
  );

  /// No description provided for @linkedDoctorToDriver.
  ///
  /// In en, this message translates to:
  /// **'Linked Dr. {doctorName} to driver {driverName}'**
  String linkedDoctorToDriver(Object doctorName, Object driverName);

  /// No description provided for @unlinkedDoctorFromDriver.
  ///
  /// In en, this message translates to:
  /// **'Unlinked Dr. {doctorName} from driver {driverName}'**
  String unlinkedDoctorFromDriver(Object doctorName, Object driverName);

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @confirmDeleteMedicalRecord.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this medical record? This action cannot be undone.'**
  String get confirmDeleteMedicalRecord;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @alertPreferences.
  ///
  /// In en, this message translates to:
  /// **'Alert preferences'**
  String get alertPreferences;

  /// No description provided for @notificationSettingsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Notification settings coming soon'**
  String get notificationSettingsComingSoon;

  /// No description provided for @linkedDriver.
  ///
  /// In en, this message translates to:
  /// **'Linked Driver'**
  String get linkedDriver;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get active;

  /// No description provided for @todaysAppointments.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Appointments'**
  String get todaysAppointments;

  /// No description provided for @manageAppointments.
  ///
  /// In en, this message translates to:
  /// **'Manage Appointments'**
  String get manageAppointments;

  /// No description provided for @viewAndUpdatePatientSchedules.
  ///
  /// In en, this message translates to:
  /// **'View and update patient schedules'**
  String get viewAndUpdatePatientSchedules;

  /// No description provided for @recordTreatments.
  ///
  /// In en, this message translates to:
  /// **'Record Treatments'**
  String get recordTreatments;

  /// No description provided for @documentMedicalProcedures.
  ///
  /// In en, this message translates to:
  /// **'Document medical procedures'**
  String get documentMedicalProcedures;

  /// No description provided for @inventoryManagement.
  ///
  /// In en, this message translates to:
  /// **'Inventory Management'**
  String get inventoryManagement;

  /// No description provided for @checkSuppliesAndMedications.
  ///
  /// In en, this message translates to:
  /// **'Check supplies and medications'**
  String get checkSuppliesAndMedications;

  /// No description provided for @medicalRecords.
  ///
  /// In en, this message translates to:
  /// **'Medical Records'**
  String get medicalRecords;

  /// No description provided for @viewAndManagePatientRecords.
  ///
  /// In en, this message translates to:
  /// **'View and manage patient records'**
  String get viewAndManagePatientRecords;

  /// No description provided for @uploadDocuments.
  ///
  /// In en, this message translates to:
  /// **'Upload Documents'**
  String get uploadDocuments;

  /// No description provided for @uploadTreatmentDocumentsAndReports.
  ///
  /// In en, this message translates to:
  /// **'Upload treatment documents and reports'**
  String get uploadTreatmentDocumentsAndReports;

  /// No description provided for @urgentCases.
  ///
  /// In en, this message translates to:
  /// **'Urgent Cases'**
  String get urgentCases;

  /// No description provided for @approveAndManageUrgentServiceRequests.
  ///
  /// In en, this message translates to:
  /// **'Approve and manage urgent service requests'**
  String get approveAndManageUrgentServiceRequests;

  /// No description provided for @medicalRecordsScreen.
  ///
  /// In en, this message translates to:
  /// **'Medical Records'**
  String get medicalRecordsScreen;

  /// No description provided for @addMedicalRecord.
  ///
  /// In en, this message translates to:
  /// **'Add Medical Record'**
  String get addMedicalRecord;

  /// No description provided for @addMedicalRecordsForYourPatients.
  ///
  /// In en, this message translates to:
  /// **'Add medical records for your patients'**
  String get addMedicalRecordsForYourPatients;

  /// No description provided for @addFirstRecord.
  ///
  /// In en, this message translates to:
  /// **'Add First Record'**
  String get addFirstRecord;

  /// No description provided for @medicalRecordDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Medical record deleted successfully'**
  String get medicalRecordDeletedSuccessfully;

  /// No description provided for @updateYourCredentials.
  ///
  /// In en, this message translates to:
  /// **'Update your credentials'**
  String get updateYourCredentials;

  /// No description provided for @scheduleSettings.
  ///
  /// In en, this message translates to:
  /// **'Schedule Settings'**
  String get scheduleSettings;

  /// No description provided for @workingHoursAndAvailability.
  ///
  /// In en, this message translates to:
  /// **'Working hours and availability'**
  String get workingHoursAndAvailability;

  /// No description provided for @additionalNotes.
  ///
  /// In en, this message translates to:
  /// **'Additional Notes'**
  String get additionalNotes;

  /// No description provided for @vanUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Van updated successfully'**
  String get vanUpdatedSuccessfully;

  /// No description provided for @vanAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Van added successfully'**
  String get vanAddedSuccessfully;

  /// No description provided for @errorSavingVan.
  ///
  /// In en, this message translates to:
  /// **'Error saving van'**
  String get errorSavingVan;

  /// No description provided for @deleteVan.
  ///
  /// In en, this message translates to:
  /// **'Delete Van'**
  String get deleteVan;

  /// No description provided for @areYouSureYouWantToDeleteVan.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{vanName}\"? This action cannot be undone.'**
  String areYouSureYouWantToDeleteVan(Object vanName);

  /// No description provided for @vanDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Van deleted successfully'**
  String get vanDeletedSuccessfully;

  /// No description provided for @errorDeletingVan.
  ///
  /// In en, this message translates to:
  /// **'Error deleting van: {error}'**
  String errorDeletingVan(Object error);

  /// No description provided for @vanAssignedToTeam.
  ///
  /// In en, this message translates to:
  /// **'Van \"{vanName}\" assigned to Dr. {doctorName} and {driverName}'**
  String vanAssignedToTeam(
    Object doctorName,
    Object driverName,
    Object vanName,
  );

  /// No description provided for @errorUnassigningVan.
  ///
  /// In en, this message translates to:
  /// **'Error unassigning van: {error}'**
  String errorUnassigningVan(Object error);

  /// No description provided for @youDoNotHavePermissionToAccessThisPage.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to access this page.'**
  String get youDoNotHavePermissionToAccessThisPage;

  /// No description provided for @vanManagement.
  ///
  /// In en, this message translates to:
  /// **'Van Management'**
  String get vanManagement;

  /// No description provided for @editVan.
  ///
  /// In en, this message translates to:
  /// **'Edit Van'**
  String get editVan;

  /// No description provided for @addNewVan.
  ///
  /// In en, this message translates to:
  /// **'Add New Van'**
  String get addNewVan;

  /// No description provided for @vanName.
  ///
  /// In en, this message translates to:
  /// **'Van Name'**
  String get vanName;

  /// No description provided for @vanNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Van name is required'**
  String get vanNameRequired;

  /// No description provided for @licensePlate.
  ///
  /// In en, this message translates to:
  /// **'License Plate'**
  String get licensePlate;

  /// No description provided for @licensePlateRequired.
  ///
  /// In en, this message translates to:
  /// **'License plate is required'**
  String get licensePlateRequired;

  /// No description provided for @capacityRequired.
  ///
  /// In en, this message translates to:
  /// **'Capacity is required'**
  String get capacityRequired;

  /// No description provided for @enterValidCapacity.
  ///
  /// In en, this message translates to:
  /// **'Enter valid capacity'**
  String get enterValidCapacity;

  /// No description provided for @optionalDescription.
  ///
  /// In en, this message translates to:
  /// **'Optional description'**
  String get optionalDescription;

  /// No description provided for @area.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get area;

  /// No description provided for @selectAnArea.
  ///
  /// In en, this message translates to:
  /// **'Select an area'**
  String get selectAnArea;

  /// No description provided for @updateVan.
  ///
  /// In en, this message translates to:
  /// **'Update Van'**
  String get updateVan;

  /// No description provided for @addVan.
  ///
  /// In en, this message translates to:
  /// **'Add Van'**
  String get addVan;

  /// No description provided for @noVansFound.
  ///
  /// In en, this message translates to:
  /// **'No vans found'**
  String get noVansFound;

  /// No description provided for @fullyAssigned.
  ///
  /// In en, this message translates to:
  /// **'Fully Assigned'**
  String get fullyAssigned;

  /// No description provided for @partiallyAssigned.
  ///
  /// In en, this message translates to:
  /// **'Partially Assigned'**
  String get partiallyAssigned;

  /// No description provided for @assignToTeam.
  ///
  /// In en, this message translates to:
  /// **'Assign to Team'**
  String get assignToTeam;

  /// No description provided for @unassignVan.
  ///
  /// In en, this message translates to:
  /// **'Unassign Van'**
  String get unassignVan;

  /// No description provided for @vanNameExample.
  ///
  /// In en, this message translates to:
  /// **'e.g., Vet Van Alpha'**
  String get vanNameExample;

  /// No description provided for @licensePlateExample.
  ///
  /// In en, this message translates to:
  /// **'e.g., VET-001'**
  String get licensePlateExample;

  /// No description provided for @modelExample.
  ///
  /// In en, this message translates to:
  /// **'e.g., Ford Transit'**
  String get modelExample;

  /// No description provided for @numberOfPassengers.
  ///
  /// In en, this message translates to:
  /// **'Number of passengers'**
  String get numberOfPassengers;

  /// No description provided for @areYouSureYouWantToCloseTheApp.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to close the app?'**
  String get areYouSureYouWantToCloseTheApp;

  /// No description provided for @pleaseCloseThisBrowserTabManuallyToExitTheApp.
  ///
  /// In en, this message translates to:
  /// **'Please close this browser tab manually to exit the app'**
  String get pleaseCloseThisBrowserTabManuallyToExitTheApp;

  /// No description provided for @pleaseCloseTheApplicationWindowManuallyToExit.
  ///
  /// In en, this message translates to:
  /// **'Please close the application window manually to exit'**
  String get pleaseCloseTheApplicationWindowManuallyToExit;

  /// No description provided for @noPermissionToAccessPage.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to access this page.'**
  String get noPermissionToAccessPage;

  /// No description provided for @welcomeName.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String welcomeName(Object name);

  /// No description provided for @adminFunctions.
  ///
  /// In en, this message translates to:
  /// **'Admin Functions'**
  String get adminFunctions;

  /// No description provided for @userManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// No description provided for @serviceManagement.
  ///
  /// In en, this message translates to:
  /// **'Service Management'**
  String get serviceManagement;

  /// No description provided for @reportingAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Reporting & Analytics'**
  String get reportingAnalytics;

  /// No description provided for @complianceRecords.
  ///
  /// In en, this message translates to:
  /// **'Compliance & Records'**
  String get complianceRecords;

  /// No description provided for @dataBackupRestore.
  ///
  /// In en, this message translates to:
  /// **'Data Backup & Restore'**
  String get dataBackupRestore;

  /// No description provided for @areaManagement.
  ///
  /// In en, this message translates to:
  /// **'Area Management'**
  String get areaManagement;

  /// No description provided for @systemSettings.
  ///
  /// In en, this message translates to:
  /// **'System Settings'**
  String get systemSettings;

  /// No description provided for @auditLogs.
  ///
  /// In en, this message translates to:
  /// **'Audit Logs'**
  String get auditLogs;

  /// No description provided for @dataExportedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Data exported to clipboard'**
  String get dataExportedToClipboard;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(Object error);

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get importData;

  /// No description provided for @pasteTheExportedJSONDataBelow.
  ///
  /// In en, this message translates to:
  /// **'Paste the exported JSON data below:'**
  String get pasteTheExportedJSONDataBelow;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @dataImportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Data imported successfully'**
  String get dataImportedSuccessfully;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailed(Object error);

  /// No description provided for @addService.
  ///
  /// In en, this message translates to:
  /// **'Add Service'**
  String get addService;

  /// No description provided for @serviceNameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Service name is required'**
  String get serviceNameIsRequired;

  /// No description provided for @validPriceIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Valid price is required'**
  String get validPriceIsRequired;

  /// No description provided for @categoryIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Category is required'**
  String get categoryIsRequired;

  /// No description provided for @serviceAdded.
  ///
  /// In en, this message translates to:
  /// **'Service added'**
  String get serviceAdded;

  /// No description provided for @errorAddingService.
  ///
  /// In en, this message translates to:
  /// **'Error adding service: {error}'**
  String errorAddingService(Object error);

  /// No description provided for @editService.
  ///
  /// In en, this message translates to:
  /// **'Edit Service'**
  String get editService;

  /// No description provided for @serviceUpdated.
  ///
  /// In en, this message translates to:
  /// **'Service updated'**
  String get serviceUpdated;

  /// No description provided for @errorUpdatingService.
  ///
  /// In en, this message translates to:
  /// **'Error updating service: {error}'**
  String errorUpdatingService(Object error);

  /// No description provided for @deleteService.
  ///
  /// In en, this message translates to:
  /// **'Delete Service'**
  String get deleteService;

  /// No description provided for @areYouSureYouWantToDeleteService.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{serviceName}\"?'**
  String areYouSureYouWantToDeleteService(Object serviceName);

  /// No description provided for @serviceDeleted.
  ///
  /// In en, this message translates to:
  /// **'has been deleted'**
  String get serviceDeleted;

  /// No description provided for @errorDeletingService.
  ///
  /// In en, this message translates to:
  /// **'Error deleting service: {error}'**
  String errorDeletingService(Object error);

  /// No description provided for @noServicesFound.
  ///
  /// In en, this message translates to:
  /// **'No services found'**
  String get noServicesFound;

  /// No description provided for @vehicleCheck.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Check'**
  String get vehicleCheck;

  /// No description provided for @vehicleCheckFunctionalityWillBeImplementedHere.
  ///
  /// In en, this message translates to:
  /// **'Vehicle check functionality will be implemented here.'**
  String get vehicleCheckFunctionalityWillBeImplementedHere;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @currentLocationNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Current location not available'**
  String get currentLocationNotAvailable;

  /// No description provided for @couldNotOpenMaps.
  ///
  /// In en, this message translates to:
  /// **'Could not open maps: {error}'**
  String couldNotOpenMaps(Object error);

  /// No description provided for @supportContactFunctionalityWillBeImplemented.
  ///
  /// In en, this message translates to:
  /// **'Support contact functionality will be implemented'**
  String get supportContactFunctionalityWillBeImplemented;

  /// No description provided for @appointmentDetails.
  ///
  /// In en, this message translates to:
  /// **'Appointment Details'**
  String get appointmentDetails;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @navigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// No description provided for @successfullyLinkedWithDoctor.
  ///
  /// In en, this message translates to:
  /// **'Successfully linked with Dr. {doctorName}'**
  String successfullyLinkedWithDoctor(Object doctorName);

  /// No description provided for @failedToLinkWithDoctor.
  ///
  /// In en, this message translates to:
  /// **'Failed to link with doctor'**
  String get failedToLinkWithDoctor;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @addUser.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get addUser;

  /// No description provided for @errorAddingUser.
  ///
  /// In en, this message translates to:
  /// **'Error adding user: {error}'**
  String errorAddingUser(Object error);

  /// No description provided for @setAsOwner.
  ///
  /// In en, this message translates to:
  /// **'Set as Owner'**
  String get setAsOwner;

  /// No description provided for @setAsDoctor.
  ///
  /// In en, this message translates to:
  /// **'Set as Doctor'**
  String get setAsDoctor;

  /// No description provided for @setAsDriver.
  ///
  /// In en, this message translates to:
  /// **'Set as Driver'**
  String get setAsDriver;

  /// No description provided for @setAsAdmin.
  ///
  /// In en, this message translates to:
  /// **'Set as Admin'**
  String get setAsAdmin;

  /// No description provided for @linkToDriver.
  ///
  /// In en, this message translates to:
  /// **'Link to Driver'**
  String get linkToDriver;

  /// No description provided for @unlinkFromDriver.
  ///
  /// In en, this message translates to:
  /// **'Unlink from Driver'**
  String get unlinkFromDriver;

  /// No description provided for @fileSavedToDocumentsFolder.
  ///
  /// In en, this message translates to:
  /// **'File saved to Documents folder'**
  String get fileSavedToDocumentsFolder;

  /// No description provided for @appointmentManagement.
  ///
  /// In en, this message translates to:
  /// **'Appointment Management'**
  String get appointmentManagement;

  /// No description provided for @appointmentAccepted.
  ///
  /// In en, this message translates to:
  /// **'Appointment accepted'**
  String get appointmentAccepted;

  /// No description provided for @appointmentStarted.
  ///
  /// In en, this message translates to:
  /// **'Appointment started'**
  String get appointmentStarted;

  /// No description provided for @rescheduleFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Reschedule feature coming soon'**
  String get rescheduleFeatureComingSoon;

  /// No description provided for @appointmentRejected.
  ///
  /// In en, this message translates to:
  /// **'Appointment rejected'**
  String get appointmentRejected;

  /// No description provided for @locationUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Location updated successfully'**
  String get locationUpdatedSuccessfully;

  /// No description provided for @failedToUpdateLocation.
  ///
  /// In en, this message translates to:
  /// **'Failed to update location'**
  String get failedToUpdateLocation;

  /// No description provided for @paymentProcessingFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment processing failed'**
  String get paymentProcessingFailed;

  /// No description provided for @appointmentCompletedAndTreatmentRecordSaved.
  ///
  /// In en, this message translates to:
  /// **'Appointment completed and treatment record saved'**
  String get appointmentCompletedAndTreatmentRecordSaved;

  /// No description provided for @paymentMarkedAsReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment marked as received'**
  String get paymentMarkedAsReceived;

  /// No description provided for @failedToProcessPayment.
  ///
  /// In en, this message translates to:
  /// **'Failed to process payment'**
  String get failedToProcessPayment;

  /// No description provided for @completeAppointmentAndRecordTreatment.
  ///
  /// In en, this message translates to:
  /// **'Complete Appointment & Record Treatment'**
  String get completeAppointmentAndRecordTreatment;

  /// No description provided for @completeAndSave.
  ///
  /// In en, this message translates to:
  /// **'Complete & Save'**
  String get completeAndSave;

  /// No description provided for @pleaseFillInDiagnosisAndTreatment.
  ///
  /// In en, this message translates to:
  /// **'Please fill in diagnosis and treatment'**
  String get pleaseFillInDiagnosisAndTreatment;

  /// No description provided for @setLocation.
  ///
  /// In en, this message translates to:
  /// **'Set Location'**
  String get setLocation;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @reschedule.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get reschedule;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @startAppointment.
  ///
  /// In en, this message translates to:
  /// **'Start Appointment'**
  String get startAppointment;

  /// No description provided for @markPaymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Mark Payment Received'**
  String get markPaymentReceived;

  /// No description provided for @markComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark Complete'**
  String get markComplete;

  /// No description provided for @settingsSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully'**
  String get settingsSavedSuccessfully;

  /// No description provided for @failedToSaveSomeSettings.
  ///
  /// In en, this message translates to:
  /// **'Failed to save some settings'**
  String get failedToSaveSomeSettings;

  /// No description provided for @saveAllSettings.
  ///
  /// In en, this message translates to:
  /// **'Save All Settings'**
  String get saveAllSettings;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @dog.
  ///
  /// In en, this message translates to:
  /// **'Dog'**
  String get dog;

  /// No description provided for @cat.
  ///
  /// In en, this message translates to:
  /// **'Cat'**
  String get cat;

  /// No description provided for @bird.
  ///
  /// In en, this message translates to:
  /// **'Bird'**
  String get bird;

  /// No description provided for @rabbit.
  ///
  /// In en, this message translates to:
  /// **'Rabbit'**
  String get rabbit;

  /// No description provided for @hamster.
  ///
  /// In en, this message translates to:
  /// **'Hamster'**
  String get hamster;

  /// No description provided for @fish.
  ///
  /// In en, this message translates to:
  /// **'Fish'**
  String get fish;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @emergencyCaseApprovedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Emergency case approved successfully'**
  String get emergencyCaseApprovedSuccessfully;

  /// No description provided for @failedToApproveCase.
  ///
  /// In en, this message translates to:
  /// **'Failed to approve case'**
  String get failedToApproveCase;

  /// No description provided for @emergencyCaseRejected.
  ///
  /// In en, this message translates to:
  /// **'Emergency case rejected'**
  String get emergencyCaseRejected;

  /// No description provided for @failedToRejectCase.
  ///
  /// In en, this message translates to:
  /// **'Failed to reject case'**
  String get failedToRejectCase;

  /// No description provided for @rejectEmergencyCase.
  ///
  /// In en, this message translates to:
  /// **'Reject Emergency Case'**
  String get rejectEmergencyCase;

  /// No description provided for @addFirstItem.
  ///
  /// In en, this message translates to:
  /// **'Add First Item'**
  String get addFirstItem;

  /// No description provided for @noCategoriesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No categories available'**
  String get noCategoriesAvailable;

  /// No description provided for @deleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete Item'**
  String get deleteItem;

  /// No description provided for @areYouSureYouWantToDeleteItem.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {itemName}?'**
  String areYouSureYouWantToDeleteItem(Object itemName);

  /// No description provided for @itemDeleted.
  ///
  /// In en, this message translates to:
  /// **'{itemName} deleted'**
  String itemDeleted(Object itemName);

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Update Stock'**
  String get stock;

  /// No description provided for @stockUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Stock updated successfully'**
  String get stockUpdatedSuccessfully;

  /// No description provided for @medicalRecordDetails.
  ///
  /// In en, this message translates to:
  /// **'Medical Record Details'**
  String get medicalRecordDetails;

  /// No description provided for @previewFunctionalityFor.
  ///
  /// In en, this message translates to:
  /// **'Preview functionality for {fileName}'**
  String previewFunctionalityFor(Object fileName);

  /// No description provided for @addFiles.
  ///
  /// In en, this message translates to:
  /// **'Add Files'**
  String get addFiles;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @deleteDocument.
  ///
  /// In en, this message translates to:
  /// **'Delete Document'**
  String get deleteDocument;

  /// No description provided for @areYouSureYouWantToDeleteDocument.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this document?'**
  String get areYouSureYouWantToDeleteDocument;

  /// No description provided for @documentDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Document deleted successfully'**
  String get documentDeletedSuccessfully;

  /// No description provided for @failedToDeleteDocument.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete document'**
  String get failedToDeleteDocument;

  /// No description provided for @errorDeletingDocument.
  ///
  /// In en, this message translates to:
  /// **'Error deleting document: {error}'**
  String errorDeletingDocument(Object error);

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for Now'**
  String get skipForNow;

  /// No description provided for @scheduleUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Schedule updated successfully'**
  String get scheduleUpdatedSuccessfully;

  /// No description provided for @failedToUpdateSchedule.
  ///
  /// In en, this message translates to:
  /// **'Failed to update schedule'**
  String get failedToUpdateSchedule;

  /// No description provided for @treatmentRecording.
  ///
  /// In en, this message translates to:
  /// **'Treatment Recording'**
  String get treatmentRecording;

  /// No description provided for @petSelectionWillBeImplemented.
  ///
  /// In en, this message translates to:
  /// **'Pet selection will be implemented'**
  String get petSelectionWillBeImplemented;

  /// No description provided for @emergencyCase.
  ///
  /// In en, this message translates to:
  /// **'Emergency Case'**
  String get emergencyCase;

  /// No description provided for @saveTreatmentRecord.
  ///
  /// In en, this message translates to:
  /// **'Save Treatment Record'**
  String get saveTreatmentRecord;

  /// No description provided for @noTreatmentRecordsYet.
  ///
  /// In en, this message translates to:
  /// **'No treatment records yet'**
  String get noTreatmentRecordsYet;

  /// No description provided for @pleaseSelectAPatient.
  ///
  /// In en, this message translates to:
  /// **'Please select a patient'**
  String get pleaseSelectAPatient;

  /// No description provided for @treatmentRecordSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Treatment record saved successfully'**
  String get treatmentRecordSavedSuccessfully;

  /// No description provided for @failedToSaveTreatmentRecord.
  ///
  /// In en, this message translates to:
  /// **'Failed to save treatment record'**
  String get failedToSaveTreatmentRecord;

  /// No description provided for @treatmentHistory.
  ///
  /// In en, this message translates to:
  /// **'Treatment History'**
  String get treatmentHistory;

  /// No description provided for @noTreatmentRecordsFound.
  ///
  /// In en, this message translates to:
  /// **'No treatment records found'**
  String get noTreatmentRecordsFound;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @downloadPDF.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPDF;

  /// No description provided for @downloadFile.
  ///
  /// In en, this message translates to:
  /// **'Download File'**
  String get downloadFile;

  /// No description provided for @shareFunctionalityComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Share functionality coming soon'**
  String get shareFunctionalityComingSoon;

  /// No description provided for @documentInformation.
  ///
  /// In en, this message translates to:
  /// **'Document Information'**
  String get documentInformation;

  /// No description provided for @doctorDashboardTranslationTest.
  ///
  /// In en, this message translates to:
  /// **'Doctor Dashboard Translation Test'**
  String get doctorDashboardTranslationTest;

  /// No description provided for @allCategoriesAccessible.
  ///
  /// In en, this message translates to:
  /// **'All categories accessible'**
  String get allCategoriesAccessible;

  /// No description provided for @switchLanguage.
  ///
  /// In en, this message translates to:
  /// **'Switch Language'**
  String get switchLanguage;

  /// No description provided for @searchDoctors.
  ///
  /// In en, this message translates to:
  /// **'Search doctors...'**
  String get searchDoctors;

  /// No description provided for @specialty.
  ///
  /// In en, this message translates to:
  /// **'Specialty'**
  String get specialty;

  /// No description provided for @yourLocation.
  ///
  /// In en, this message translates to:
  /// **'Your Location'**
  String get yourLocation;

  /// No description provided for @liveMap.
  ///
  /// In en, this message translates to:
  /// **'Live Map'**
  String get liveMap;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @nextStop.
  ///
  /// In en, this message translates to:
  /// **'Next Stop'**
  String get nextStop;

  /// No description provided for @otherStops.
  ///
  /// In en, this message translates to:
  /// **'Other Stops'**
  String get otherStops;

  /// No description provided for @driverStatus.
  ///
  /// In en, this message translates to:
  /// **'Driver Status'**
  String get driverStatus;

  /// No description provided for @statusUpdatesAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Status updates automatically'**
  String get statusUpdatesAutomatically;

  /// No description provided for @nextAppointment.
  ///
  /// In en, this message translates to:
  /// **'Next Appointment'**
  String get nextAppointment;

  /// No description provided for @scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduled;

  /// No description provided for @distanceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Distance unavailable'**
  String get distanceUnavailable;

  /// No description provided for @noAppointmentsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Appointments Available'**
  String get noAppointmentsAvailable;

  /// No description provided for @linkWithADoctor.
  ///
  /// In en, this message translates to:
  /// **'Link with a Doctor'**
  String get linkWithADoctor;

  /// No description provided for @allAppointments.
  ///
  /// In en, this message translates to:
  /// **'All Appointments'**
  String get allAppointments;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @gettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting location...'**
  String get gettingLocation;

  /// No description provided for @addressNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Address not available'**
  String get addressNotAvailable;

  /// No description provided for @vet2UDriver.
  ///
  /// In en, this message translates to:
  /// **'Vet2U Driver'**
  String get vet2UDriver;

  /// No description provided for @deleteMedicalRecord.
  ///
  /// In en, this message translates to:
  /// **'Delete Medical Record'**
  String get deleteMedicalRecord;

  /// No description provided for @phoneRequiredForDoctors.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required for doctors'**
  String get phoneRequiredForDoctors;

  /// No description provided for @enterValidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get enterValidPhoneNumber;

  /// No description provided for @specializationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Veterinary Medicine, Surgery, etc.'**
  String get specializationHint;

  /// No description provided for @licenseNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Professional license number'**
  String get licenseNumberHint;

  /// No description provided for @yearsHint.
  ///
  /// In en, this message translates to:
  /// **'Number of years'**
  String get yearsHint;

  /// No description provided for @enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get enterValidNumber;

  /// No description provided for @enterRealisticYears.
  ///
  /// In en, this message translates to:
  /// **'Please enter a realistic number of years'**
  String get enterRealisticYears;

  /// No description provided for @bioHint.
  ///
  /// In en, this message translates to:
  /// **'Brief description of your experience and services'**
  String get bioHint;

  /// No description provided for @currentPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Current password is required'**
  String get currentPasswordRequired;

  /// No description provided for @newPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'New password is required'**
  String get newPasswordRequired;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your new password'**
  String get confirmPasswordRequired;

  /// No description provided for @editMedicalRecord.
  ///
  /// In en, this message translates to:
  /// **'Edit Medical Record'**
  String get editMedicalRecord;

  /// No description provided for @petLabel.
  ///
  /// In en, this message translates to:
  /// **'Pet'**
  String get petLabel;

  /// No description provided for @visitDate.
  ///
  /// In en, this message translates to:
  /// **'Visit Date'**
  String get visitDate;

  /// No description provided for @diagnosisHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the diagnosis...'**
  String get diagnosisHint;

  /// No description provided for @diagnosisRequired.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis *'**
  String get diagnosisRequired;

  /// No description provided for @diagnosisDetailed.
  ///
  /// In en, this message translates to:
  /// **'Please provide a detailed diagnosis'**
  String get diagnosisDetailed;

  /// No description provided for @treatmentHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the treatment provided...'**
  String get treatmentHint;

  /// No description provided for @treatmentRequired.
  ///
  /// In en, this message translates to:
  /// **'Treatment is required'**
  String get treatmentRequired;

  /// No description provided for @treatmentDetailed.
  ///
  /// In en, this message translates to:
  /// **'Please provide detailed treatment information'**
  String get treatmentDetailed;

  /// No description provided for @prescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Prescription (Optional)'**
  String get prescriptionOptional;

  /// No description provided for @prescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'List prescribed medications and dosages...'**
  String get prescriptionHint;

  /// No description provided for @additionalNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Additional Notes (Optional)'**
  String get additionalNotesOptional;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Any additional observations or follow-up instructions...'**
  String get notesHint;

  /// No description provided for @medicalRecordAdded.
  ///
  /// In en, this message translates to:
  /// **'Medical record added successfully'**
  String get medicalRecordAdded;

  /// No description provided for @medicalRecordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Medical record updated successfully'**
  String get medicalRecordUpdated;

  /// No description provided for @addSupportingDocuments.
  ///
  /// In en, this message translates to:
  /// **'Add Supporting Documents'**
  String get addSupportingDocuments;

  /// No description provided for @uploadDocumentsDescription.
  ///
  /// In en, this message translates to:
  /// **'Upload medical documents, lab results, or images related to this record'**
  String get uploadDocumentsDescription;

  /// No description provided for @updateRecord.
  ///
  /// In en, this message translates to:
  /// **'Update Record'**
  String get updateRecord;

  /// No description provided for @saveRecord.
  ///
  /// In en, this message translates to:
  /// **'Save Record'**
  String get saveRecord;

  /// No description provided for @sortedByDateTime.
  ///
  /// In en, this message translates to:
  /// **'Sorted by date & time'**
  String get sortedByDateTime;

  /// No description provided for @appointmentsAutoSorted.
  ///
  /// In en, this message translates to:
  /// **'Appointments are automatically sorted by date and time'**
  String get appointmentsAutoSorted;

  /// No description provided for @locationUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update location'**
  String get locationUpdateFailed;

  /// No description provided for @appointmentServiceType.
  ///
  /// In en, this message translates to:
  /// **'Appointment'**
  String get appointmentServiceType;

  /// No description provided for @treatmentProvidedRequired.
  ///
  /// In en, this message translates to:
  /// **'Treatment Provided *'**
  String get treatmentProvidedRequired;

  /// No description provided for @prescriptionOptionalShort.
  ///
  /// In en, this message translates to:
  /// **'Prescription (Optional)'**
  String get prescriptionOptionalShort;

  /// No description provided for @paymentProcessingFailedGeneral.
  ///
  /// In en, this message translates to:
  /// **'Failed to process payment'**
  String get paymentProcessingFailedGeneral;

  /// No description provided for @scheduledAt.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduledAt;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @uploadFiles.
  ///
  /// In en, this message translates to:
  /// **'Upload Files'**
  String get uploadFiles;

  /// No description provided for @rescheduleComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Reschedule feature coming soon'**
  String get rescheduleComingSoon;

  /// No description provided for @locationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Location updated successfully'**
  String get locationUpdated;

  /// No description provided for @appointmentCompletedRecordSaved.
  ///
  /// In en, this message translates to:
  /// **'Appointment completed and treatment record saved'**
  String get appointmentCompletedRecordSaved;

  /// No description provided for @appointmentCompletedRecordFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save treatment record'**
  String get appointmentCompletedRecordFailed;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
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
