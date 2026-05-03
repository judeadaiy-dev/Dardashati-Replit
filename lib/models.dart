import 'package:flutter/material.dart';

// ==================== Enums ====================
enum IconStyle { minimal, bold, soft }

// ==================== Models ====================

class AppUser {
  final String id;
  final String fullName;
  final String avatarUrl;
  final bool isOnline;
  final String? zodiac;
  final String? gender;
  final String? bio;
  final bool isBanned;
  final String role; // 'user', 'admin', 'moderator'
  int followersCount;
  int followingCount;

  AppUser({
    required this.id,
    required this.fullName,
    required this.avatarUrl,
    this.isOnline = false,
    this.zodiac,
    this.gender,
    this.bio,
    this.isBanned = false,
    this.role = 'user',
    this.followersCount = 0,
    this.followingCount = 0,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      fullName: map['full_name'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String? ?? '',
      isOnline: map['is_online'] as bool? ?? false,
      zodiac: map['zodiac'] as String?,
      gender: map['gender'] as String?,
      bio: map['bio'] as String?,
      isBanned: map['is_banned'] as bool? ?? false,
      role: map['role'] as String? ?? 'user',
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isModerator => role == 'moderator' || role == 'admin';
}

class AppRoom {
  final String id;
  final String name;
  final String icon;
  final String description;
  final String ownerId;
  final bool isFeatured;
  final int membersCount;

  AppRoom({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.ownerId,
    this.isFeatured = false,
    this.membersCount = 0,
  });

  factory AppRoom.fromMap(Map<String, dynamic> map) {
    return AppRoom(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      icon: map['icon'] as String? ?? '💬',
      description: map['description'] as String? ?? '',
      ownerId: map['owner_id'] as String? ?? '',
      isFeatured: map['is_featured'] as bool? ?? false,
    );
  }

  String get membersCountLabel {
    if (membersCount >= 1000) return '${(membersCount / 1000).toStringAsFixed(1)}k عضو';
    return '$membersCount عضو';
  }
}

class AppMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String content;
  final DateTime time;
  final bool isAudio;
  final String? audioDuration;
  final String? replyToContent;
  final String? replyToSender;

  AppMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.content,
    required this.time,
    this.isAudio = false,
    this.audioDuration,
    this.replyToContent,
    this.replyToSender,
  });

  factory AppMessage.fromMap(Map<String, dynamic> map) {
    final sender = map['sender'] as Map<String, dynamic>?;
    final replyTo = map['reply_to'] as Map<String, dynamic>?;
    final replySender = replyTo?['sender'] as Map<String, dynamic>?;
    return AppMessage(
      id: map['id'] as String,
      senderId: map['sender_id'] as String? ?? '',
      senderName: sender?['full_name'] as String? ?? '',
      senderAvatar: sender?['avatar_url'] as String? ?? '',
      content: map['content'] as String? ?? '',
      time: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      isAudio: map['is_audio'] as bool? ?? false,
      audioDuration: map['audio_duration'] as String?,
      replyToContent: replyTo?['content'] as String?,
      replyToSender: replySender?['full_name'] as String?,
    );
  }

  String get formattedTime {
    final h = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final m = time.minute.toString().padLeft(2, '0');
    final p = time.hour >= 12 ? 'م' : 'ص';
    return '$h:$m $p';
  }
}

class AppRoomRequest {
  final String id;
  final String requesterId;
  final String requesterName;
  final String name;
  final String icon;
  final String description;
  String status;

  AppRoomRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.name,
    required this.icon,
    required this.description,
    required this.status,
  });

  factory AppRoomRequest.fromMap(Map<String, dynamic> map) {
    final requester = map['requester'] as Map<String, dynamic>?;
    return AppRoomRequest(
      id: map['id'] as String,
      requesterId: map['requester_id'] as String? ?? '',
      requesterName: requester?['full_name'] as String? ?? '',
      name: map['name'] as String? ?? '',
      icon: map['icon'] as String? ?? '💬',
      description: map['description'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
    );
  }
}

class AppReport {
  final String id;
  final String reporterId;
  final String reporterName;
  final String targetId;
  final String targetName;
  final String reason;
  final DateTime timestamp;
  String status;

  AppReport({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.targetId,
    required this.targetName,
    required this.reason,
    required this.timestamp,
    required this.status,
  });

  factory AppReport.fromMap(Map<String, dynamic> map) {
    final reporter = map['reporter'] as Map<String, dynamic>?;
    final target = map['target'] as Map<String, dynamic>?;
    return AppReport(
      id: map['id'] as String,
      reporterId: map['reporter_id'] as String? ?? '',
      reporterName: reporter?['full_name'] as String? ?? 'مجهول',
      targetId: map['target_id'] as String? ?? '',
      targetName: target?['full_name'] as String? ?? 'مجهول',
      reason: map['reason'] as String? ?? '',
      timestamp: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      status: map['status'] as String? ?? 'pending',
    );
  }
}

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic> data;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.data = const {},
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      type: map['type'] as String? ?? 'system',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      isRead: map['is_read'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      data: (map['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  IconData get icon {
    switch (type) {
      case 'follow': return Icons.person_add_rounded;
      case 'message': return Icons.chat_bubble_rounded;
      case 'room_request': return Icons.room_preferences_rounded;
      case 'report': return Icons.flag_rounded;
      case 'broadcast': return Icons.campaign_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color iconColor(Color accent) {
    switch (type) {
      case 'follow': return Colors.blue;
      case 'message': return Colors.green;
      case 'room_request': return Colors.orange;
      case 'report': return Colors.red;
      case 'broadcast': return Colors.purple;
      default: return accent;
    }
  }
}

// ==================== Theme ====================

class AppThemeData {
  final String name;
  final String label;
  final Color background;
  final Color text;
  final Color button;
  final Color buttonText;
  final Color accent;
  final Color card;
  final Color menu;
  final String fontFamily;
  final IconStyle iconStyle;
  final bool isDark;

  AppThemeData({
    required this.name,
    required this.label,
    required this.background,
    required this.text,
    required this.button,
    required this.buttonText,
    required this.accent,
    required this.card,
    required this.menu,
    required this.fontFamily,
    required this.iconStyle,
    required this.isDark,
  });
}
