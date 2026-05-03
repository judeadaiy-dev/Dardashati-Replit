import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../models.dart';

class DatabaseService {
  static final _db = SupabaseService.client;
  static String? get _uid => SupabaseService.currentUserId;

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
    if (_uid == null) return;
    final updates = <String, dynamic>{
      'full_name': fullName,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (zodiac != null) 'zodiac': zodiac,
      if (gender != null) 'gender': gender,
    };
    await _db.from('profiles').update(updates).eq('id', _uid!);
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
    if (_uid == null) return false;
    try {
      final data = await _db
          .from('follows')
          .select()
          .eq('follower_id', _uid!)
          .eq('following_id', targetId)
          .maybeSingle();
      return data != null;
    } catch (_) { return false; }
  }

  static Future<void> toggleFollow(String targetId) async {
    if (_uid == null) return;
    final alreadyFollowing = await isFollowing(targetId);
    if (alreadyFollowing) {
      await _db.from('follows').delete()
          .eq('follower_id', _uid!)
          .eq('following_id', targetId);
    } else {
      await _db.from('follows').insert({
        'follower_id': _uid!,
        'following_id': targetId,
      });
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

  static Future<AppRoom?> getRoomById(String id) async {
    try {
      final data = await _db.from('rooms').select().eq('id', id).single();
      return AppRoom.fromMap(data);
    } catch (_) { return null; }
  }

  static Future<int> getRoomMembersCount(String roomId) async {
    final data = await _db.from('room_members').select().eq('room_id', roomId);
    return (data as List).length;
  }

  static Future<void> joinRoom(String roomId) async {
    if (_uid == null) return;
    try {
      await _db.from('room_members').upsert({'room_id': roomId, 'user_id': _uid!});
    } catch (_) {}
  }

  static Future<void> leaveRoom(String roomId) async {
    if (_uid == null) return;
    await _db.from('room_members').delete()
        .eq('room_id', roomId)
        .eq('user_id', _uid!);
  }

  static Future<List<AppUser>> getRoomMembers(String roomId) async {
    final data = await _db
        .from('room_members')
        .select('user_id, profiles(*)')
        .eq('room_id', roomId);
    return (data as List).map((m) => AppUser.fromMap(m['profiles'])).toList();
  }

  static Future<List<AppRoom>> searchRooms(String query) async {
    final data = await _db
        .from('rooms')
        .select()
        .or('name.ilike.%$query%,description.ilike.%$query%')
        .eq('is_active', true);
    return (data as List).map((m) => AppRoom.fromMap(m)).toList();
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

  static Future<void> sendRoomMessage({
    required String roomId,
    required String content,
    String? replyToId,
  }) async {
    if (_uid == null) return;
    await _db.from('room_messages').insert({
      'room_id': roomId,
      'sender_id': _uid!,
      'content': content,
      'reply_to_id': replyToId,
    });
  }

  // الاستماع للرسائل الجديدة في الغرفة (Realtime)
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
          filter: PostgresChangeFilter(type: FilterType.eq, column: 'room_id', value: roomId),
          callback: (payload) => onInsert(payload.newRecord),
        )
        .subscribe();
  }

  // ==================== الرسائل الخاصة ====================

  static Future<List<AppMessage>> getPrivateMessages(String otherUserId) async {
    if (_uid == null) return [];
    final data = await _db
        .from('private_messages')
        .select('''
          *,
          sender:profiles!sender_id(id, full_name, avatar_url),
          reply_to:private_messages(content, sender:profiles!sender_id(full_name))
        ''')
        .or('and(sender_id.eq.$_uid,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$_uid)')
        .eq('is_deleted', false)
        .order('created_at')
        .limit(100);
    return (data as List).map((m) => AppMessage.fromMap(m)).toList();
  }

  static Future<void> sendPrivateMessage({
    required String receiverId,
    required String content,
    String? replyToId,
  }) async {
    if (_uid == null) return;
    await _db.from('private_messages').insert({
      'sender_id': _uid!,
      'receiver_id': receiverId,
      'content': content,
      'reply_to_id': replyToId,
    });
  }

  static Future<void> markPrivateMessagesRead(String senderId) async {
    if (_uid == null) return;
    await _db.from('private_messages')
        .update({'is_read': true})
        .eq('sender_id', senderId)
        .eq('receiver_id', _uid!);
  }

  // الاستماع للرسائل الخاصة الجديدة (Realtime)
  static RealtimeChannel subscribeToPrivateMessages(
    String otherUserId,
    void Function(Map<String, dynamic>) onInsert,
  ) {
    return _db
        .channel('private_messages_${_uid}_$otherUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'private_messages',
          callback: (payload) {
            final record = payload.newRecord;
            final senderId = record['sender_id'] as String?;
            final receiverId = record['receiver_id'] as String?;
            if ((senderId == otherUserId && receiverId == _uid) ||
                (senderId == _uid && receiverId == otherUserId)) {
              onInsert(record);
            }
          },
        )
        .subscribe();
  }

  // ==================== البلاغات ====================

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

  static Future<void> submitReport({
    required String targetId,
    required String reason,
  }) async {
    if (_uid == null) return;
    await _db.from('reports').insert({
      'reporter_id': _uid!,
      'target_id': targetId,
      'reason': reason,
    });
  }

  static Future<void> updateReportStatus(String reportId, String status) async {
    await _db.from('reports').update({
      'status': status,
      'resolved_by': _uid,
    }).eq('id', reportId);
  }

  // ==================== طلبات الغرف ====================

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

  static Future<void> submitRoomRequest({
    required String name,
    required String icon,
    required String description,
  }) async {
    if (_uid == null) return;
    await _db.from('room_requests').insert({
      'requester_id': _uid!,
      'name': name,
      'icon': icon,
      'description': description,
    });
  }

  static Future<void> updateRoomRequestStatus(String requestId, String status) async {
    if (status == 'approved') {
      // جلب بيانات الطلب ثم إنشاء الغرفة
      final req = await _db.from('room_requests').select().eq('id', requestId).single();
      await _db.from('rooms').insert({
        'name': req['name'],
        'icon': req['icon'],
        'description': req['description'],
        'owner_id': req['requester_id'],
      });
    }
    await _db.from('room_requests').update({
      'status': status,
      'reviewed_by': _uid,
    }).eq('id', requestId);
  }

  // ==================== الإشعارات ====================

  static Future<List<AppNotification>> getNotifications() async {
    if (_uid == null) return [];
    final data = await _db
        .from('notifications')
        .select()
        .eq('user_id', _uid!)
        .order('created_at', ascending: false)
        .limit(50);
    return (data as List).map((m) => AppNotification.fromMap(m)).toList();
  }

  static Future<void> markNotificationRead(String notificationId) async {
    await _db.from('notifications').update({'is_read': true}).eq('id', notificationId);
  }

  static Future<void> markAllNotificationsRead() async {
    if (_uid == null) return;
    await _db.from('notifications').update({'is_read': true}).eq('user_id', _uid!);
  }

  static Future<int> getUnreadNotificationsCount() async {
    if (_uid == null) return 0;
    final data = await _db
        .from('notifications')
        .select()
        .eq('user_id', _uid!)
        .eq('is_read', false);
    return (data as List).length;
  }

  // الاستماع للإشعارات الجديدة (Realtime)
  static RealtimeChannel subscribeToNotifications(
    void Function(AppNotification) onNew,
  ) {
    return _db
        .channel('notifications_$_uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(type: FilterType.eq, column: 'user_id', value: _uid ?? ''),
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

  // ==================== إعدادات المستخدم ====================

  static Future<String> getUserTheme() async {
    if (_uid == null) return 'natural_garden';
    try {
      final data = await _db
          .from('user_settings')
          .select('theme_name')
          .eq('user_id', _uid!)
          .single();
      return data['theme_name'] as String? ?? 'natural_garden';
    } catch (_) { return 'natural_garden'; }
  }

  static Future<void> saveUserTheme(String themeName) async {
    if (_uid == null) return;
    await _db.from('user_settings').upsert({
      'user_id': _uid!,
      'theme_name': themeName,
    });
  }
}
