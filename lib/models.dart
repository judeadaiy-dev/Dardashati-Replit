import 'package:flutter/material.dart';

// ==================== Enums ====================
enum IconStyle { minimal, bold, soft }
enum FilterType { all, online, banned, pending }

// ==================== Models ====================

class AppUser {
  final String id;
  final String fullName;
  final String email; 
  final String avatarUrl;
  final bool isOnline;
  final String? zodiac;
  final String? gender;
  final String? bio;
  final bool isBanned;
  final String role; 
  int followersCount;
  int followingCount;

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
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
      email: map['email'] as String? ?? '', 
      avatarUrl: map['avatar_url'] as String? ?? '',
      isOnline: map['is_online'] as bool? ?? false,
      zodiac: map['zodiac'] as String?,
      gender: map['gender'] as String?,
      bio: map['bio'] as String?,
      isBanned: map['is_banned'] as bool? ?? false,
      role: map['role'] as String? ?? 'user',
      followersCount: map['followers_count'] as int? ?? 0,
      followingCount: map['following_count'] as int? ?? 0,
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
      membersCount: map['members_count'] as int? ?? 0,
    );
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
}

// ==================== التعديل المطلوب لحل أخطاء الـ Theme ====================

class AppThemeData {
  final String name;
  final Color primaryColor;
  final List<Color> gradientColors;
  final double borderRadius;
  
  // الحقول الجديدة المطلوبة في ملف profile_screen.dart ✅
  final Color text;   
  final Color button; 

  AppThemeData({
    required this.name,
    required this.primaryColor,
    required this.gradientColors,
    required this.text,    // تمت إضافتها هنا
    required this.button,  // تمت إضافتها هنا
    this.borderRadius = 30.0,
  });
}

class AppRoomRequest {
  final String id;
  final String userId;
  final String roomName;
  final String status; 
  final DateTime createdAt;

  AppRoomRequest({
    required this.id,
    required this.userId,
    required this.roomName,
    required this.status,
    required this.createdAt,
  });

  factory AppRoomRequest.fromMap(Map<String, dynamic> map) {
    return AppRoomRequest(
      id: map['id'] as String,
      userId: map['user_id'] as String? ?? '',
      roomName: map['room_name'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class AppReport {
  final String id;
  final String reporterId;
  final String reportedId;
  final String reason;
  final DateTime timestamp;

  AppReport({
    required this.id,
    required this.reporterId,
    required this.reportedId,
    required this.reason,
    required this.timestamp,
  });

  factory AppReport.fromMap(Map<String, dynamic> map) {
    return AppReport(
      id: map['id'] as String,
      reporterId: map['reporter_id'] as String? ?? '',
      reportedId: map['reported_id'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      timestamp: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

