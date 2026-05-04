import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../models.dart';

class AuthService {
  static final _client = SupabaseService.client;

  static String? get currentUserId => _client.auth.currentUser?.id;

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

  static Session? get currentSession => _client.auth.currentSession;
  static User? get currentUser => _client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // جلب الملف الشخصي للمستخدم الحالي - تم تحديثه ليتوافق مع المودل الجديد ✅
  static Future<AppUser?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      
      // نقوم بدمج الإيميل من بيانات الـ Auth لضمان عدم وجود قيمة فارغة
      final Map<String, dynamic> profileData = Map<String, dynamic>.from(data);
      if (profileData['email'] == null || profileData['email'].toString().isEmpty) {
        profileData['email'] = user.email;
      }
      
      return AppUser.fromMap(profileData);
    } catch (_) {
      // في حال لم يتم العثور على بروفايل بعد، ننشئ كائن مؤقت من بيانات التسجيل
      return AppUser(
        id: user.id,
        fullName: user.userMetadata?['full_name'] ?? 'مستخدم',
        email: user.email ?? '',
        avatarUrl: '',
      );
    }
  }

  // تحديث الحضور (online/offline)
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
    } catch (_) {}
  }

  static Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  static Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }
}
