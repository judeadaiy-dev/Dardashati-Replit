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

// --- تحديث كلاس الثيم لحل أخطاء label, background, card ---
class AppThemeData {
  final String name;
  final String label; // أضفنا الحقل المطلوب
  final Color primaryColor;
  final List<Color> gradientColors;
  final Color background; // أضفنا الحقل المطلوب
  final Color text;   
  final Color button; 
  final Color card; // أضفنا الحقل المطلوب
  final double borderRadius;

  AppThemeData({
    required this.name,
    required this.label,
    required this.primaryColor,
    required this.gradientColors,
    required this.background,
    required this.text,    
    required this.button,  
    required this.card,
    this.borderRadius = 30.0,
  });
}

// --- تحديث طلبات الغرف لحل خطأ name ---
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

  // الـ Getter الذي يطلبه ملف admin_dashboard
  String get name => roomName;

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

// --- تحديث التقارير لحل خطأ targetName ---
class AppReport {
  final String id;
  final String reporterId;
  final String reportedId;
  final String reason;
  final DateTime timestamp;
  final String? targetName; // أضفنا الحقل المطلوب

  AppReport({
    required this.id,
    required this.reporterId,
    required this.reportedId,
    required this.reason,
    required this.timestamp,
    this.targetName,
  });

  factory AppReport.fromMap(Map<String, dynamic> map) {
    return AppReport(
      id: map['id'] as String,
      reporterId: map['reporter_id'] as String? ?? '',
      reportedId: map['reported_id'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      timestamp: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      targetName: map['target_name'] as String?,
    );
  }
}
