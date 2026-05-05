import 'package:flutter/material.dart'; // حرف i صغير هنا

// ==================== Enums ====================
enum IconStyle { minimal, bold, soft }
enum FilterType { all, online, banned, pending }

// ==================== Models ====================

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
      senderName: map['user_name']?.toString(),
      senderAvatar: map['avatar_url']?.toString(),
      replyToId: map['reply_to_id']?.toString(),
    );
  }
}

class AppUser {
  final String id;
  final String fullName;
  final String email; 
  final String avatarUrl;
  final bool isOnline;
  final String? bio;
  final String role; 
  final bool isBanned;
  final String themePreference;

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
      id: map['id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? 'مستخدم جديد',
      email: map['email']?.toString() ?? '', 
      avatarUrl: map['avatar_url']?.toString() ?? '',
      isOnline: map['is_online'] ?? false,
      bio: map['bio']?.toString(),
      role: map['role']?.toString() ?? 'user',
      isBanned: map['is_banned'] ?? false,
      themePreference: map['theme_preference']?.toString() ?? 'dark',
    );
  }

  bool get isAdmin => role == 'admin';
}

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
      title: map['title']?.toString() ?? 'إشعار جديد',
      body: map['body']?.toString() ?? '',
      isRead: map['is_read'] ?? false,
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      icon: _getIconForType(map['type']?.toString()),
    );
  }

  static IconData _getIconForType(String? type) {
    switch (type) {
      case 'message': return Icons.chat_bubble_outline;
      case 'system': return Icons.info_outline;
      case 'alert': return Icons.warning_amber_rounded;
      default: return Icons.notifications_none;
    }
  }
}

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
      id: map['id']?.toString() ?? '',
      reporterId: map['reporter_id']?.toString() ?? '',
      reportedId: map['reported_id']?.toString() ?? '',
      reason: map['reason']?.toString() ?? '',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
