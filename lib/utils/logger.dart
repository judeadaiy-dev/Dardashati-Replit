import 'dart:developer' as dev;

class AppLogger {
  // دالة مساعدة للحصول على الوقت الحالي بتنسيق مقروء
  static String get _timestamp => DateTime.now().toString().split('.').first.split(' ').last;

  // 1. للعمليات الناجحة (مثل: نجاح الاتصال بسوبابيس أو إرسال رسالة)
  static void success(String module, String message) {
    dev.log(
      '✅ [SUCCESS] [$module] ($_timestamp): $message',
      name: 'Dardashati.SUCCESS',
    );
  }

  // 2. للأخطاء (تم تحديثها لتستقبل الـ StackTrace لتعرف بالضبط أين حدث الخطأ)
  static void error(String module, String message, [Object? error, StackTrace? stackTrace]) {
    dev.log(
      '❌ [ERROR] [$module] ($_timestamp): $message',
      name: 'Dardashati.ERROR',
      error: error,
      stackTrace: stackTrace,
    );
  }

  // 3. للمعلومات العامة (مثل: تحميل الثيم أو تحديث عدد الإشعارات)
  static void info(String module, String message) {
    dev.log(
      'ℹ️ [INFO] [$module] ($_timestamp): $message',
      name: 'Dardashati.INFO',
    );
  }

  // 4. لمراقبة التفاصيل الدقيقة (مثل: التنقل بين الشاشات أو ضغطات الأزرار)
  static void trace(String module, String message) {
    dev.log(
      '🔍 [TRACE] [$module] ($_timestamp): $message',
      name: 'Dardashati.TRACE',
    );
  }
}
