import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class DatabaseService {
  final _supabase = Supabase.instance.client;

  // 1. مراقبة الجلسة والبروفايل
  User? get currentUser => _supabase.auth.currentUser;
  
  // تتبع حالة المستخدم (هل هو مسجل دخول أم لا) لضمان عدم تكرار طلب تسجيل الدخول
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // 2. تسجيل دخول جوجل مع معالجة الأخطاء (Robust Google Sign-In)
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      // استخدام Client ID الذي تم إنشاؤه في Google Cloud وحفظه في Supabase
      const webClientId = '62134907551-ofam7s8j4m4id3qtdqac6vrk7ui2d2o3.apps.googleusercontent.com';

      final googleSignIn = GoogleSignIn(serverClientId: webClientId);
      final googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) return null; // المستخدم ألغى التسجيل

      final googleAuth = await googleUser.authentication;
      
      // تسجيل الدخول في سوبابيس باستخدام الـ Tokens المستلمة
      return await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
    } catch (e) {
      print('خطأ في تسجيل الدخول: $e');
      rethrow;
    }
  }

  // 3. نظام الرسائل المطور (Messages)
  // تم إضافة 'user_name' و 'avatar_url' لضمان ظهور بيانات المستخدم في الشات فوراً
  Future<void> sendMessage(String roomId, String content) async {
    if (currentUser == null) return;

    await _supabase.from('messages').insert({
      'room_id': roomId,
      'content': content,
      'user_id': currentUser!.id,
      'user_name': currentUser!.userMetadata?['full_name'] ?? 'مستخدم مجهول',
      'avatar_url': currentUser!.userMetadata?['avatar_url'],
    });
  }

  // حذف الرسالة مع التأكد من أن الحاذف هو صاحب الرسالة
  Future<void> deleteMessage(String messageId) async {
    await _supabase.from('messages')
        .delete()
        .match({'id': messageId, 'user_id': currentUser!.id});
  }

  // 4. نظام البلاغات والحظر (Reporting & Blocking)
  // هذا الجزء أساسي للقبول في متاجر التطبيقات (Apple & Google)
  Future<void> reportUser({
    required String reportedUserId,
    required String reason,
    String? messageContext,
  }) async {
    await _supabase.from('reports').insert({
      'reporter_id': currentUser!.id,
      'reported_id': reportedUserId,
      'reason': reason,
      'context': messageContext, // نص الرسالة التي تم الإبلاغ عنها
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // حظر مستخدم (لإخفاء رسائله عنك تماماً)
  Future<void> blockUser(String blockedUserId) async {
    await _supabase.from('blocks').insert({
      'blocker_id': currentUser!.id,
      'blocked_id': blockedUserId,
    });
  }

  // 5. جلب بيانات الغرف (Real-time Stream)
  // ستحتاج هذا لعرض الرسائل وهي تصل فوراً (Live Chat)
  Stream<List<Map<String, dynamic>>> getMessagesStream(String roomId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: true);
  }

  // 6. تسجيل الخروج الكامل
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _supabase.auth.signOut();
  }
}
