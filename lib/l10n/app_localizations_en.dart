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
  String get languagePickerTitle => 'Choose language';

  @override
  String get homeWidgetTitle => 'Your circle';

  @override
  String get homeWidgetEmpty => 'No one is sharing right now';

  @override
  String arrivalPromptTitle(String zone) {
    return 'Did you arrive at $zone?';
  }

  @override
  String get arrivalPromptAction => 'I\'ve arrived';

  @override
  String arrivalPingMessage(String zone) {
    return '🏠 I\'ve arrived at $zone!';
  }

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
      'You\'re using the web companion of Kinly: here your location only updates while this tab is open.';

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
  String get circlesActionShoppingList => 'Shopping list';

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
  String get shoppingListTitle => 'Shopping list';

  @override
  String get shoppingListEmptyTitle => 'Empty list';

  @override
  String get shoppingListEmptyMessage =>
      'Add something you need: if someone in the circle passes near a saved supermarket, they\'ll get an automatic reminder.';

  @override
  String get shoppingListAddButton => 'Add';

  @override
  String get shoppingListAddHint => 'E.g. Milk, Bread…';

  @override
  String get shoppingListClaimButton => 'I\'ll get it';

  @override
  String shoppingListClaimedBy(String name) {
    return '$name is getting it';
  }

  @override
  String get shoppingListUnclaim => 'Undo';

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
  String get avatarGenerativeTitle => 'Or generate a unique avatar';

  @override
  String get avatarGenerativeHint =>
      'A pattern generated automatically from a random seed: no drawing needed, always different.';

  @override
  String get avatarGenerativeShuffle => 'Generate another';

  @override
  String get avatarGenerativeConfirm => 'Use this avatar';

  @override
  String get avatarGenerativeSelected => 'This is your current avatar';

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

  @override
  String get paywallFeatureLocationHistoryTitle => 'Location history';

  @override
  String get paywallFeatureLocationHistoryDesc =>
      'Review where circle members have been over the past days.';

  @override
  String get paywallFeatureStatsTitle => 'Statistics and trips';

  @override
  String get paywallFeatureStatsDesc =>
      'Distance traveled and a map of trips taken, reconstructed from history.';

  @override
  String get paywallFeatureSafeZonesTitle => 'Safe zones';

  @override
  String get paywallFeatureSafeZonesDesc =>
      'Home, work, school: get a custom notification whenever someone arrives or leaves.';

  @override
  String get paywallFeatureUnlimitedCirclesTitle => 'Unlimited circles';

  @override
  String get paywallFeatureUnlimitedCirclesDesc =>
      'No limit on the number of circles or people per circle.';

  @override
  String get paywallFeatureDrivingTitle => 'Driving alerts';

  @override
  String get paywallFeatureDrivingDesc =>
      'Know when a driver exceeds a speed limit you set.';

  @override
  String get paywallFeatureBackgroundTitle => 'Background tracking';

  @override
  String get paywallFeatureBackgroundDesc =>
      'Location keeps updating even with the app closed.';

  @override
  String get paywallFeatureUnlimitedMsgTitle =>
      'Unlimited messages, pings and expenses';

  @override
  String get paywallFeatureUnlimitedMsgDesc =>
      'Send as many messages, pings and expenses as you want, with no daily limit.';

  @override
  String get paywallFeatureShoppingTitle => 'Bring me something';

  @override
  String get paywallFeatureShoppingDesc =>
      'Let the circle know when you\'re at the supermarket or a bar, so they can ask you for something quickly.';

  @override
  String get paywallFeaturePriorityTitle => 'Priority support';

  @override
  String get paywallFeaturePriorityDesc =>
      'Dedicated support for your circle, 7 days a week.';

  @override
  String get paywallFeatureGhostModeTitle => 'Temporary Ghost Mode';

  @override
  String get paywallFeatureGhostModeDesc =>
      'Make your location invisible for 2 hours with one tap: everything becomes visible again on its own.';

  @override
  String get paywallFeatureWidgetTitle => 'Home screen widget';

  @override
  String get paywallFeatureWidgetDesc =>
      'Whoever matters most, always at a glance, without opening the app (Android).';

  @override
  String get paywallRequestError =>
      'We couldn\'t send the request. Please try again.';

  @override
  String get paywallCancelMessage =>
      'I\'d like to cancel my Kinly+ subscription.';

  @override
  String paywallUpgradeMessage(String plan) {
    return 'I\'d like to activate the Kinly+ $plan plan.';
  }

  @override
  String get paywallComingSoonTitle => 'Coming soon';

  @override
  String get paywallComingSoonBody =>
      'Kinly+ payments aren\'t active yet: we\'ve logged your request and will activate the plan manually.';

  @override
  String get paywallFamilyActive => 'Kinly+ Family active';

  @override
  String get paywallIndividualActive => 'Kinly+ Individual active';

  @override
  String get paywallIncluded => 'Kinly+ included';

  @override
  String paywallIncludedInFamilyOf(String name) {
    return 'Included in $name\'s Family plan';
  }

  @override
  String get paywallYourSubscriptionActive => 'Your subscription is active';

  @override
  String get paywallMorePeaceOfMind =>
      'More peace of mind for the whole circle';

  @override
  String get paywallFamilyIncludedHint =>
      'As long as you\'re part of their circle, you get all Kinly+ benefits at no cost.';

  @override
  String get paywallAllUnlockedHint =>
      'All the benefits below are unlocked for you and your circles.';

  @override
  String get paywallChooseTierHint =>
      'An Individual plan unlocks the benefits only for you; a Family plan extends them to whoever you invite.';

  @override
  String get paywallWhatIncludes => 'What\'s included';

  @override
  String get paywallComparePlans => 'Compare plans';

  @override
  String get paywallFamilyMemberHint =>
      'You pay nothing: whoever created that circle with the Family plan extended Kinly+ to you and the other early members (up to 6).';

  @override
  String get paywallYourFamilyPlan => 'Your Family plan';

  @override
  String get paywallFamilyOwnerHint =>
      'Whoever joins a circle you created (up to 6 people, based on when they joined) has Kinly+ included, at no cost.';

  @override
  String get paywallRequestSent => 'Request sent.';

  @override
  String get paywallRequestCancellation => 'Request cancellation';

  @override
  String get paywallManageSubscription => 'Manage subscription';

  @override
  String get paywallIndividualCancelHint =>
      'Your Kinly+ isn\'t linked to a real payment yet. To deactivate it, send a request: we\'ll turn it off manually.';

  @override
  String get paywallSwitchToFamily => 'Switch to Family';

  @override
  String get paywallFamilyPrice => '€9.90';

  @override
  String get paywallIndividualPrice => '€3.90';

  @override
  String get paywallFamilyUpgradeDesc =>
      'Extend Kinly+ to whoever you invite to the circles you create (up to 6 people), not just yourself.';

  @override
  String get paywallIndividualTitle => 'Individual';

  @override
  String get paywallIndividualDesc =>
      'Unlock all Kinly+ benefits for yourself, across all your circles.';

  @override
  String get paywallSwitchToIndividual => 'Switch to Individual';

  @override
  String get paywallFamilyTitle => 'Family';

  @override
  String get paywallFamilyDesc =>
      'A single subscription: whoever joins a circle you create (up to 6 people) has Kinly+ included.';

  @override
  String get paywallDesignPreviewHint =>
      'Design preview: payments aren\'t active yet.';

  @override
  String get paywallPerMonth => ' / month';

  @override
  String get paywallCompareCirclesMembers => 'Circles and members';

  @override
  String get paywallCompareFreeCircleLimit => 'Up to 2 / 6';

  @override
  String get paywallCompareUnlimited => 'Unlimited';

  @override
  String get paywallCompareMessagesPingExpenses => 'Messages, pings, expenses';

  @override
  String get paywallCompare5PerDay => '5 per day';

  @override
  String get paywallCompareSafeZonesCreate => 'Safe zones (create)';

  @override
  String get paywallCompareWhoBenefits => 'Who benefits';

  @override
  String get paywallCompareOnlyYou => 'Only you';

  @override
  String get paywallCompareUpTo6People => 'Up to 6 people';

  @override
  String get paywallComparePrice => 'Price';

  @override
  String get paywallCompareFree => 'Free';

  @override
  String get paywallCompareIndividualPricePerMonth => '€3.90/month';

  @override
  String get paywallCompareFamilyPricePerMonth => '€9.90/month';

  @override
  String get paywallTierFree => 'Free';

  @override
  String get paywallPlanLabelIndividual => 'Individual (€3.90/month)';

  @override
  String get paywallPlanLabelFamily => 'Family (€9.90/month)';

  @override
  String safeZonesTitle(String circle) {
    return 'Safe zones · $circle';
  }

  @override
  String get safeZonesEmptyTitleFree => 'No safe zones';

  @override
  String get safeZonesEmptyMessagePremium =>
      'Create a zone (e.g. home or school) to get a notification when someone enters or leaves.';

  @override
  String get safeZonesEmptyMessageFree =>
      'Switch to Kinly+ to create safe zones and get a notification when someone arrives at or leaves a place.';

  @override
  String get safeZonesCreateFirst => 'Create the first zone';

  @override
  String get safeZonesSuggestedForYou => 'Suggested for you';

  @override
  String safeZonesFrequentVisit(int days) {
    return 'You go here often ($days different days) · tap to create a zone';
  }

  @override
  String safeZonesKindRadius(String kindLabel, int radius) {
    return '$kindLabel · Radius $radius m';
  }

  @override
  String get safeZonesEditTooltip => 'Edit zone';

  @override
  String get safeZonesDeleteTooltip => 'Delete zone';

  @override
  String get safeZonesLastEntry => 'Last entry recorded';

  @override
  String get safeZonesLastExit => 'Last exit recorded';

  @override
  String get safeZonesEditTitle => 'Edit safe zone';

  @override
  String get safeZonesNewTitle => 'New safe zone';

  @override
  String get safeZonesNameHint => 'Name (e.g. Home, School)';

  @override
  String get safeZonesPlaceType => 'Place type';

  @override
  String safeZonesRadiusMeters(int radius) {
    return 'Radius: $radius m';
  }

  @override
  String safeZonesRadiusValue(int radius) {
    return '$radius m';
  }

  @override
  String get safeZonesOrEnterAddress => 'Or enter an address';

  @override
  String get safeZonesAddressNotFound =>
      'Address not found. Try being more precise.';

  @override
  String get safeZonesAddressSearchError =>
      'We couldn\'t search this address. Please try again.';

  @override
  String get safeZonesPlusOnly => 'Safe zones are a Kinly+ feature.';

  @override
  String get safeZonesSaveChangesError =>
      'We couldn\'t save the changes. Please try again.';

  @override
  String get safeZonesCreateError =>
      'We couldn\'t create the zone. Please try again.';

  @override
  String get safeZonesSaveChanges => 'Save changes';

  @override
  String get safeZonesCreateButton => 'Create zone';

  @override
  String get historyDeleteConfirmTitle => 'Delete history?';

  @override
  String get historyDeleteConfirmBody =>
      'Deletes all points recorded so far, including trip statistics already calculated from this data. This can\'t be undone.';

  @override
  String get historyDeleteButton => 'Delete';

  @override
  String get historyDeletedSnackbar => 'History deleted.';

  @override
  String get historyDeleteError =>
      'We couldn\'t delete the history. Please try again.';

  @override
  String historyTitle(String name) {
    return 'History · $name';
  }

  @override
  String get historyDeleteTooltip => 'Delete history';

  @override
  String get historyUpsellMessage =>
      'Switch to Kinly+ to review where circle members have been over the past days.';

  @override
  String get historyEmpty => 'No history available yet.';

  @override
  String historyToday(String time) {
    return 'Today, $time';
  }

  @override
  String statsTitle(String name) {
    return 'Statistics · $name';
  }

  @override
  String get statsUpsellMessage =>
      'Switch to Kinly+ to see how far you\'ve traveled and review your trips.';

  @override
  String get statsNoTripsYet =>
      'No trips available yet: come back after moving around a bit.';

  @override
  String get statsLast7Days => 'Last 7 days';

  @override
  String get statsLast30Days => 'Last 30 days';

  @override
  String get statsWeeklySummary => 'Weekly summary';

  @override
  String statsTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trips',
      one: '$count trip',
    );
    return '$_temp0';
  }

  @override
  String get statsRecentTrips => 'Recent trips';

  @override
  String get statsTripLabel => 'Trip';

  @override
  String get statsDeparture => 'Departure';

  @override
  String get statsArrival => 'Arrival';

  @override
  String get statsDistance => 'Distance';

  @override
  String get statsDuration => 'Duration';

  @override
  String statsMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String statsDateAndMinutes(String date, int minutes) {
    return '$date · $minutes min';
  }

  @override
  String get statsDayMon => 'M';

  @override
  String get statsDayTue => 'T';

  @override
  String get statsDayWed => 'W';

  @override
  String get statsDayThu => 'T';

  @override
  String get statsDayFri => 'F';

  @override
  String get statsDaySat => 'S';

  @override
  String get statsDaySun => 'S';

  @override
  String speedAlertsTitle(String name) {
    return 'Driving alerts · $name';
  }

  @override
  String get speedAlertsUpsellMessage =>
      'Switch to Kinly+ to know when a driver exceeds the speed limit they set.';

  @override
  String get speedAlertsEmpty =>
      'No alerts recorded: this person hasn\'t exceeded their speed threshold yet (or hasn\'t set one).';

  @override
  String speedAlertsKmhLimit(int speed, int threshold) {
    return '$speed km/h (limit $threshold km/h)';
  }

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonContinue => 'Continue';

  @override
  String get biometricLockedTitle => 'Kinly is locked';

  @override
  String get biometricLockedMessage =>
      'Unlock with your fingerprint, face, or device passcode to continue.';

  @override
  String get biometricUnlockButton => 'Unlock';

  @override
  String get splashConnectionError =>
      'We can\'t reach Kinly. Check your connection and try again.';

  @override
  String get onboardingWelcomeTitle => 'Welcome to Kinly';

  @override
  String get onboardingWelcomeDesc =>
      'Share your location only with who really matters: family, friends, colleagues. Always invite-only, never public.';

  @override
  String get onboardingSafeTitle => 'Always safe';

  @override
  String get onboardingSafeDesc =>
      'SOS and \"Ask for help\" immediately alert your circle when needed. Safe zones tell you when someone arrives at or leaves home, work or school.';

  @override
  String get onboardingContactTitle => 'Stay in touch';

  @override
  String get onboardingContactDesc =>
      'Quick messages, a shared meeting point, and local weather: all in one place, without having to ask \"where are you?\".';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingBiometricTitle => 'Protect your access';

  @override
  String get onboardingBiometricDesc =>
      'Turn on unlock with fingerprint, face or device passcode right away: one more layer beyond your password, verified by the system (Kinly never sees your biometric data).';

  @override
  String get createCircleTitle => 'Create your circle';

  @override
  String get circleLimitCirclesMessage =>
      'On the free plan you can be part of up to 2 circles. Switch to Kinly+ for no limits.';

  @override
  String get createCircleError =>
      'We couldn\'t create the circle. Please try again.';

  @override
  String get createCircleNameQuestion => 'What\'s it called?';

  @override
  String get createCircleNameHint =>
      'For example \"Family\" or \"Weekend in the mountains\".';

  @override
  String get createCircleNameField => 'Circle name';

  @override
  String get createCircleIconLabel => 'Icon';

  @override
  String get createCircleColorLabel => 'Color';

  @override
  String get createCircleSubmit => 'Create circle';

  @override
  String createCircleSuccessTitle(String name) {
    return '\"$name\" is ready!';
  }

  @override
  String get createCircleSuccessMessage =>
      'Share this code with whoever you want to invite. Only those who have it can join.';

  @override
  String get createCircleCodeCopied => 'Code copied';

  @override
  String get createCircleCopyCode => 'Copy code';

  @override
  String get joinCircleTitle => 'Join a circle';

  @override
  String get joinCircleQuestion => 'Enter the invite code';

  @override
  String get joinCircleHint =>
      'Whoever created the circle sends it to you, for example by message.';

  @override
  String get joinCircleInvalidCode =>
      'Invalid code. Ask whoever invited you to double-check it.';

  @override
  String get joinCircleMemberLimitMessage =>
      'This circle has already reached the free plan\'s limit of 6 people.';

  @override
  String get joinCircleError =>
      'We couldn\'t verify the code. Please try again.';

  @override
  String get joinCircleSubmit => 'Join';

  @override
  String get joinCircleFormatHint =>
      'Ask whoever created the circle for the code: it has the format XXX-0000.';

  @override
  String get sharingModeAutomatic => 'Automatic';

  @override
  String get sharingModeOnRequest => 'On request';

  @override
  String get sharingModePaused => 'Paused';

  @override
  String get sharingModeFuzzy => 'Approximate';

  @override
  String get sharingModeAutomaticDesc =>
      'Your location is always visible to your circle, in real time.';

  @override
  String get sharingModeOnRequestDesc =>
      'No one sees your location until you approve a request.';

  @override
  String get sharingModePausedDesc =>
      'Ghost mode: you\'re invisible, no one can ask where you are.';

  @override
  String get sharingModeFuzzyDesc =>
      'Your circle only sees the general area (about 1 km), never the exact point.';

  @override
  String get ghostModeTitle => 'Temporary Ghost Mode';

  @override
  String get ghostModeDesc =>
      'Go fully invisible for 2 hours, then become visible again on your own.';

  @override
  String get ghostModePlusTeaser =>
      'Go fully invisible for a limited time. Kinly+ feature.';

  @override
  String get ghostModeActiveTitle => 'Ghost Mode active';

  @override
  String ghostModeActiveUntil(String time) {
    return 'You\'ll be visible again at $time';
  }

  @override
  String get ghostModeActivate => 'Activate';

  @override
  String get ghostModeEndNow => 'End now';

  @override
  String get helpReqReasonFlatTire => 'Flat tire';

  @override
  String get helpReqReasonAccident => 'Accident';

  @override
  String get helpReqReasonFollowed => 'I feel followed';

  @override
  String get helpReqReasonLowBattery => 'Low battery';

  @override
  String get helpReqReasonOther => 'Other';

  @override
  String get pingKindCoffee => 'Coffee?';

  @override
  String get pingKindTraffic => 'Watch out for traffic';

  @override
  String get pingKindHighFive => 'High five';

  @override
  String get safeZoneKindHome => 'Home';

  @override
  String get safeZoneKindWork => 'Work';

  @override
  String get safeZoneKindSchool => 'School';

  @override
  String get safeZoneKindOther => 'Other';

  @override
  String get personLastUpdateNow => 'Just now';

  @override
  String personLastUpdateMinutes(int minutes) {
    return '$minutes min ago';
  }

  @override
  String personLastUpdateHours(int hours) {
    return '$hours h ago';
  }

  @override
  String personLastUpdateDays(int days) {
    return '$days d ago';
  }

  @override
  String get weatherClear => 'Clear';

  @override
  String get weatherPartlyCloudy => 'Partly cloudy';

  @override
  String get weatherOvercast => 'Overcast';

  @override
  String get weatherFog => 'Fog';

  @override
  String get weatherDrizzle => 'Drizzle';

  @override
  String get weatherRain => 'Rain';

  @override
  String get weatherSnow => 'Snow';

  @override
  String get weatherShowers => 'Showers';

  @override
  String get weatherSnowShowers => 'Snow showers';

  @override
  String get weatherStorm => 'Storm';

  @override
  String get weatherNow => 'Right now';

  @override
  String get tripReplayPause => 'Pause';

  @override
  String get tripReplayWatch => 'Watch the trip';

  @override
  String get mapWaitingForLocation => 'Waiting for location…';

  @override
  String get pwaInstallTitle => 'Install Kinly';

  @override
  String get pwaInstallAndroidBody =>
      'Add it to your Home Screen: it opens faster and takes no extra space.';

  @override
  String get pwaInstallButton => 'Install';

  @override
  String get pwaInstallIosBody => 'Tap Share, then \"Add to Home Screen\".';
}
