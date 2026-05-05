import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dardashati/models.dart'; // المسار الجديد المعتمد

class DatabaseService {
  static final _supabase = Supabase.instance.client;

  // 1. إدارة المستخدم الحالي والجلسة
  static User? get currentUser => _supabase.auth.currentUser;
  
  // دالة لمراقبة تغييرات الدخول/الخروج وتوجيه المستخدم (Auth Gate)
  static Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // 2. تسجيل دخول جوجل (النسخة الأكثر استقراراً)
  static Future<AuthResponse?> signInWithGoogle() async {
    try {
      const webClientId = '62134907551-ofam7s8j4m4id3qtdqac6vrk7ui2d2o3.apps.googleusercontent.com';
      final googleSignIn = GoogleSignIn(serverClientId: webClientId);
      final googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      
      return await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
    } catch (e) {
      print('خطأ في تسجيل دخول جوجل: $e');
      rethrow;
    }
  }

  // 3. نظام الرسائل الفورية (Real-time)
  // ميزة تليجرام: إرسال الرسالة مع دعم الرد (Reply)
  static Future<void> sendMessage(String receiverId, String content, {String? replyToId}) async {
    if (currentUser == null) return;

    await _supabase.from('messages').insert({
      'user_id': currentUser!.id,
      'receiver_id': receiverId, // للدردشة الخاصة
      'content': content,
      'reply_to_id': replyToId,
      'user_name': currentUser!.userMetadata?['full_name'] ?? 'مستخدم',
      'avatar_url': currentUser!.userMetadata?['avatar_url'],
    });
  }

  // دالة البث المباشر (Stream) - سرعة تليجرام في وصول الرسائل
  static Stream<List<Map<String, dynamic>>> getMessagesStream(String otherUserId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .or('user_id.eq.${currentUser!.id},receiver_id.eq.${currentUser!.id}')
        .order('created_at', ascending: true);
  }

  // 4. نظام الإشعارات (Notifications)
  static Future<List<AppNotification>> getNotifications() async {
    final response = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', currentUser!.id)
        .order('created_at', ascending: false);
    
    return (response as List).map((n) => AppNotification(
      id: n['id'],
      title: n['title'],
      body: n['body'],
      icon: _getIconForType(n['type']),
      isRead: n['is_read'] ?? false,
      createdAt: DateTime.parse(n['created_at']),
    )).toList();
  }

  // دالة مساعدة لتحديد أيقونة الإشعار
  static IconData _getIconForType(String? type) {
    switch (type) {
      case 'message': return Icons.chat_bubble_outline;
      case 'system': return Icons.info_outline;
      default: return Icons.notifications_none;
    }
  }

  // 5. حماية المستخدم (Reporting & Blocking)
  static Future<void> reportUser(String reportedId, String reason) async {
    await _supabase.from('reports').insert({
      'reporter_id': currentUser!.id,
      'reported_id': reportedId,
      'reason': reason,
    });
  }

  static Future<void> markNotificationRead(String id) async {
    await _supabase.from('notifications').update({'is_read': true}).eq('id', id);
  }

  static Future<void> markAllNotificationsRead() async {
    await _supabase.from('notifications').update({'is_read': true}).eq('user_id', currentUser!.id);
  }

  // 6. الخروج
  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _supabase.auth.signOut();
  }
}
