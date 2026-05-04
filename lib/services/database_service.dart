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
    try {
      final res = await _db.from('follows').select('follower_id', const FetchOptions(count: CountOption.exact)).eq('following_id', userId);
      return res.count;
    } catch (_) { return 0; }
  }

  static Future<int> getFollowingCount(String userId) async {
    try {
      final res = await _db.from('follows').select('following_id', const FetchOptions(count: CountOption.exact)).eq('follower_id', userId);
      return res.count;
    } catch (_) { return 0; }
  }

  // ==================== الغرف (Rooms) ====================
  static Future<List<AppRoom>> getRooms() async {
    final data = await _db.from('rooms').select().eq('is_active', true).order('is_featured', ascending: false);
    return (data as List).map((m) => AppRoom.fromMap(m)).toList();
  }

  static Future<List<AppRoom>> searchRooms(String query) async {
    final data = await _db.from('rooms').select().ilike('name', '%$query%').limit(30);
    return (data as List).map((m) => AppRoom.fromMap(m)).toList();
  }

  // دالة جلب طلبات الغرف الجديدة للوحة الإدارة
  static Future<List<AppRoomRequest>> getRoomRequests() async {
    final data = await _db.from('room_requests').select().order('created_at', ascending: false);
    return (data as List).map((m) => AppRoomRequest.fromMap(m)).toList();
  }

  static Future<void> joinRoom(String roomId) async {
    if (_uid == null) return;
    await _db.from('room_members').upsert({'room_id': roomId, 'user_id': _uid!});
  }

  // ==================== الرسائل (Messages) ====================
  static Future<List<AppMessage>> getRoomMessages(String roomId) async {
    final data = await _db.from('room_messages').select('*, sender:profiles(*)').eq('room_id', roomId).order('created_at', ascending: true);
    return (data as List).map((m) => AppMessage.fromMap(m)).toList();
  }

  static RealtimeChannel subscribeToRoomMessages(String roomId, Function(Map) onInsert) {
    return _db.channel('room_$roomId').onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'room_messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq, 
        column: 'room_id', 
        value: roomId
      ),
      callback: (payload) => onInsert(payload.newRecord),
    ).subscribe();
  }

  // ==================== الإشعارات والثيم ====================
  static Future<String> getUserTheme() async {
    const String defaultTheme = 'dardashati_wave';
    if (_uid == null) return defaultTheme;
    try {
      final data = await _db.from('user_settings').select('theme_name').eq('user_id', _uid!).single();
      return data['theme_name'] as String? ?? defaultTheme;
    } catch (_) { return defaultTheme; }
  }

  static Future<void> saveUserTheme(String themeName) async {
    if (_uid == null) return;
    await _db.from('user_settings').upsert({'user_id': _uid!, 'theme_name': themeName});
  }

  // ==================== الإدارة والتقارير ====================
  
  // دالة جلب كافة البلاغات للوحة الإدارة (تم إصلاح الخطأ هنا)
  static Future<List<AppReport>> getReports() async {
    final data = await _db.from('reports').select().order('created_at', ascending: false);
    return (data as List).map((m) => AppReport.fromMap(m)).toList();
  }

  static Future<void> submitReport({required String targetId, required String reason}) async {
    if (_uid == null) return;
    await _db.from('reports').insert({
      'reporter_id': _uid!, 
      'target_id': targetId, 
      'reason': reason,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> updateReportStatus(String reportId, String status) async {
    await _db.from('reports').update({'status': status}).eq('id', reportId);
  }
}

