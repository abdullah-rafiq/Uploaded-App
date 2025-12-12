import 'app_locale.dart';

class L10n {
  static bool get _isUrdu => AppLocale.isUrdu();

  static String workerTodayOverviewTitle() =>
      _isUrdu ? 'آج کا خلاصہ' : "Today's overview";

  static String workerTodayOverviewSubtitle() => _isUrdu
      ? 'اپنی آنے والی درخواستوں اور کمائی کو منظم کریں۔'
      : 'Manage your incoming requests and track your earnings.';

  static String workerIncomingRequestsTitle() =>
      _isUrdu ? 'آنے والی درخواستیں' : 'Incoming requests';

  static String workerIncomingRequestsSubtitle() => _isUrdu
      ? 'ڈیمو جاب کی تفصیل دیکھنے کے لئے ٹیپ کریں۔ مستقبل میں یہاں حقیقی بکنگز نظر آئیں گی۔'
      : 'Tap to view a demo job detail. In the future this will show real-time bookings assigned to you.';

  static String workerMyJobsEarningsTitle() =>
      _isUrdu ? 'میری جابس اور کمائی' : 'My jobs & earnings';

  static String workerMyJobsEarningsSubtitle() => _isUrdu
      ? 'ڈیمو کمائی کا خلاصہ دیکھنے کے لئے ٹیپ کریں۔ بعد میں یہاں مکمل شدہ جابس اور ادائیگی کی ہسٹری آئے گی۔'
      : 'Tap to view a demo earnings summary. Later this will include completed jobs and payout history.';

  static String workerNavHome() => _isUrdu ? 'ہوم' : 'Home';
  static String workerNavJobs() => _isUrdu ? 'جابز' : 'Jobs';
  static String workerNavEarnings() => _isUrdu ? 'کمائی' : 'Earnings';
  static String workerNavMessages() => _isUrdu ? 'پیغامات' : 'Messages';
  static String workerNavProfile() => _isUrdu ? 'پروفائل' : 'Profile';
}
