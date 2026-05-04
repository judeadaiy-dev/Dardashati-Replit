import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'auth_service.dart';
import '../models.dart';

class DatabaseService {
  static final _db = SupabaseService.client;
  static String? get _uid => AuthService.currentUserId;

  // ... (الأكواد السابقة الخاصة بالمستخدمين والمتابعات والغرف تبقى كما هي) ...

  // ==================== الرسائل العامة والخاصة ====================
  
  // دالة جلب الرسائل الخاصة
  static Future<List<AppMessage>> getPrivateMessages(String otherUserId) async {
    if (_uid == null) return [];
    final data = await _db
        .from('private_messages')
        .select('*, sender:profiles(*)')
        .or('and(sender_id.eq.$_uid,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$_uid)')
        .order('created_at', ascending: true);
    return (data as List).map((m) => AppMessage.fromMap(m)).toList();
  }

  // --- الدالة التي كانت مفقودة وتسببت في الخطأ (الحل الاحترافي) ---
  static RealtimeChannel subscribeToPrivateMessages(String otherUserId, Function(Map) onInsert) {
    return _db.channel('private_chat_$_uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'private_messages',
          // نراقب الرسائل التي يكون فيها المستخدم الحالي هو المستلم والمرسل هو الطرف الآخر
          callback: (payload) {
            final newRecord = payload.newRecord;
            if (newRecord['sender_id'] == otherUserId && newRecord['receiver_id'] == _uid) {
              onInsert(newRecord);
            }
          },
        )
        .subscribe();
  }

  static Future<void> sendPrivateMessage({required String receiverId, required String content, String? replyToId}) async {
    if (_uid == null) return;
    await _db.from('private_messages').insert({
      'sender_id': _uid,
      'receiver_id': receiverId,
      'content': content,
      'reply_to_id': replyToId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> markPrivateMessagesRead(String otherUserId) async {
    if (_uid == null) return;
    await _db.from('private_messages')
        .update({'is_read': true})
        .eq('receiver_id', _uid!)
        .eq('sender_id', otherUserId)
        .eq('is_read', false); // تحديث غير المقروء فقط لتقليل استهلاك الداتابيز
  }

  // ==================== الإشعارات ====================
  
  // تحسين جلب الإشعارات ليتوافق مع المودل الجديد
  static Future<List<AppNotification>> getNotifications() async {
    if (_uid == null) return [];
    final data = await _db
        .from('notifications')
        .select()
        .eq('user_id', _uid!)
        .order('created_at', ascending: false);
    return (data as List).map((m) => AppNotification.fromMap(m)).toList();
  }

  // ... (باقي الدوال تبقى كما هي) ...
}
