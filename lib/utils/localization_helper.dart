// lib/utils/localization_helper.dart
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// A helper class that bridges Flutter's AppLocalizations with GetX-style translations
/// and provides additional localization utilities
class LocalizationHelper {
  static AppLocalizations? _localizations;

  /// Initialize the helper with the current localizations
  static void init(BuildContext context) {
    _localizations = AppLocalizations.of(context);
  }

  /// Get translated string by key, with optional arguments for placeholders
  static String tr(String key, {Map<String, String>? args}) {
    if (_localizations == null) {
      return key; // Fallback to key if not initialized
    }

    String translated = _getTranslatedString(key);

    // Replace placeholders with args
    if (args != null) {
      args.forEach((placeholder, value) {
        translated = translated.replaceAll('{$placeholder}', value);
      });
    }

    return translated;
  }

  /// Get translated string by key with required arguments
  static String trWithParams(String key, Map<String, String> args) {
    return tr(key, args: args);
  }

  /// Get translated string from AppLocalizations using reflection-like mapping
  static String _getTranslatedString(String key) {
    if (_localizations == null) return key;

    // Map keys to AppLocalizations getters
    switch (key) {
      // Authentication & User
      case 'createAccount':
        return _localizations!.createAccount;
      case 'letsSetUpYourAccount':
        return _localizations!.letsSetUpYourAccount;
      case 'fullName':
        return _localizations!.fullName;
      case 'enterYourFullName':
        return _localizations!.enterYourFullName;
      case 'emailAddress':
        return _localizations!.emailAddress;
      case 'enterYourEmail':
        return _localizations!.enterYourEmail;
      case 'password':
        return _localizations!.password;
      case 'min6Characters':
        return _localizations!.min6Characters;
      case 'phoneNumber':
        return _localizations!.phoneNumber;
      case 'optional':
        return _localizations!.optional;
      case 'role':
        return _localizations!.role;
      case 'selectYourRole':
        return _localizations!.selectYourRole;
      case 'petOwner':
        return _localizations!.petOwner;
      case 'veterinarian':
        return _localizations!.veterinarian;
      case 'driver':
        return _localizations!.driver;
      case 'administrator':
        return _localizations!.administrator;
      case 'serviceAreaRequired':
        return _localizations!.serviceAreaRequired;
      case 'selectYourServiceArea':
        return _localizations!.selectYourServiceArea;
      case 'pleaseSelectServiceArea':
        return _localizations!.pleaseSelectServiceArea;
      case 'orContinueWith':
        return _localizations!.orContinueWith;
      case 'google':
        return _localizations!.google;
      case 'facebook':
        return _localizations!.facebook;
      case 'alreadyHaveAccount':
        return _localizations!.alreadyHaveAccount;
      case 'signIn':
        return _localizations!.signIn;
      case 'pleaseEnterYourFullName':
        return _localizations!.pleaseEnterYourFullName;
      case 'pleaseEnterYourEmail':
        return _localizations!.pleaseEnterYourEmail;
      case 'pleaseEnterValidEmailAddress':
        return _localizations!.pleaseEnterValidEmailAddress;
      case 'passwordMustBeAtLeast6Characters':
        return _localizations!.passwordMustBeAtLeast6Characters;
      case 'pleaseSelectServiceAreaForYourRole':
        return _localizations!.pleaseSelectServiceAreaForYourRole;

      // App Common
      case 'appTitle':
        return _localizations!.appTitle;
      case 'welcomeMessage':
        return _localizations!.welcomeMessage;
      case 'welcomeBack':
        return _localizations!.welcomeBack;
      case 'yourPetsSafeHands':
        return _localizations!.yourPetsSafeHands;
      case 'selectLanguage':
        return _localizations!.selectLanguage;
      case 'languageToggle':
        return _localizations!.languageToggle;
      case 'english':
        return _localizations!.english;
      case 'arabic':
        return _localizations!.arabic;
      case 'cancel':
        return _localizations!.cancel;
      case 'saveChanges':
        return _localizations!.saveChanges;
      case 'changePhoto':
        return _localizations!.changePhoto;

      // Clinic Terms
      case 'doctor':
        return _localizations!.doctor;
      case 'pet':
        return _localizations!.pet;
      case 'medicalRecord':
        return _localizations!.medicalRecord;

      // Document Upload
      case 'uploadDocument':
        return _localizations!.uploadDocument;
      case 'selectPet':
        return _localizations!.selectPet;
      case 'choosePet':
        return _localizations!.choosePet;
      case 'selectFile':
        return _localizations!.selectFile;
      case 'tapToSelectFile':
        return _localizations!.tapToSelectFile;
      case 'supportedFormats':
        return _localizations!.supportedFormats;
      case 'description':
        return _localizations!.description;
      case 'accessLevel':
        return _localizations!.accessLevel;
      case 'private':
        return _localizations!.private;
      case 'public':
        return _localizations!.public;
      case 'restricted':
        return _localizations!.restricted;
      case 'upload':
        return _localizations!.upload;
      case 'uploading':
        return _localizations!.uploading;
      case 'documentUploadedSuccessfully':
        return _localizations!.documentUploadedSuccessfully;
      case 'failedToUploadDocument':
        return _localizations!.failedToUploadDocument;
      case 'linkToMedicalRecord':
        return _localizations!.linkToMedicalRecord;
      case 'associateWithRecord':
        return _localizations!.associateWithRecord;
      case 'noSpecificRecord':
        return _localizations!.noSpecificRecord;
      case 'accessLevelDescription':
        return _localizations!.accessLevelDescription;
      case 'pleaseSelectPet':
        return _localizations!.pleaseSelectPet;
      case 'pleaseSelectFile':
        return _localizations!.pleaseSelectFile;
      case 'errorPickingFile':
        return _localizations!.errorPickingFile;
      case 'errorUploadingDocument':
        return _localizations!.errorUploadingDocument;

      // Profile
      case 'profile':
        return _localizations!.profile;
      case 'personalInformation':
        return _localizations!.personalInformation;
      case 'professionalInformation':
        return _localizations!.professionalInformation;
      case 'updateDetails':
        return _localizations!.updateDetails;
      case 'contactNumber':
        return _localizations!.contactNumber;
      case 'accountSettings':
        return _localizations!.accountSettings;
      case 'changePassword':
        return _localizations!.changePassword;
      case 'currentPassword':
        return _localizations!.currentPassword;
      case 'newPassword':
        return _localizations!.newPassword;
      case 'confirmPassword':
        return _localizations!.confirmPassword;
      case 'specialization':
        return _localizations!.specialization;
      case 'licenseNumber':
        return _localizations!.licenseNumber;
      case 'yearsOfExperience':
        return _localizations!.yearsOfExperience;
      case 'serviceArea':
        return _localizations!.serviceArea;
      case 'professionalBio':
        return _localizations!.professionalBio;
      case 'enablePasswordChange':
        return _localizations!.enablePasswordChange;
      case 'profileInfoHelp':
        return _localizations!.profileInfoHelp;
      case 'doctorProfile':
        return _localizations!.doctorProfile;
      case 'editDoctorProfile':
        return _localizations!.editDoctorProfile;
      case 'profileUpdatedSuccessfully':
        return _localizations!.profileUpdatedSuccessfully;

      // Validation Messages
      case 'nameRequired':
        return _localizations!.nameRequired;
      case 'emailRequired':
        return _localizations!.emailRequired;
      case 'phoneRequired':
        return _localizations!.phoneRequired;
      case 'specializationRequired':
        return _localizations!.specializationRequired;
      case 'licenseRequired':
        return _localizations!.licenseRequired;
      case 'experienceRequired':
        return _localizations!.experienceRequired;
      case 'areaRequired':
        return _localizations!.areaRequired;
      case 'bioRequired':
        return _localizations!.bioRequired;
      case 'passwordRequired':
        return _localizations!.passwordRequired;
      case 'passwordMinLength':
        return _localizations!.passwordMinLength;
      case 'passwordsDoNotMatch':
        return _localizations!.passwordsDoNotMatch;
      case 'invalidPhoneNumber':
        return _localizations!.invalidPhoneNumber;
      case 'invalidExperience':
        return _localizations!.invalidExperience;
      case 'experienceTooHigh':
        return _localizations!.experienceTooHigh;
      case 'nameMinLength':
        return _localizations!.nameMinLength;
      case 'bioMinLength':
        return _localizations!.bioMinLength;

      // Fallback - return key if not found
      default:
        debugPrint('Localization key not found: $key');
        return key;
    }
  }

  /// Check if current locale is RTL
  static bool isRTL(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return ['ar', 'he', 'fa', 'ur'].contains(locale.languageCode);
  }

  /// Get text direction based on current locale
  static TextDirection getTextDirection(BuildContext context) {
    return isRTL(context) ? TextDirection.rtl : TextDirection.ltr;
  }

  /// Get current locale
  static Locale getCurrentLocale(BuildContext context) {
    return Localizations.localeOf(context);
  }

  /// Format date according to locale
  static String formatDate(BuildContext context, DateTime date) {
    // This would use intl's DateFormat with locale
    // For now, return a simple formatted string
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Format number according to locale
  static String formatNumber(BuildContext context, num number) {
    // This would use intl's NumberFormat with locale
    // For now, return string representation
    return number.toString();
  }
}
