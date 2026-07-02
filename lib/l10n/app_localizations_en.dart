import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTagline => 'Your location, only with the people who really matter.';

  @override
  String get authModeSignUp => 'Create account';

  @override
  String get authModeSignIn => 'Sign in';

  @override
  String get authNameHint => 'Your name';

  @override
  String get authEmailHint => 'Your email';

  @override
  String get authPasswordHint => 'Password';

  @override
  String get authInvalidEmail => 'Enter a valid email address.';

  @override
  String get authPasswordTooShort => 'Password must be at least 6 characters.';

  @override
  String get authAccountCreated => 'Account created: check your email to confirm it before signing in.';

  @override
  String authGenericError(String error) {
    return 'Something went wrong. Please try again.\n$error';
  }

  @override
  String get authPrivacyHint => 'No one sees your location without your permission.';

  @override
  String get authBackToWebsite => 'Back to the Kinly website';

  @override
  String get welcomeCreateCircle => 'Create your circle';

  @override
  String get welcomeJoinCircle => 'I have an invite code';

  @override
  String get welcomeInviteOnlyHint => 'Invite-only access. No one sees your location without your permission.';

  @override
  String get navMap => 'Map';

  @override
  String get navCircles => 'Circles';

  @override
  String get navRequests => 'Requests';

  @override
  String get navProfile => 'Profile';

  @override
  String get languageSectionTitle => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languageEnglish => 'English';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonNo => 'No';

  @override
  String get commonSomeone => 'Someone';

  @override
  String get mapNeedCircleFirst => 'Create or join a circle first.';

  @override
  String get mapWhichCircleTitle => 'Which circle?';

  @override
  String mapMeetingPointAdded(String name) {
    return '\"$name\" added as a meeting point.';
  }

  @override
  String get mapSearchHint => 'Search an address or a store…';

  @override
  String get mapMakeMeetingPoint => 'Make meeting point';

  @override
  String get mapLocationUnavailable => 'We couldn\'t detect your location.';

  @override
  String get mapSosConfirmTitle => 'Activate SOS?';

  @override
  String get mapSosConfirmBody => 'Your exact location will be shared immediately with all your circles, even if you have a reduced sharing mode. No audio recording: location only.';

  @override
  String get mapActivateSos => 'Activate SOS';

  @override
  String get mapLocationUnavailableForSos => 'We couldn\'t detect your location for the SOS.';

  @override
  String get mapSosNotSentOffline => 'SOS not sent (are you offline?). Set an SOS SMS number in Privacy and safety to have a backup plan.';

  @override
  String get mapNoInternetSosSmsTitle => 'No internet: SOS via SMS?';

  @override
  String mapNoInternetSosSmsBody(String number) {
    return 'We couldn\'t send the SOS online. Do you want to send an SMS with your location to $number?';
  }

  @override
  String get mapPrepareSms => 'Prepare SMS';

  @override
  String get mapWalkMeHomeActiveTitle => 'Walk me home active';

  @override
  String mapWalkMeHomeActiveBody(int minutes) {
    return 'If you don\'t confirm within ~$minutes min, your circle receives an alert with your location.';
  }

  @override
  String get mapArrived => 'I\'ve arrived';

  @override
  String get mapWalkMeHomeTitle => 'Walk me home';

  @override
  String get mapWalkMeHomeDescription => 'Choose how long you expect to take: if you don\'t confirm within that time (or don\'t enter a Home area), your circle automatically receives an alert with your location.';

  @override
  String mapWalkMeHomeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get mapWalkMeHomeNote => 'Note: if the phone fully closes the app before the deadline, the automatic alert might not fire.';

  @override
  String get mapCrashDetectedTitle => 'Possible crash detected';

  @override
  String mapCrashDetectedBody(int secondsLeft) {
    return 'Automatic SOS in $secondsLeft seconds. Are you OK? Cancel if this is a false alarm.';
  }

  @override
  String get mapImFine => 'I\'m fine, cancel';

  @override
  String get mapShareLocationLinkTitle => 'Share your location with a link';

  @override
  String get mapShareLocationLinkBody => 'Whoever receives the link sees your live location from the browser, even without the app. The link expires on its own.';

  @override
  String get mapDuration1h => '1 hour';

  @override
  String get mapDuration3h => '3 hours';

  @override
  String get mapDuration24h => '24 hours';

  @override
  String mapShareLiveMessage(String label, String url) {
    return 'Follow my live location on Kinly (valid $label): $url';
  }

  @override
  String get mapLinkCreateError => 'We couldn\'t create the link. Please try again.';

  @override
  String get mapWhichCircleForMeetingPoint => 'For which circle?';

  @override
  String get mapManageSafeZones => 'Manage safe zones';

  @override
  String get mapYourCircle => 'Your circle';

  @override
  String mapPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '$count person',
    );
    return '$_temp0';
  }

  @override
  String get mapNewMeetingPointTooltip => 'New meeting point';

  @override
  String get mapShareLocationLinkTooltip => 'Share location with a link';

  @override
  String get mapEmptyCircleTitle => 'No one to see here yet';

  @override
  String get mapEmptyCircleMessage => 'Invite someone to the circle to see them on the map.';

  @override
  String get mapAllCirclesChip => 'All';

  @override
  String get mapWebNotice => 'You\'re using the web companion of Kinly: here your location only updates while this tab is open. For continuous tracking, push notifications and biometric lock, you need the app.';

  @override
  String get mapSosActiveLabel => 'SOS active';

  @override
  String get mapActivateSosSemantic => 'Activate SOS';

  @override
  String get mapHelpRequestedLabel => 'Help requested';

  @override
  String get mapAskForHelp => 'Ask for help';

  @override
  String get mapWalkMeHomeActiveLabel => 'Walk me home active';

  @override
  String get mapWalkMeHomeSemantic => 'Walk me home';

  @override
  String mapSosBannerText(String personName) {
    return '$personName activated SOS · tap to see where they are';
  }

  @override
  String mapHelpBannerText(String personName, String reason) {
    return '$personName needs help ($reason) · tap for details';
  }

  @override
  String mapWalkMeHomeBannerText(int minutes) {
    return 'Walk me home active · confirm within ~$minutes min';
  }

  @override
  String get mapHighFive => 'High five';

  @override
  String mapEncounterText(String personName) {
    return 'You crossed paths with $personName!';
  }

  @override
  String mapShoppingAtStore(String personName, String place) {
    return '$personName is at the store$place';
  }

  @override
  String get mapAskSomething => 'Ask for something';

  @override
  String get mapShoppingHint => 'E.g. Milk!';

  @override
  String get mapTheyAskedFor => 'They asked you for:';

  @override
  String mapShoppingRequestLine(String name, String note) {
    return '$name: $note';
  }

  @override
  String get mapHelpRequestDescription => 'Notify your circle with a reason and your current location. Unlike SOS, this doesn\'t change your sharing mode.';

  @override
  String get mapCircleLabel => 'Circle';

  @override
  String get mapReasonLabel => 'Reason';

  @override
  String get mapNoteHint => 'Add a detail (optional)';

  @override
  String get mapSendRequest => 'Send request';

  @override
  String get mapNeedCircleForHelp => 'Create or join a circle before asking for help.';

  @override
  String get mapHelpRequestSendError => 'We couldn\'t send the request. Please try again.';

  @override
  String mapSafeZoneLabelAndRadius(String kindLabel, int radius) {
    return '$kindLabel · radius $radius m';
  }
}
