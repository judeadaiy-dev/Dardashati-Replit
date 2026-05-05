import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dardashati/services/supabase_service.dart';
import 'package:dardashati/services/auth_service.dart';
import 'package:dardashati/models.dart';
import 'package:dardashati/utils/logger.dart';

class DatabaseService {
  static final _db = SupabaseService.client;
  static String? get _uid => AuthService.currentUserId;

  // ==================== الغرف والمستخدمين (للرئيسية) ====================

  static Future<List<AppRoom>> getRooms() async {
    try {
      final data = await _db.from('rooms').select().order('created_at');
      return (data as List).map((r) => AppRoom.fromMap(r)).toList();
    } catch (e) {
      AppLogger.error("DB", "خطأ في جلب الغرف", e);
      return [];
    }
  }

  static Future<List<AppUser>> getUsers() async {
    try {
      final data = await _db.from('profiles').select().neq('id', _uid ?? '');
      return (data as List).map((u) => AppUser.fromMap(u)).toList();
    } catch (e) {
      AppLogger.error("DB", "خطأ في جلب المستخدمين", e);
      return [];
    }
  }

  // ==================== الرسائل الخاصة (Realtime) ====================
  
  static Future<List<AppMessage>> getPrivateMessages(String otherUserId) async {
    if (_uid == null) return [];
    try {
      final data = await _db
          .from('private_messages')
          .select('*, sender:profiles(*)')
          .or('and(sender_id.eq.$_uid,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$uid)')
          .order('created_at', ascending: true);
      
      return (data as List).map((m) => AppMessage.fromMap(m)).toList();
    } catch (e) {
      AppLogger.error("DB", "فشل جلب المحادثة الخاصة", e);
      return [];
    }
  }

  static RealtimeChannel subscribeToPrivateMessages(String otherUserId, Function(AppMessage) onNewMessage) {
    return _db.channel('private_chat_$_uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'private_messages',
          callback: (payload) {
            final record = payload.newRecord;
            // تأكد أن الرسالة تخص هذه المحادثة تحديداً
            if (record['sender_id'] == otherUserId && record['receiver_id'] == _uid) {
              onNewMessage(AppMessage.fromMap(record));
            }
          },
        )
        .subscribe();
  }

  static Future<void> sendPrivateMessage({required String receiverId, required String content, String? replyToId}) async {
    if (_uid == null) return;
    try {
      await _db.from('private_messages').insert({
        'sender_id': _uid,
        'receiver_id': receiverId,
        'content': content,
        'reply_to_id': replyToId,
      });
      AppLogger.success("CHAT", "تم إرسال الرسالة بنجاح");
    } catch (e) {
      AppLogger.error("CHAT", "فشل إرسال الرسالة", e);
    }
  }

  // ==================== الإشعارات ====================
  
  static Future<List<AppNotification>> getNotifications() async {
    if (_uid == null) return [];
    try {
      final data = await _db
          .from('notifications')
          .select()
          .eq('user_id', _uid!)
          .order('created_at', ascending: false);
      return (data as List).map((m) => AppNotification.fromMap(m)).toList();
    } catch (e) {
      AppLogger.error("NOTIF", "فشل جلب الإشعارات", e);
      return [];
    }
  }

  static Future<void> markNotificationsRead() async {
    if (_uid == null) return;
    await _db.from('notifications')
        .update({'is_read': true})
        .eq('user_id', _uid!)
        .eq('is_read', false);
  }
}
