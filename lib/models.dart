import 'package:flutter/material.dart';

// ==================== Enums ====================
enum IconStyle { minimal, bold, soft }
enum FilterType { all, online, banned, pending }

// ==================== Models ====================

// --- 1. كلاس الرسائل ---
class AppMessage {
  final String id;
  final String senderId;
  final String content;
  final DateTime time;
  final String? senderName;
  final String? senderAvatar;
  final String? replyToId;

  AppMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.time,
    this.senderName,
    this.senderAvatar,
    this.replyToId,
  });

  factory AppMessage.fromMap(Map<String, dynamic> map) {
    return AppMessage(
      id: map['id']?.toString() ?? '',
      senderId: map['user_id']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      time: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      senderName: map['user_name'],
      senderAvatar: map['avatar_url'],
      replyToId: map['reply_to_id'],
    );
  }
}

// --- 2. كلاس المستخدم (تم تحديثه ليدعم الثيم) ---
class AppUser {
  final String id;
  final String fullName;
  final String email; 
  final String avatarUrl;
  final bool isOnline;
  final String? bio;
  final String role; 
  final bool isBanned;
  final String themePreference; // أضفنا هذا لربطه مع شاشة الإعدادات

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.avatarUrl,
    this.isOnline = false,
    this.bio,
    this.role = 'user',
    this.isBanned = false,
    this.themePreference = 'dark',
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      fullName: map['full_name'] ?? 'مستخدم جديد',
      email: map['email'] ?? '', 
      avatarUrl: map['avatar_url'] ?? '',
      isOnline: map['is_online'] ?? false,
      bio: map['bio'],
      role: map['role'] ?? 'user',
      isBanned: map['is_banned'] ?? false,
      themePreference: map['theme_preference'] ?? 'dark',
    );
  }

  bool get isAdmin => role == 'admin';
}

// --- 3. كلاس الإشعارات (هذا ما كان ينقص البناء!) ---
class AppNotification {
  final String id;
  final String title;
  final String body;
  final IconData icon;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.icon,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? 'إشعار جديد',
      body: map['body'] ?? '',
      isRead: map['is_read'] ?? false,
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      icon: _getIconForType(map['type']),
    );
  }

  static IconData _getIconForType(String? type) {
    switch (type) {
      case 'message': return Icons.chat_bubble_outline;
      case 'system': return Icons.info_outline;
      default: return Icons.notifications_none;
    }
  }
}

// --- 4. كلاس الثيم ---
class AppThemeData {
  final String name;
  final Color background;
  final Color text;   
  final Color button; 
  final Color card;
  final Color menu;        
  final Color buttonText;  
  final bool isDark;       
  final double borderRadius;

  AppThemeData({
    required this.name,
    required this.background,
    required this.text,    
    required this.button,  
    required this.card,
    required this.menu,
    required this.buttonText,
    required this.isDark,
    this.borderRadius = 40.0,
  });

  static AppThemeData dark() => AppThemeData(
    name: 'dark',
    background: const Color(0xFF0F172A),
    text: Colors.white,
    button: const Color(0xFF38BDF8),
    card: const Color(0xFF1E293B),
    menu: const Color(0xFF1E293B),
    buttonText: Colors.white,
    isDark: true,
  );
}

// --- 5. كلاس البلاغات ---
class AppReport {
  final String id;
  final String reporterId;
  final String reportedId;
  final String reason;
  final DateTime createdAt;

  AppReport({
    required this.id,
    required this.reporterId,
    required this.reportedId,
    required this.reason,
    required this.createdAt,
  });

  factory AppReport.fromMap(Map<String, dynamic> map) {
    return AppReport(
      id: map['id'] ?? '',
      reporterId: map['reporter_id'] ?? '',
      reportedId: map['reported_id'] ?? '',
      reason: map['reason'] ?? '',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
