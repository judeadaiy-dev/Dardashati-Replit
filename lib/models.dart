dart
class AppThemeData {
  final String name;
  final String label;  // ✅ ADD THIS
  final Color primaryColor;  // ✅ ADD THIS
  final List<Color> gradientColors;  // ✅ ADD THIS
  final Color background;
  final Color text;   
  final Color button; 
  final Color card;
  final Color accent;  // ✅ ADD THIS
  final Color menu;        
  final Color buttonText;  
  final bool isDark;       
  final double borderRadius;

  AppThemeData({
    required this.name,
    required this.label,  // ✅ ADD THIS
    required this.primaryColor,  // ✅ ADD THIS
    required this.gradientColors,  // ✅ ADD THIS
    required this.background,
    required this.text,    
    required this.button,  
    required this.card,
    required this.accent,  // ✅ ADD THIS
    required this.menu,
    required this.buttonText,
    required this.isDark,
    this.borderRadius = 40.0,
  });

  static AppThemeData dark() => AppThemeData(
    name: 'dark',
    label: 'الوضع الداكن',  // ✅ ADD THIS
    primaryColor: const Color(0xFF38BDF8),  // ✅ ADD THIS
    gradientColors: [const Color(0xFF0F172A), const Color(0xFF1E293B)],  // ✅ ADD THIS
    background: const Color(0xFF0F172A),
    text: Colors.white,
    button: const Color(0xFF38BDF8),
    card: const Color(0xFF1E293B),
    accent: const Color(0xFF38BDF8),  // ✅ ADD THIS
    menu: const Color(0xFF1E293B),
    buttonText: Colors.white,
    isDark: true,
  );
}
```

Also add this immutable property to `AppNotification` class (after line 86):
```dart
class AppNotification {
  final String id;
  final String title;
  final String body;
  final IconData icon;
  bool isRead;  // ✅ CHANGE FROM final TO mutable (remove final)
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.icon,
    required this.isRead,
    required this.createdAt,
  });
  // ... rest of the code stays the same
}
```

---

### **2. lib/services/database_service.dart** - Add missing methods and fix variable
Replace the entire file with:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dardashati/services/supabase_service.dart';
import 'package:dardashati/services/auth_service.dart';
import 'package:dardashati/models.dart';
import 'package:dardashati/utils/logger.dart';

class AppRoom {  // ✅ ADD THIS CLASS
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;

  AppRoom({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  factory AppRoom.fromMap(Map<String, dynamic> map) {
    return AppRoom(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'غرفة جديدة',
      description: map['description']?.toString(),
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

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
          .or('and(sender_id.eq.$_uid,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$_uid)')  // ✅ FIXED: $uid -> $_uid
          .order('created_at', ascending: true);
      
      return (data as List).map((m) => AppMessage.fromMap(m)).toList();
    } catch (e) {
      AppLogger.error("DB", "فشل جلب المحادثة الخاصة", e);
      return [];
    }
  }

  // ✅ ADD THIS METHOD
  static Stream<List<Map<String, dynamic>>> getMessagesStream(String otherUserId) {
    if (_uid == null) return Stream.value([]);
    return _db
        .from('private_messages')
        .stream(primaryKey: ['id'])
        .eq('sender_id', _uid!)
        .or('receiver_id.eq.$otherUserId')
        .order('created_at')
        .map((event) => List<Map<String, dynamic>>.from(event));
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

  // ✅ ADD THIS METHOD
  static Future<void> sendMessage(String otherUserId, String content) async {
    await sendPrivateMessage(receiverId: otherUserId, content: content);
  }

  // ✅ ADD THIS METHOD
  static Future<void> markPrivateMessagesRead(String otherUserId) async {
    if (_uid == null) return;
    try {
      await _db.from('private_messages')
          .update({'is_read': true})
          .eq('receiver_id', _uid!)
          .eq('sender_id', otherUserId);
      AppLogger.success("CHAT", "تم تحديث حالة القراءة");
    } catch (e) {
      AppLogger.error("CHAT", "فشل تحديث حالة القراءة", e);
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

  // ✅ ADD THIS METHOD
  static Future<void> markAllNotificationsRead() async {
    await markNotificationsRead();
  }

  // ✅ ADD THIS METHOD
  static Future<void> markNotificationRead(String notificationId) async {
    if (_uid == null) return;
    try {
      await _db.from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      AppLogger.error("NOTIF", "فشل تحديث الإشعار", e);
    }
  }

  // ✅ ADD THIS METHOD
  static Future<AppUser?> getUserById(String userId) async {
    try {
      final data = await _db.from('profiles').select().eq('id', userId).single();
      return AppUser.fromMap(data as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error("DB", "فشل جلب بيانات المستخدم", e);
      return null;
    }
  }

  // ✅ ADD THIS METHOD
  static Future<void> submitReport({required String targetId, required String reason}) async {
    if (_uid == null) return;
    try {
      await _db.from('reports').insert({
        'reporter_id': _uid,
        'reported_id': targetId,
        'reason': reason,
        'created_at': DateTime.now().toIso8601String(),
      });
      AppLogger.success("REPORT", "تم إرسال البلاغ بنجاح");
    } catch (e) {
      AppLogger.error("REPORT", "فشل إرسال البلاغ", e);
      rethrow;
    }
  }

  // ✅ ADD THIS METHOD
  static Future<void> signInWithGoogle() async {
    try {
      await AuthService.signInWithGoogle();
      AppLogger.success("AUTH", "تم تسجيل الدخول بنجاح");
    } catch (e) {
      AppLogger.error("AUTH", "فشل تسجيل الدخول", e);
      rethrow;
    }
  }
}
