import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'auth_service.dart'; // تأكد من استيراد هذا الملف
import '../models.dart';

class DatabaseService {
  static final _db = SupabaseService.client;
  
  // دقق: سحب المعرف من AuthService لضمان التزامن
  static String? get _uid => AuthService.currentUserId;

  // ==================== المستخدمون ====================

  static Future<List<AppUser>> getUsers() async {
    try {
      final data = await _db.from('profiles').select().order('created_at');
      return (data as List).map((m) => AppUser.fromMap(m)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<AppUser?> getUserById(String id) async {
    try {
      final data = await _db.from('profiles').select().eq('id', id).single();
      return AppUser.fromMap(data);
    } catch (_) { return null; }
  }

  static Future<void> updateProfile({
    required String fullName,
    String? bio,
    String? avatarUrl,
    String? zodiac,
    String? gender,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    final updates = <String, dynamic>{
      'full_name': fullName,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (zodiac != null) 'zodiac': zodiac,
      if (gender != null) 'gender': gender,
    };
    await _db.from('profiles').update(updates).eq('id', uid);
  }

  static Future<void> banUser(String userId, bool ban) async {
    await _db.from('profiles').update({'is_banned': ban}).eq('id', userId);
  }

  // ==================== رسائل الغرف ====================

  static Future<List<AppMessage>> getRoomMessages(String roomId) async {
    try {
      final data = await _db
          .from('room_messages')
          .select('''
            *,
            sender:profiles(id, full_name, avatar_url),
            reply_to:room_messages(content, sender:profiles(full_name))
          ''')
          .eq('room_id', roomId)
          .eq('is_deleted', false)
          .order('created_at')
          .limit(100);
      return (data as List).map((m) => AppMessage.fromMap(m)).toList();
    } catch (e) {
      return [];
    }
  }

  // احذر: هذا هو السطر الذي كان يسبب الخطأ في الصور السابقة
  static RealtimeChannel subscribeToRoomMessages(
    String roomId,
    void Function(Map<String, dynamic>) onInsert,
  ) {
    return _db
        .channel('room_messages_$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'room_messages',
          filter: PostgresChangeFilter(
            type: 'eq', // تم الإصلاح هنا (استخدام النص مباشرة)
            column: 'room_id', 
            value: roomId
          ),
          callback: (payload) => onInsert(payload.newRecord),
        )
        .subscribe();
  }

  // ==================== الإشعارات ====================

  static Future<int> getUnreadNotificationsCount() async {
    final uid = _uid;
    if (uid == null) return 0;
    try {
      final data = await _db
          .from('notifications')
          .select()
          .eq('user_id', uid)
          .eq('is_read', false);
      return (data as List).length;
    } catch (_) { return 0; }
  }

  // احذر: تعديل الفلتر لضمان عمل الإشعارات بنجاح
  static RealtimeChannel subscribeToNotifications(
    void Function(AppNotification) onNew,
  ) {
    final uid = _uid;
    return _db
        .channel('notifications_${uid ?? 'guest'}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: 'eq', // تم الإصلاح هنا أيضاً ✅
            column: 'user_id', 
            value: uid ?? ''
          ),
          callback: (payload) => onNew(AppNotification.fromMap(payload.newRecord)),
        )
        .subscribe();
  }

  // ==================== البث الجماعي (Admin) ====================

  static Future<void> broadcastMessage(String message) async {
    try {
      final users = await _db.from('profiles').select('id');
      for (final user in users as List) {
        await _db.from('notifications').insert({
          'user_id': user['id'],
          'type': 'broadcast',
          'title': 'رسالة من الإدارة',
          'body': message,
        });
      }
    } catch (e) {
      print("Broadcast error: $e");
    }
  }

  // ==================== إعدادات المستخدم ====================

  static Future<String> getUserTheme() async {
    final uid = _uid;
    if (uid == null) return 'natural_garden';
    try {
      final data = await _db
          .from('user_settings')
          .select('theme_name')
          .eq('user_id', uid)
          .single();
      return data['theme_name'] as String? ?? 'natural_garden';
    } catch (_) { return 'natural_garden'; }
  }

  static Future<void> saveUserTheme(String themeName) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db.from('user_settings').upsert({
        'user_id': uid,
        'theme_name': themeName,
      });
    } catch (e) {}
  }
}
