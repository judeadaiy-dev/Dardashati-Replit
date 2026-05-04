import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'auth_service.dart';
import '../models.dart';

class DatabaseService {
  static final _db = SupabaseService.client;
  static String? get _uid => AuthService.currentUserId;

  // ==================== المستخدمون (Profiles) ====================
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

  static Future<void> updateProfile({required String fullName, String? bio, String? avatarUrl}) async {
    if (_uid == null) return;
    await _db.from('profiles').update({
      'full_name': fullName,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    }).eq('id', _uid!);
  }

  static Future<void> banUser(String userId, bool ban) async {
    await _db.from('profiles').update({'is_banned': ban}).eq('id', userId);
  }

  static Future<List<AppUser>> searchUsers(String query) async {
    final data = await _db.from('profiles').select().ilike('full_name', '%$query%').limit(30);
    return (data as List).map((m) => AppUser.fromMap(m)).toList();
  }

  // ==================== المتابعات (Follows) ====================
  static Future<bool> isFollowing(String targetId) async {
    if (_uid == null) return false;
    final data = await _db.from('follows').select().eq('follower_id', _uid!).eq('following_id', targetId).maybeSingle();
    return data != null;
  }

  static Future<void> toggleFollow(String targetId) async {
    if (_uid == null) return;
    final following = await isFollowing(targetId);
    if (following) {
      await _db.from('follows').delete().eq('follower_id', _uid!).eq('following_id', targetId);
    } else {
      await _db.from('follows').insert({'follower_id': _uid!, 'following_id': targetId});
    }
  }

  static Future<int> getFollowersCount(String userId) async {
    final data = await _db.from('follows').select().eq('following_id', userId);
    return (data as List).length;
  }

  static Future<int> getFollowingCount(String userId) async {
    final data = await _db.from('follows').select().eq('follower_id', userId);
    return (data as List).length;
  }

  // ==================== الغرف (Rooms) ====================
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

  // ==================== الرسائل (Messages) ====================
  static Future<void> sendRoomMessage({required String roomId, required String content, String? replyToId}) async {
    if (_uid == null) return;
    await _db.from('room_messages').insert({
      'room_id': roomId,
      'sender_id': _uid!,
      'content': content,
      'reply_to_id': replyToId,
    });
  }

  static Future<List<AppMessage>> getRoomMessages(String roomId) async {
    final data = await _db.from('room_messages').select('*, sender:profiles(*)').eq('room_id', roomId).order('created_at');
    return (data as List).map((m) => AppMessage.fromMap(m)).toList();
  }

  static RealtimeChannel subscribeToRoomMessages(String roomId, Function(Map) onInsert) {
    return _db.channel('room_$roomId').onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'room_messages',
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'room_id', value: roomId),
      callback: (payload) => onInsert(payload.newRecord),
    ).subscribe();
  }

  static Future<List<AppMessage>> getPrivateMessages(String otherId) async {
    if (_uid == null) return [];
    final data = await _db.from('private_messages').select('*, sender:profiles(*)').or('and(sender_id.eq.$_uid,receiver_id.eq.$otherId),and(sender_id.eq.$otherId,receiver_id.eq.$_uid)').order('created_at');
    return (data as List).map((m) => AppMessage.fromMap(m)).toList();
  }

  static Future<void> sendPrivateMessage({required String receiverId, required String content, String? replyToId}) async {
    if (_uid == null) return;
    await _db.from('private_messages').insert({'sender_id': _uid!, 'receiver_id': receiverId, 'content': content, 'reply_to_id': replyToId});
  }

  static Future<void> markPrivateMessagesRead(String otherId) async {
    if (_uid == null) return;
    await _db.from('private_messages').update({'is_read': true}).eq('sender_id', otherId).eq('receiver_id', _uid!);
  }

  static RealtimeChannel subscribeToPrivateMessages(String otherId, Function(Map) onInsert) {
    return _db.channel('pvt_$otherId').onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'private_messages',
      callback: (payload) => onInsert(payload.newRecord),
    ).subscribe();
  }

  // ==================== الإشعارات والثيم ====================
  static Future<List<AppNotification>> getNotifications() async {
    if (_uid == null) return [];
    final data = await _db.from('notifications').select().eq('user_id', _uid!).order('created_at', ascending: false);
    return (data as List).map((m) => AppNotification.fromMap(m)).toList();
  }

  static Future<int> getUnreadNotificationsCount() async {
    if (_uid == null) return 0;
    final data = await _db.from('notifications').select().eq('user_id', _uid!).eq('is_read', false);
    return (data as List).length;
  }

  static Future<void> markAllNotificationsRead() async {
    if (_uid == null) return;
    await _db.from('notifications').update({'is_read': true}).eq('user_id', _uid!);
  }

  static Future<void> markNotificationRead(String id) async {
    await _db.from('notifications').update({'is_read': true}).eq('id', id);
  }

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

  // ==================== الإدارة (Admin) ====================
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

  static Future<void> submitReport({required String targetId, required String reason}) async {
    if (_uid == null) return;
    await _db.from('reports').insert({'reporter_id': _uid!, 'target_id': targetId, 'reason': reason});
  }
}
