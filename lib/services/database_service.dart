import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'auth_service.dart'; // تأكد من استيراد ملف الأصالة
import '../models.dart';

class DatabaseService {
  static final _db = SupabaseService.client;
  
  // تحديث مصدر المعرف ليكون من AuthService المصلح
  static String? get _uid => AuthService.currentUserId;

  // ==================== المستخدمون ====================

  static Future<List<AppUser>> getUsers() async {
    final data = await _db.from('profiles').select().order('created_at');
    return (data as List).map((m) => AppUser.fromMap(m)).toList();
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

  static Future<List<AppUser>> searchUsers(String query) async {
    final data = await _db
        .from('profiles')
        .select()
        .ilike('full_name', '%$query%')
        .limit(30);
    return (data as List).map((m) => AppUser.fromMap(m)).toList();
  }

  // ==================== المتابعات ====================

  static Future<bool> isFollowing(String targetId) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      final data = await _db
          .from('follows')
          .select()
          .eq('follower_id', uid)
          .eq('following_id', targetId)
          .maybeSingle();
      return data != null;
    } catch (_) { return false; }
  }

  static Future<void> toggleFollow(String targetId) async {
    final uid = _uid;
    if (uid == null) return;
    final alreadyFollowing = await isFollowing(targetId);
    if (alreadyFollowing) {
      await _db.from('follows').delete()
          .eq('follower_id', uid)
          .eq('following_id', targetId);
    } else {
      await _db.from('follows').insert({
        'follower_id': uid,
        'following_id': targetId,
      });
    }
  }

  static Future<int> getFollowersCount(String userId) async {
    final data = await _db.from('follows').select().eq('following_id', userId);
    return (data as List).length;
  }

  // ==================== الغرف ====================

  static Future<List<AppRoom>> getRooms() async {
    final data = await _db
        .from('rooms')
        .select()
        .eq('is_active', true)
        .order('is_featured', ascending: false)
        .order('created_at');
    return (data as List).map((m) => AppRoom.fromMap(m)).toList();
  }

  static Future<void> joinRoom(String roomId) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db.from('room_members').upsert({'room_id': roomId, 'user_id': uid});
    } catch (_) {}
  }

  static Future<void> leaveRoom(String roomId) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.from('room_members').delete()
        .eq('room_id', roomId)
        .eq('user_id', uid);
  }

  static Future<List<AppUser>> getRoomMembers(String roomId) async {
    final data = await _db
        .from('room_members')
        .select('user_id, profiles(*)')
        .eq('room_id', roomId);
    return (data as List).map((m) => AppUser.fromMap(m['profiles'])).toList();
  }

  // ==================== رسائل الغرف ====================

  static Future<List<AppMessage>> getRoomMessages(String roomId) async {
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
  }

  // الاستماع للرسائل الجديدة في الغرفة (تم إصلاح الفلتر هنا) ✅
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
            type: 'eq', // تم تحويلها لنص
            column: 'room_id', 
            value: roomId
          ),
          callback: (payload) => onInsert(payload.newRecord),
        )
        .subscribe();
  }

  // ==================== الرسائل الخاصة ====================

  static Future<List<AppMessage>> getPrivateMessages(String otherUserId) async {
    final uid = _uid;
    if (uid == null) return [];
    final data = await _db
        .from('private_messages')
        .select('''
          *,
          sender:profiles!sender_id(id, full_name, avatar_url),
          reply_to:private_messages(content, sender:profiles!sender_id(full_name))
        ''')
        .or('and(sender_id.eq.$uid,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$uid)')
        .eq('is_deleted', false)
        .order('created_at')
        .limit(100);
    return (data as List).map((m) => AppMessage.fromMap(m)).toList();
  }

  // ==================== البلاغات وطلبات الغرف ====================

  static Future<List<AppReport>> getReports() async {
    final data = await _db
        .from('reports')
        .select('''
          *,
          reporter:profiles!reporter_id(full_name, avatar_url),
          target:profiles!target_id(full_name, avatar_url)
        ''')
        .order('created_at', ascending: false);
    return (data as List).map((m) => AppReport.fromMap(m)).toList();
  }

  static Future<List<AppRoomRequest>> getRoomRequests() async {
    final data = await _db
        .from('room_requests')
        .select('''
          *,
          requester:profiles!requester_id(full_name, avatar_url)
        ''')
        .order('created_at', ascending: false);
    return (data as List).map((m) => AppRoomRequest.fromMap(m)).toList();
  }

  // ==================== الإشعارات (تم إصلاح الفلتر هنا أيضاً) ✅ ====================

  static Future<int> getUnreadNotificationsCount() async {
    final uid = _uid;
    if (uid == null) return 0;
    final data = await _db
        .from('notifications')
        .select()
        .eq('user_id', uid)
        .eq('is_read', false);
    return (data as List).length;
  }

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
            type: 'eq', // تم تحويلها لنص لإزالة الخطأ
            column: 'user_id', 
            value: uid ?? ''
          ),
          callback: (payload) => onNew(AppNotification.fromMap(payload.newRecord)),
        )
        .subscribe();
  }

  // ==================== البث الجماعي (Admin) ====================

  static Future<void> broadcastMessage(String message) async {
    final users = await _db.from('profiles').select('id');
    for (final user in users as List) {
      await _db.from('notifications').insert({
        'user_id': user['id'],
        'type': 'broadcast',
        'title': 'رسالة من الإدارة',
        'body': message,
      });
    }
  }

  // ==================== إعدادات الثيم ====================

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
    await _db.from('user_settings').upsert({
      'user_id': uid,
      'theme_name': themeName,
    });
  }
}
