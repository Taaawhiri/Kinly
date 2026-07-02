// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTagline =>
      'Your location, only with the people who really matter.';

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
  String get authAccountCreated =>
      'Account created: check your email to confirm it before signing in.';

  @override
  String authGenericError(String error) {
    return 'Something went wrong. Please try again.\n$error';
  }

  @override
  String get authPrivacyHint =>
      'No one sees your location without your permission.';

  @override
  String get authBackToWebsite => 'Back to the Kinly website';

  @override
  String get welcomeCreateCircle => 'Create your circle';

  @override
  String get welcomeJoinCircle => 'I have an invite code';

  @override
  String get welcomeInviteOnlyHint =>
      'Invite-only access. No one sees your location without your permission.';

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
  String get commonSave => 'Save';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonNotNow => 'Not now';

  @override
  String get commonActivate => 'Activate';

  @override
  String get commonDone => 'Done';

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
  String get mapSosConfirmBody =>
      'Your exact location will be shared immediately with all your circles, even if you have a reduced sharing mode. No audio recording: location only.';

  @override
  String get mapActivateSos => 'Activate SOS';

  @override
  String get mapLocationUnavailableForSos =>
      'We couldn\'t detect your location for the SOS.';

  @override
  String get mapSosNotSentOffline =>
      'SOS not sent (are you offline?). Set an SOS SMS number in Privacy and safety to have a backup plan.';

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
  String get mapWalkMeHomeDescription =>
      'Choose how long you expect to take: if you don\'t confirm within that time (or don\'t enter a Home area), your circle automatically receives an alert with your location.';

  @override
  String mapWalkMeHomeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get mapWalkMeHomeNote =>
      'Note: if the phone fully closes the app before the deadline, the automatic alert might not fire.';

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
  String get mapShareLocationLinkBody =>
      'Whoever receives the link sees your live location from the browser, even without the app. The link expires on its own.';

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
  String get mapLinkCreateError =>
      'We couldn\'t create the link. Please try again.';

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
  String get mapEmptyCircleMessage =>
      'Invite someone to the circle to see them on the map.';

  @override
  String get mapAllCirclesChip => 'All';

  @override
  String get mapWebNotice =>
      'You\'re using the web companion of Kinly: here your location only updates while this tab is open. For continuous tracking, push notifications and biometric lock, you need the app.';

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
  String get mapHelpRequestDescription =>
      'Notify your circle with a reason and your current location. Unlike SOS, this doesn\'t change your sharing mode.';

  @override
  String get mapCircleLabel => 'Circle';

  @override
  String get mapReasonLabel => 'Reason';

  @override
  String get mapNoteHint => 'Add a detail (optional)';

  @override
  String get mapSendRequest => 'Send request';

  @override
  String get mapNeedCircleForHelp =>
      'Create or join a circle before asking for help.';

  @override
  String get mapHelpRequestSendError =>
      'We couldn\'t send the request. Please try again.';

  @override
  String mapSafeZoneLabelAndRadius(String kindLabel, int radius) {
    return '$kindLabel · radius $radius m';
  }

  @override
  String get circlesTitle => 'Your circles';

  @override
  String get circlesAddTitle => 'Add a circle';

  @override
  String get circlesCreateNew => 'Create a new circle';

  @override
  String get circlesHaveInviteCode => 'I have an invite code';

  @override
  String circlesJoinedSnackbar(String name) {
    return 'You joined \"$name\"';
  }

  @override
  String circlesYourModeInTitle(String name) {
    return 'Your mode in \"$name\"';
  }

  @override
  String get circlesModeOverrideHint =>
      'Only applies to this circle: other circles keep your general profile setting.';

  @override
  String get circlesUseGeneralMode => 'Use the general mode';

  @override
  String circlesGeneralModeDescription(String modeLabel) {
    return 'The one chosen in your profile ($modeLabel).';
  }

  @override
  String circlesAnomalyStillAt(String name, String zoneName) {
    return '$name is still $zoneName';
  }

  @override
  String circlesAnomalyLate(String expected, int minutes) {
    return 'Usually leaves by $expected · $minutes min late';
  }

  @override
  String get circlesInviteCodeCopied => 'Invite code copied';

  @override
  String get circlesActionInvite => 'Invite';

  @override
  String circlesInviteShareMessage(String circleName, String inviteCode) {
    return 'Join my circle \"$circleName\" on Kinly!\n\nInvite code: $inviteCode\n\nOpen Kinly and tap \"I have an invite code\", or tap: kinly://join/$inviteCode';
  }

  @override
  String get circlesActionSafeZones => 'Safe zones';

  @override
  String get circlesActionMeetingPoint => 'Meeting point';

  @override
  String get circlesActionMessages => 'Messages';

  @override
  String get circlesActionExpenses => 'Expenses';

  @override
  String get circlesActionSummary => 'Summary';

  @override
  String get circlesActionYourMode => 'Your mode';

  @override
  String get circlesCoachStep1Title => 'Your circle';

  @override
  String get circlesCoachStep1Body =>
      'Each circle has its own members, icon and settings: you can have more than one.';

  @override
  String get circlesCoachStep2Title => 'Circle actions';

  @override
  String get circlesCoachStep2Body =>
      'From here you manage safe zones, meeting point, messages, group expenses and the weekly summary.';

  @override
  String get circlesCoachStep3Title => 'Invite code';

  @override
  String get circlesCoachStep3Body =>
      'Tap to copy it: only whoever gets it from you can join this circle.';

  @override
  String get circlesCoachSkip => 'Skip';

  @override
  String get circlesCoachNext => 'Next';

  @override
  String get circlesCoachFinish => 'Done';

  @override
  String get meetingPointTitle => 'Meeting point';

  @override
  String get meetingPointDeleteTooltip => 'Delete meeting point';

  @override
  String get meetingPointCreateButton => 'Create point';

  @override
  String get meetingPointEmptyTitle => 'No meeting point';

  @override
  String get meetingPointEmptyMessage =>
      'Suggest a place to meet: everyone will see their own real-time distance, without texting \"where are you?\".';

  @override
  String get meetingPointMarkArrived => 'Mark my arrival';

  @override
  String get meetingPointWhoArriving => 'Who\'s arriving';

  @override
  String meetingPointScheduledAt(String time, String date) {
    return 'At $time · $date';
  }

  @override
  String get meetingPointArrived => 'Arrived';

  @override
  String get meetingPointPositionUnavailable => 'Location unavailable';

  @override
  String meetingPointEtaMinutes(int minutes) {
    return '~$minutes min by car';
  }

  @override
  String get meetingPointNewTitle => 'New meeting point';

  @override
  String get meetingPointSearchHint => 'Search a place or an address…';

  @override
  String get meetingPointOr => 'or';

  @override
  String get meetingPointUseMyLocation => 'Use my current location';

  @override
  String get meetingPointPositionSet => 'Location set';

  @override
  String get meetingPointNameHint => 'Name (e.g. Stadium entrance, Bar Roma)';

  @override
  String get meetingPointSetTime => 'Set a time (optional)';

  @override
  String meetingPointNoResultsFor(String query) {
    return 'No results for \"$query\".';
  }

  @override
  String get meetingPointSearchFailed => 'Search failed. Please try again.';

  @override
  String get meetingPointLocationUnavailable =>
      'We couldn\'t detect your location.';

  @override
  String get meetingPointChooseNameAndLocation =>
      'Choose a name and a location.';

  @override
  String get meetingPointCreateError =>
      'We couldn\'t create the meeting point. Please try again.';

  @override
  String circleMessagesTitle(String circleName) {
    return 'Messages · $circleName';
  }

  @override
  String get circleMessagesSendError =>
      'We couldn\'t send the message. Please try again.';

  @override
  String get circleMessagesDailyLimitTitle => 'Daily limit reached';

  @override
  String get circleMessagesDailyLimitBody =>
      'You\'ve already sent 5 messages today: that\'s the free plan limit. With Kinly+ you can send as many as you want.';

  @override
  String get circleMessagesGotIt => 'Got it';

  @override
  String get circleMessagesDiscoverPlus => 'Discover Kinly+';

  @override
  String get circleMessagesHintPremium =>
      'Only for short, important notices. For chatting, use WhatsApp or another messaging app.';

  @override
  String get circleMessagesHintFree =>
      'Only for short, important notices (max 5 per day on the free plan). For chatting, use WhatsApp or another messaging app.';

  @override
  String get circleMessagesEmptyTitle => 'No messages yet';

  @override
  String get circleMessagesEmptyMessage => 'Send the first notice below.';

  @override
  String get circleMessagesTimeNow => 'now';

  @override
  String circleMessagesTimeMinutesAgo(int minutes) {
    return '$minutes min ago';
  }

  @override
  String circleMessagesTimeHoursAgo(int hours) {
    return '$hours h ago';
  }

  @override
  String get circleMessagesComposerHint => 'Write a short notice...';

  @override
  String get quickMessage1 => 'On my way 🚗';

  @override
  String get quickMessage2 => 'Running late ⏰';

  @override
  String get quickMessage3 => 'I\'ve arrived 🏠';

  @override
  String get quickMessage4 => 'Everything OK? 👋';

  @override
  String get quickMessage5 => 'Call me when you can 📞';

  @override
  String get quickMessage6 => 'Good morning ☀️';

  @override
  String get quickMessage7 => 'Good night 🌙';

  @override
  String get quickMessage8 => 'Thank you! ❤️';

  @override
  String get expensesTitle => 'Group expenses';

  @override
  String get expensesNewButton => 'New expense';

  @override
  String get expensesEmptyTitle => 'No expenses';

  @override
  String get expensesEmptyMessage =>
      'Keep track of who paid what in the circle, without writing it down from memory.';

  @override
  String get expensesBalancesTitle => 'Balances';

  @override
  String get expensesListTitle => 'Expenses';

  @override
  String get expensesSetPaymentLinkHint =>
      'Set your payment link in Privacy and safety to make it easier for people to pay you.';

  @override
  String get expensesLinkCopied => 'Payment link copied: send it to them.';

  @override
  String expensesNoPaymentLink(String name) {
    return '$name hasn\'t set a payment link.';
  }

  @override
  String get expensesThisPerson => 'This person';

  @override
  String expensesOwesYou(String name) {
    return '$name owes you';
  }

  @override
  String expensesYouOwe(String name) {
    return 'You owe $name';
  }

  @override
  String get expensesRequestBalance => 'Request balance';

  @override
  String get expensesPay => 'Pay';

  @override
  String expensesPaidBy(String name) {
    return 'Paid by $name';
  }

  @override
  String get expensesFillFields =>
      'Fill in description, amount and at least one person.';

  @override
  String get expensesSaveError =>
      'We couldn\'t save the expense. Please try again.';

  @override
  String get expensesDailyLimitTitle => 'Daily limit reached';

  @override
  String get expensesDailyLimitBody =>
      'You\'ve already logged 5 expenses today: that\'s the free plan limit. With Kinly+ you can log as many as you want.';

  @override
  String get expensesSplitHint =>
      'You pay: it\'s split among the people you select below.';

  @override
  String get expensesDescriptionHint => 'Description (e.g. Dinner, gas)';

  @override
  String get expensesAmountHint => 'Total amount (€)';

  @override
  String get expensesSplitBetween => 'Split between';

  @override
  String get expensesSaveButton => 'Save expense';

  @override
  String weeklySummaryTitle(String circleName) {
    return 'Summary · $circleName';
  }

  @override
  String get weeklySummaryLoadError => 'We couldn\'t load the summary.';

  @override
  String get weeklySummaryRetry => 'Retry';

  @override
  String get weeklySummaryLast7Days => 'Last 7 days';

  @override
  String weeklySummaryActivityFor(String circleName) {
    return 'Activity for \"$circleName\", visible to all members.';
  }

  @override
  String get weeklySummaryQuietWeek => 'Quiet week: no events to report.';

  @override
  String get weeklySummarySosActivated => 'SOS activated';

  @override
  String get weeklySummaryHelpRequests => 'Help requests';

  @override
  String get weeklySummarySafeZoneEntries => 'Safe zone entries';

  @override
  String get weeklySummarySpeedAlerts => 'Speed alerts';

  @override
  String get weeklySummaryPushHint =>
      'You can also receive this summary via notification once a week: turn it on from Profile → Privacy and safety.';

  @override
  String get requestsIncoming => 'Incoming';

  @override
  String get requestsWaitingReply => 'Awaiting reply';

  @override
  String get requestsHistory => 'History';

  @override
  String requestsWantsToSeeYou(String name) {
    return '$name wants to see where you are';
  }

  @override
  String get requestsReject => 'Decline';

  @override
  String get requestsApprove => 'Approve';

  @override
  String requestsWaitingFor(String name) {
    return 'Waiting for $name';
  }

  @override
  String get requestsNotifyOnReply =>
      'You\'ll get a notification when they reply';

  @override
  String requestsTheyAskedYou(String name) {
    return '$name asked for your location';
  }

  @override
  String requestsYouAsked(String name) {
    return 'You asked $name for their location';
  }

  @override
  String get requestsEmptyTitle => 'No requests';

  @override
  String get requestsEmptyMessage =>
      'When someone wants to see your location, or you want to see theirs, the request will appear here.';

  @override
  String get profileStatusFriends => 'With friends';

  @override
  String get profileStatusHome => 'At home';

  @override
  String get profileStatusFree => 'Free';

  @override
  String get profileStatusBusyDay => 'Busy day';

  @override
  String get profileStatusPickerTitle => 'Your status today';

  @override
  String get profileStatusPickerHint =>
      'Visible to your circle on the map until tonight.';

  @override
  String get profileStatusCustomHint => 'Or write your own (with an emoji 🙂)';

  @override
  String get profileRemoveStatus => 'Remove status';

  @override
  String profileActiveCircles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active circles',
      one: '$count active circle',
    );
    return '$_temp0';
  }

  @override
  String get profileYourStatus => 'Your status';

  @override
  String get profileAppearance => 'Appearance';

  @override
  String get profileThemeLight => 'Light';

  @override
  String get profileThemeDark => 'Dark';

  @override
  String get profileSharingModeHeader => 'Sharing mode';

  @override
  String get profileYourCirclesHeader => 'Your circles';

  @override
  String profileCirclesManage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count circles · manage members and invites',
      one: '$count circle · manage members and invites',
    );
    return '$_temp0';
  }

  @override
  String get profileKinlyPlusHeader => 'Kinly+';

  @override
  String get profileActive => 'Active';

  @override
  String get profileNotActive => 'Not active';

  @override
  String get profileManageSubscription => 'Manage Kinly+ subscription';

  @override
  String get profileOtherHeader => 'Other';

  @override
  String get profilePrivacySecurity => 'Privacy and safety';

  @override
  String get profileHelpSupport => 'Help and support';

  @override
  String get profileAdminSupport => 'Support · admin';

  @override
  String get profileReviewOnboarding => 'Review onboarding · admin (test)';

  @override
  String get profileLogout => 'Log out';

  @override
  String get profileFeatureLocationHistoryTitle => 'Location history';

  @override
  String get profileFeatureLocationHistoryDesc =>
      'Review where circle members have been over the past days.';

  @override
  String get profileFeatureSafeZonesTitle => 'Safe zones';

  @override
  String get profileFeatureSafeZonesDesc =>
      'Home, work, school: a custom notification on every arrival or departure.';

  @override
  String get profileFeatureDrivingAlertsTitle => 'Driving alerts';

  @override
  String get profileFeatureDrivingAlertsDesc =>
      'Know when a driver exceeds a speed limit you set.';

  @override
  String get profileFeatureBackgroundTrackingTitle => 'Background tracking';

  @override
  String get profileFeatureBackgroundTrackingDesc =>
      'Location keeps updating even with the app closed.';

  @override
  String get profileFeatureUnlimitedTitle =>
      'Unlimited messages, pings and expenses';

  @override
  String get profileFeatureUnlimitedDesc =>
      'Send as many messages, pings and expenses as you want, with no limits.';

  @override
  String get profileFeatureShoppingTitle => 'Bring me something';

  @override
  String get profileFeatureShoppingDesc =>
      'Let the circle know when you\'re at the supermarket or a bar.';

  @override
  String get profileFeaturePrioritySupportTitle => 'Priority support';

  @override
  String get profileFeaturePrioritySupportDesc =>
      'Dedicated support for your circle, 7 days a week.';

  @override
  String get privacyTitle => 'Privacy and safety';

  @override
  String get privacyLocationVisibilityInfo =>
      'Your location is only visible to people in one of your circles, and only according to the sharing mode you choose from your profile (automatic, on request, or paused).';

  @override
  String get privacySosSmsNumberTitle => 'SOS SMS number';

  @override
  String get privacyPhoneExampleHint => 'E.g. +1 555 1234567';

  @override
  String get privacyPlusFeatureTitle => 'Kinly+ feature';

  @override
  String get privacyCrashDetectionPlusBody =>
      'Crash detection (automatic SOS after a violent impact while driving) is a Kinly+ benefit.';

  @override
  String get privacyBackgroundTrackingPlusBody =>
      'Background tracking (location keeps updating even with the app closed) is a Kinly+ benefit.';

  @override
  String get privacyEnableBackgroundTrackingTitle =>
      'Enable background tracking?';

  @override
  String get privacyEnableBackgroundTrackingBody =>
      'Your location will keep updating even when Kinly isn\'t in the foreground. It uses more battery and always shows a persistent notification while active, as required by Android.';

  @override
  String get privacyExtraStepTitle => 'One more step needed';

  @override
  String get privacyExtraStepBody =>
      'Your Android requires manually enabling the \"Allow all the time\" location permission from system settings, then come back here and turn the switch back on.';

  @override
  String get privacyOpenSettings => 'Open settings';

  @override
  String get privacyGrantLocationFirst =>
      'You need to grant Kinly location permission first.';

  @override
  String get privacyBiometricAuthFailed => 'We couldn\'t verify your identity.';

  @override
  String get privacyOtherDevicesSignedOut =>
      'All other devices have been signed out.';

  @override
  String get privacyOperationFailed =>
      'We couldn\'t complete the operation. Please try again.';

  @override
  String get privacyBirthdayTitle => 'Date of birth';

  @override
  String get privacyDateHint => 'DD/MM/YYYY';

  @override
  String get privacyInvalidDate => 'Invalid date';

  @override
  String get privacyPaymentLinkTitle => 'Payment link';

  @override
  String get privacyPaymentLinkHint => 'E.g. Satispay link, PayPal.me/...';

  @override
  String get privacyPhoneNumberTitle => 'Phone number';

  @override
  String get privacyAccountHeader => 'Account';

  @override
  String get privacyPersonalInfoHeader => 'Personal info';

  @override
  String get privacyBiometricHeader => 'Biometric access';

  @override
  String get privacyBackgroundTrackingHeader => 'Background tracking';

  @override
  String get privacyGhostScheduleHeader => 'Availability hours';

  @override
  String get privacySosHeader => 'SOS';

  @override
  String get privacySpeedAlertHeader => 'Speed alert';

  @override
  String get privacyWeeklySummaryHeader => 'Weekly summary';

  @override
  String get privacyGuideHeader => 'Guide';

  @override
  String get privacyChangePassword => 'Change password';

  @override
  String get privacySignOutOtherDevices => 'Sign out other devices';

  @override
  String get privacyPersonalInfoHint =>
      'Optional: only used for a birthday icon among circle members, to open a direct payment from group expenses, and so whoever receives your SOS or help request can call you.';

  @override
  String get privacyAddBirthday => 'Add date of birth';

  @override
  String privacyBirthdaySet(String date) {
    return 'Birthday: $date';
  }

  @override
  String get privacyAddPaymentLink => 'Add payment link';

  @override
  String get privacyPaymentLinkSet => 'Payment link set';

  @override
  String get privacyAddPhoneNumber => 'Add phone number';

  @override
  String privacyPhoneNumberSet(String phone) {
    return 'Number: $phone';
  }

  @override
  String get privacyBiometricHint =>
      'Require fingerprint, face or device code every time you open Kinly.';

  @override
  String get privacyBiometricUnlock => 'Biometric unlock';

  @override
  String get privacyBackgroundTrackingHint =>
      'By default Kinly only updates your location while it\'s open. Turn this on to keep it updating in the background too: it uses more battery and always shows a persistent notification while active.';

  @override
  String get privacyEnableInBackground => 'Enable in background';

  @override
  String get privacyGhostScheduleHint =>
      'Useful for work: outside this time window no one sees your location, in any of your circles (automatic \"clock-out\").';

  @override
  String get privacyLimitHours => 'Limit hours';

  @override
  String get privacyFrom => 'From';

  @override
  String get privacyTo => 'To';

  @override
  String get privacySosAllCircles =>
      'For now this notifies all your circles. You can choose only some people.';

  @override
  String privacySosSelectedCount(int count) {
    return 'Notifies only $count chosen people, not the whole circle.';
  }

  @override
  String get privacySosWhoToNotify => 'Who to notify in case of SOS';

  @override
  String get privacySosSmsNumberEmpty => 'SOS SMS number (if you\'re offline)';

  @override
  String privacySosSmsNumberSet(String number) {
    return 'SOS via SMS: $number';
  }

  @override
  String get privacyCrashDetectionTitle => 'Crash detection';

  @override
  String get privacyCrashDetectionDesc =>
      'After a violent impact while driving, a countdown starts: if you don\'t cancel it, automatic SOS.';

  @override
  String get privacySpeedAlertHint =>
      'Set your own threshold: circle members with Kinly+ get an alert if you exceed it while driving.';

  @override
  String get privacyEnableAlert => 'Enable alert';

  @override
  String get privacyThreshold => 'Threshold';

  @override
  String privacySpeedKmh(int speed) {
    return '$speed km/h';
  }

  @override
  String get privacyWeeklySummaryHint =>
      'A weekly notification with the circle\'s activity: SOS, help requests, safe zone entries, speed alerts.';

  @override
  String get privacyReceiveSummary => 'Receive the summary';

  @override
  String get privacyReviewCirclesGuide => 'Review the circles guide';

  @override
  String get changePasswordMismatch => 'The two passwords don\'t match.';

  @override
  String get changePasswordGenericError =>
      'We couldn\'t change the password. Please try again.';

  @override
  String get changePasswordDoneTitle => 'Password updated';

  @override
  String get changePasswordDoneBody =>
      'From now on, use the new password to sign in.';

  @override
  String get changePasswordNew => 'New password';

  @override
  String get changePasswordMinChars => 'At least 6 characters.';

  @override
  String get changePasswordConfirmHint => 'Confirm password';

  @override
  String get helpFaqsTitle => 'Frequently asked questions';

  @override
  String get helpFaq1Q => 'Who sees my location?';

  @override
  String get helpFaq1A =>
      'Only people in one of your circles, and only if your sharing mode allows it (automatic, on request, or paused). You can change it anytime from your profile.';

  @override
  String get helpFaq2Q => 'How do I invite someone to a circle?';

  @override
  String get helpFaq2A =>
      'Create a circle from the \"Circles\" tab and share the invite code shown to you: whoever enters it joins right away.';

  @override
  String get helpFaq3Q => 'What changes with Kinly+?';

  @override
  String get helpFaq3A =>
      'The free plan has a limit of 2 circles and 6 people per circle. Kinly+ removes the limits and unlocks location history, safe zones and driving alerts.';

  @override
  String get helpFaq4Q => 'How do I delete a safe zone or leave a circle?';

  @override
  String get helpFaq4A =>
      'Safe zones are deleted from a circle\'s \"Safe zones\" screen (trash icon). To leave a circle, write to us here: we\'ll help you do it manually until we add the button in the app.';

  @override
  String get helpWriteToUs => 'Write to us';

  @override
  String get helpPriorityBadge => 'Kinly+ priority';

  @override
  String get helpPriorityHint =>
      'As a Kinly+ subscriber, your request is placed in the priority queue.';

  @override
  String get helpNormalHint =>
      'Your request stays here, we\'ll read it as soon as possible.';

  @override
  String get helpDescribeHint => 'Describe the problem or question...';

  @override
  String get helpSend => 'Send';

  @override
  String get helpSentSnackbar =>
      'Message sent: you\'ll find it below among your requests.';

  @override
  String get helpSendError =>
      'We couldn\'t send the message. Please try again.';

  @override
  String get helpYourRequests => 'Your requests';

  @override
  String get helpNoRequestsYet => 'You haven\'t sent any requests yet.';

  @override
  String get helpStatusAnswered => 'Answered';

  @override
  String get helpStatusClosed => 'Closed';

  @override
  String get helpStatusInProgress => 'In progress';

  @override
  String get adminSupportNoMessages => 'No messages.';

  @override
  String get adminSupportPriority => 'Priority';

  @override
  String adminSupportRepliedWith(String reply) {
    return 'Replied: $reply';
  }

  @override
  String get adminSupportReplyError =>
      'We couldn\'t send the reply. Please try again.';

  @override
  String get adminSupportReplyTitle => 'Reply';

  @override
  String get adminSupportReplyHint => 'Write your reply...';

  @override
  String get adminSupportSendReply => 'Send reply';

  @override
  String get avatarUploadError =>
      'We couldn\'t upload the photo. Please try again.';

  @override
  String get avatarChooseFromGallery => 'Choose from gallery';

  @override
  String get avatarTakePhoto => 'Take a photo';

  @override
  String get avatarRemovePhoto => 'Remove photo';

  @override
  String get avatarPickerTitle => 'Choose your avatar';

  @override
  String get avatarChangePhoto => 'Change photo';

  @override
  String get avatarUploadPhoto => 'Upload a photo';

  @override
  String get avatarThemedTitle => 'Themed avatars';

  @override
  String get avatarThemedHint => 'Used when you haven\'t uploaded a photo.';

  @override
  String get avatarUseInitials => 'Use initials';

  @override
  String get personLocationNotShared => 'Location not shared';

  @override
  String get personBirthdayToday => '🎂 Today is their birthday!';

  @override
  String personUpdatedAt(String label) {
    return 'Updated $label';
  }

  @override
  String personBatteryPercent(int percent) {
    return 'Battery $percent%';
  }

  @override
  String get personRadarLink => 'Proximity radar';

  @override
  String get personLocationHistoryLink => 'Location history';

  @override
  String get personStatisticsLink => 'Statistics and trips';

  @override
  String get personDrivingAlertsLink => 'Driving alerts';

  @override
  String get personSharingWithYou => 'Sharing their location with you.';

  @override
  String get personGhostMode =>
      'They\'re in ghost mode: they can\'t receive requests right now.';

  @override
  String get personRequestSent => 'Request sent';

  @override
  String get personRequestLocation => 'Request location';

  @override
  String get personPingDailyLimitTitle => 'Daily limit reached';

  @override
  String get personPingDailyLimitBody =>
      'You\'ve already sent 5 pings today: that\'s the free plan limit. With Kinly+ you can send as many as you want.';

  @override
  String get personPingSent => 'Sent';

  @override
  String sosAlertTitle(String name) {
    return 'SOS · $name';
  }

  @override
  String get sosAlertCancelError =>
      'We couldn\'t cancel the SOS. Please try again.';

  @override
  String get sosYourAlertActive => 'Your SOS is active';

  @override
  String sosPersonActivated(String name) {
    return '$name activated SOS';
  }

  @override
  String sosActivatedAt(String time) {
    return 'Activated at $time';
  }

  @override
  String get sosWaitingAddress => 'Waiting for address...';

  @override
  String get sosEmergencyHint =>
      'In a real emergency call 911. Kinly only shares location: no audio recording.';

  @override
  String sosCallPerson(String name) {
    return 'Call $name';
  }

  @override
  String get sosImSafeCancelSos => 'I\'m safe, cancel SOS';

  @override
  String helpRequestTitle(String name) {
    return 'Help · $name';
  }

  @override
  String get helpRequestCloseError =>
      'We couldn\'t close the request. Please try again.';

  @override
  String helpRequestYouAsked(String reason) {
    return 'You asked for help: $reason';
  }

  @override
  String helpRequestPersonNeeds(String name, String reason) {
    return '$name needs help: $reason';
  }

  @override
  String helpRequestRequestedAt(String time) {
    return 'Requested at $time';
  }

  @override
  String get helpRequestCloseButton => 'Everything\'s fine, close request';

  @override
  String get sosContactsTitle => 'SOS contacts';

  @override
  String get sosContactsNoneSelected =>
      'No one selected: SOS will notify everyone in your circles.';

  @override
  String sosContactsSelectedCount(int count) {
    return 'SOS will notify only the $count selected people, not the whole circle.';
  }

  @override
  String get sosContactsEmpty => 'You don\'t have anyone in your circles yet.';

  @override
  String radarTitle(String name) {
    return 'Radar · $name';
  }

  @override
  String get radarPermissionNeeded =>
      'Location permission is needed to use the radar.';

  @override
  String radarPersonNotSharing(String name) {
    return '$name isn\'t sharing their location right now.';
  }

  @override
  String get radarCompassUnavailable =>
      'Compass not available on this device. Use the map to orient yourself.';

  @override
  String get radarVeryClose => 'You\'re very close!';

  @override
  String radarFollowArrow(String name) {
    return 'Follow the arrow to reach $name';
  }
}
