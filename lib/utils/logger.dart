import 'dart:developer' as dev;

class AppLogger {
  // للعمليات الناجحة
  static void success(String module, String message) {
    dev.log('✅ [SUCCESS] [$module]: $message');
  }

  // للأخطاء
  static void error(String module, String message, [Object? error]) {
    dev.log('❌ [ERROR] [$module]: $message ${error != null ? '\nDetails: $error' : ''}');
  }

  // لمراقبة البيانات (مثل الدردشة والإعدادات)
  static void info(String module, String message) {
    dev.log('ℹ️ [INFO] [$module]: $message');
  }

  // لمراقبة تدفق المستخدم (التسجيل والتحكم)
  static void trace(String module, String message) {
    dev.log('🔍 [TRACE] [$module]: $message');
  }
}
