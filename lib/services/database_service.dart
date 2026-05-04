import 'package:supabase_flutter/supabase_flutter.dart';
// إضافة هذا الاستيراد لضمان التعرف على أنواع الفلاتر
import 'package:supabase_flutter/src/realtime_client_ext.dart'; 
import 'supabase_service.dart';
import 'auth_service.dart';
import '../models.dart';

class DatabaseService {
  static final _db = SupabaseService.client;
  static String? get _uid => AuthService.currentUserId;

  // ==================== المستخدمون والغرف ====================

  static Future<List<AppUser>> getUsers() async {
    final data = await _db.from('profiles').select().order('created_at');
    return (data as List).map((m) => AppUser.fromMap(m)).toList();
  }

  static Future<List<AppRoom>> getRooms() async {
    final data = await _db.from('rooms').select().eq('is_active', true).order('is_featured', ascending: false);
    return (data as List).map((m) => AppRoom.fromMap(m)).toList();
  }

  static Future<void> joinRoom(String roomId) async {
    if (_uid == null) return;
    await _db.from('room_members').upsert({'room_id': roomId, 'user_id': _uid!});
  }

  static Future<List<AppUser>> getRoomMembers(String roomId) async {
    final data = await _db.from('room_members').select('profiles(*)').eq('room_id', roomId);
    return (data as List).map((m) => AppUser.fromMap(m['profiles'])).toList();
  }

  static Future<List<AppRoom>> searchRooms(String query) async {
    final data = await _db.from('rooms').select().ilike('name', '%$query%').eq('is_active', true);
    return (data as List).map((m) => AppRoom.fromMap(m)).toList();
  }

  // ==================== الرسائل والإشعارات ====================

  static Future<List<AppMessage>> getRoomMessages(String roomId) async {
    final data = await _db.from('room_messages').select('*, sender:profiles(*)').eq('room_id', roomId).eq('is_deleted', false).order('created_at').limit(100);
    return (data as List).map((m) => AppMessage.fromMap(m)).toList();
  }

  static Future<void> sendRoomMessage({required String roomId, required String content, String? replyToId}) async {
    if (_uid == null) return;
    await _db.from('room_messages').insert({'room_id': roomId, 'sender_id': _uid!, 'content': content, 'reply_to_id': replyToId});
  }

  static RealtimeChannel subscribeToRoomMessages(String roomId, void Function(Map<String, dynamic>) onInsert) {
    return _db.channel('room_messages_$roomId').onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'room_messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq, // استخدام الـ Enum مباشرة
        column: 'room_id',
        value: roomId,
      ),
      callback: (payload) => onInsert(payload.newRecord),
    ).subscribe();
  }

  static Future<int> getUnreadNotificationsCount() async {
    if (_uid == null) return 0;
    final data = await _db.from('notifications').select().eq('user_id', _uid!).eq('is_read', false);
    return (data as List).length;
  }

  static RealtimeChannel subscribeToNotifications(void Function(AppNotification) onNew) {
    return _db.channel('notif_$_uid').onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq, 
        column: 'user_id',
        value: _uid ?? '',
      ),
      callback: (payload) => onNew(AppNotification.fromMap(payload.newRecord)),
    ).subscribe();
  }

  // ==================== الإعدادات والثيم ====================

  static Future<String> getUserTheme() async {
    if (_uid == null) return 'natural_garden';
    try {
      final data = await _db.from('user_settings').select('theme_name').eq('user_id', _uid!).single();
      return data['theme_name'] as String? ?? 'natural_garden';
    } catch (_) { return 'natural_garden'; }
  }

  static Future<void> saveUserTheme(String themeName) async {
    if (_uid == null) return;
    await _db.from('user_settings').upsert({'user_id': _uid!, 'theme_name': themeName});
  }

  // ==================== الإدارة ====================

  static Future<void> broadcastMessage(String message) async {
    final users = await _db.from('profiles').select('id');
    for (final user in users as List) {
      await _db.from('notifications').insert({'user_id': user['id'], 'type': 'broadcast', 'title': 'إدارة دردشاتي', 'body': message});
    }
  }

  static Future<List<AppReport>> getReports() async {
    final data = await _db.from('reports').select('*, reporter:profiles!reporter_id(*), target:profiles!target_id(*)');
    return (data as List).map((m) => AppReport.fromMap(m)).toList();
  }

  static Future<List<AppRoomRequest>> getRoomRequests() async {
    final data = await _db.from('room_requests').select('*, requester:profiles(*)');
    return (data as List).map((m) => AppRoomRequest.fromMap(m)).toList();
  }

  static Future<void> updateRoomRequestStatus(String id, String status) async {
    await _db.from('room_requests').update({'status': status}).eq('id', id);
  }

  static Future<void> updateReportStatus(String id, String status) async {
    await _db.from('reports').update({'status': status}).eq('id', id);
  }
}
