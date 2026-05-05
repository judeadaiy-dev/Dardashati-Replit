import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dardashati/services/supabase_service.dart';
import 'package:dardashati/utils/logger.dart';
import '../models.dart';

class AuthService {
  static final _client = SupabaseService.client;

  // --- اختصارات الوصول السريع ---
  static String? get currentUserId => _client.auth.currentUser?.id;
  static User? get currentUser => _client.auth.currentUser;
  static Session? get currentSession => _client.auth.currentSession;
  static bool get isLoggedIn => currentUser != null;
  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // --- تسجيل الدخول بالبريد وكلمة المرور ---
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      AppLogger.success("AUTH", "تم تسجيل الدخول بنجاح: $email");
      return res;
    } catch (e) {
      AppLogger.error("AUTH", "فشل تسجيل الدخول", e);
      rethrow;
    }
  }

  // --- إنشاء حساب جديد ---
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim()},
      );
      AppLogger.success("AUTH", "تم إنشاء حساب جديد بنجاح: $email");
      return response;
    } catch (e) {
      AppLogger.error("AUTH", "فشل إنشاء الحساب", e);
      rethrow;
    }
  }

  // --- تسجيل الخروج مع تحديث حالة الحضور ---
  static Future<void> signOut() async {
    try {
      await setOnlineStatus(false); // نجعله غير متصل قبل الخروج
      await _client.auth.signOut();
      AppLogger.info("AUTH", "تم تسجيل الخروج");
    } catch (e) {
      AppLogger.error("AUTH", "خطأ أثناء تسجيل الخروج", e);
    }
  }

  // --- جلب الملف الشخصي المدمج ---
  static Future<AppUser?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;
    
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      
      final Map<String, dynamic> profileData = Map<String, dynamic>.from(data);
      // تأكيد وجود الإيميل لضمان عدم حدوث خطأ في المودل
      profileData['email'] ??= user.email;
      
      return AppUser.fromMap(profileData);
    } catch (e) {
      AppLogger.trace("AUTH", "لم يتم العثور على بروفايل في جدول Profiles، يتم استخدام بيانات Auth المؤقتة");
      return AppUser(
        id: user.id,
        fullName: user.userMetadata?['full_name'] ?? 'مستخدم',
        email: user.email ?? '',
        avatarUrl: '',
        isOnline: true,
      );
    }
  }

  // --- تحديث حالة الحضور (Online/Offline) ---
  static Future<void> setOnlineStatus(bool isOnline) async {
    final uid = currentUserId;
    if (uid == null) return;
    try {
      await _client
          .from('profiles')
          .update({
            'is_online': isOnline, 
            'last_seen': DateTime.now().toIso8601String()
          })
          .eq('id', uid);
    } catch (e) {
      AppLogger.error("AUTH", "فشل تحديث حالة الحضور", e);
    }
  }

  // --- إدارة كلمات المرور ---
  static Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
    AppLogger.success("AUTH", "تم تحديث كلمة المرور بنجاح");
  }

  static Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim());
    AppLogger.info("AUTH", "تم إرسال رابط إعادة تعيين كلمة المرور إلى: $email");
  }
}
