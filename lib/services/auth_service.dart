import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../models.dart';

class AuthService {
  static final _client = SupabaseService.client;

  // تسجيل الدخول بالبريد وكلمة المرور
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  // إنشاء حساب جديد
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim()},
    );
    return response;
  }

  // تسجيل الخروج
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // الجلسة الحالية (تحفظ تلقائياً)
  static Session? get currentSession => _client.auth.currentSession;
  static User? get currentUser => _client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  // الاستماع لتغييرات المصادقة
  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // جلب الملف الشخصي للمستخدم الحالي
  static Future<AppUser?> getCurrentProfile() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', uid)
          .single();
      return AppUser.fromMap(data);
    } catch (_) {
      return null;
    }
  }

  // تحديث الحضور (online/offline)
  static Future<void> setOnlineStatus(bool isOnline) async {
    final uid = currentUser?.id;
    if (uid == null) return;
    try {
      await _client
          .from('profiles')
          .update({'is_online': isOnline, 'last_seen': DateTime.now().toIso8601String()})
          .eq('id', uid);
    } catch (_) {}
  }

  // تغيير كلمة المرور
  static Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  // إعادة تعيين كلمة المرور عبر البريد
  static Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }
}
