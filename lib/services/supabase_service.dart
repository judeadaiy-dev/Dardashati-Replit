import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dardashati/utils/logger.dart'; // لاستخدام اللوجر الاحترافي
import '../env.dart';

class SupabaseService {
  // الوصول السريع للعميل (Client) من أي مكان في التطبيق
  static SupabaseClient get client => Supabase.instance.client;
  
  // الحصول على بيانات المستخدم المسجل حالياً
  static User? get currentAuthUser => client.auth.currentUser;
  
  // الحصول على معرف المستخدم (UUID) بشكل مباشر
  static String? get currentUserId => currentAuthUser?.id;

  // دالة التهيئة الأساسية التي يتم استدعاؤها في main.dart
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        anonKey: Env.supabaseAnonKey,
      );
      AppLogger.success("SUPABASE", "تم الاتصال بخوادم سوبابيس بنجاح 🚀");
    } catch (e) {
      AppLogger.error("SUPABASE", "فشل الاتصال الأولي بالخادم", e);
      rethrow; // نمرر الخطأ ليتم التقاطه في الـ PlatformDispatcher في main
    }
  }

  // دالة إضافية للتأكد من أن الجلسة (Session) لا تزال صالحة
  static bool get hasActiveSession => client.auth.currentSession != null;
}
