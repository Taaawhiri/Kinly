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
  String get circlesModeOverrideHint => 'Only applies to this circle: other circles keep your general profile setting.';

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
  String get circlesCoachStep1Body => 'Each circle has its own members, icon and settings: you can have more than one.';

  @override
  String get circlesCoachStep2Title => 'Circle actions';

  @override
  String get circlesCoachStep2Body => 'From here you manage safe zones, meeting point, messages, group expenses and the weekly summary.';

  @override
  String get circlesCoachStep3Title => 'Invite code';

  @override
  String get circlesCoachStep3Body => 'Tap to copy it: only whoever gets it from you can join this circle.';

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
  String get meetingPointEmptyMessage => 'Suggest a place to meet: everyone will see their own real-time distance, without texting \"where are you?\".';

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
  String get meetingPointLocationUnavailable => 'We couldn\'t detect your location.';

  @override
  String get meetingPointChooseNameAndLocation => 'Choose a name and a location.';

  @override
  String get meetingPointCreateError => 'We couldn\'t create the meeting point. Please try again.';

  @override
  String circleMessagesTitle(String circleName) {
    return 'Messages · $circleName';
  }

  @override
  String get circleMessagesSendError => 'We couldn\'t send the message. Please try again.';

  @override
  String get circleMessagesDailyLimitTitle => 'Daily limit reached';

  @override
  String get circleMessagesDailyLimitBody => 'You\'ve already sent 5 messages today: that\'s the free plan limit. With Kinly+ you can send as many as you want.';

  @override
  String get circleMessagesGotIt => 'Got it';

  @override
  String get circleMessagesDiscoverPlus => 'Discover Kinly+';

  @override
  String get circleMessagesHintPremium => 'Only for short, important notices. For chatting, use WhatsApp or another messaging app.';

  @override
  String get circleMessagesHintFree => 'Only for short, important notices (max 5 per day on the free plan). For chatting, use WhatsApp or another messaging app.';

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
  String get expensesEmptyMessage => 'Keep track of who paid what in the circle, without writing it down from memory.';

  @override
  String get expensesBalancesTitle => 'Balances';

  @override
  String get expensesListTitle => 'Expenses';

  @override
  String get expensesSetPaymentLinkHint => 'Set your payment link in Privacy and safety to make it easier for people to pay you.';

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
  String get expensesFillFields => 'Fill in description, amount and at least one person.';

  @override
  String get expensesSaveError => 'We couldn\'t save the expense. Please try again.';

  @override
  String get expensesDailyLimitTitle => 'Daily limit reached';

  @override
  String get expensesDailyLimitBody => 'You\'ve already logged 5 expenses today: that\'s the free plan limit. With Kinly+ you can log as many as you want.';

  @override
  String get expensesSplitHint => 'You pay: it\'s split among the people you select below.';

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
  String get weeklySummaryPushHint => 'You can also receive this summary via notification once a week: turn it on from Profile → Privacy and safety.';

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
  String get requestsNotifyOnReply => 'You\'ll get a notification when they reply';

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
  String get requestsEmptyMessage => 'When someone wants to see your location, or you want to see theirs, the request will appear here.';

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
  String get profileStatusPickerHint => 'Visible to your circle on the map until tonight.';

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
  String get profileFeatureLocationHistoryDesc => 'Review where circle members have been over the past days.';

  @override
  String get profileFeatureSafeZonesTitle => 'Safe zones';

  @override
  String get profileFeatureSafeZonesDesc => 'Home, work, school: a custom notification on every arrival or departure.';

  @override
  String get profileFeatureDrivingAlertsTitle => 'Driving alerts';

  @override
  String get profileFeatureDrivingAlertsDesc => 'Know when a driver exceeds a speed limit you set.';

  @override
  String get profileFeatureBackgroundTrackingTitle => 'Background tracking';

  @override
  String get profileFeatureBackgroundTrackingDesc => 'Location keeps updating even with the app closed.';

  @override
  String get profileFeatureUnlimitedTitle => 'Unlimited messages, pings and expenses';

  @override
  String get profileFeatureUnlimitedDesc => 'Send as many messages, pings and expenses as you want, with no limits.';

  @override
  String get profileFeatureShoppingTitle => 'Bring me something';

  @override
  String get profileFeatureShoppingDesc => 'Let the circle know when you\'re at the supermarket or a bar.';

  @override
  String get profileFeaturePrioritySupportTitle => 'Priority support';

  @override
  String get profileFeaturePrioritySupportDesc => 'Dedicated support for your circle, 7 days a week.';
}
