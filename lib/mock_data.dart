// ======================================================
// بيانات وهمية للاختبار المحلي فقط
// يمكن حذف هذا الملف بأمان عند الربط الحقيقي مع Supabase
// تأكد من إزالة الاستيراد من الملفات الأخرى عند الحذف
// ======================================================

import 'models.dart';

final List<AppUser> mockUsers = [
  AppUser(id: 'u1', fullName: 'المشرف العام', avatarUrl: 'https://i.pravatar.cc/150?img=1', isOnline: true, role: 'admin', bio: 'مشرف التطبيق'),
  AppUser(id: '1',  fullName: 'أحمد',        avatarUrl: 'https://i.pravatar.cc/150?img=11', isOnline: true,  role: 'user', zodiac: 'الحمل',   gender: 'male',   bio: 'مطور تطبيقات'),
  AppUser(id: '2',  fullName: 'سارة',        avatarUrl: 'https://i.pravatar.cc/150?img=32', isOnline: false, role: 'user', zodiac: 'العذراء', gender: 'female', bio: 'مصممة جرافيك'),
  AppUser(id: '3',  fullName: 'خالد',        avatarUrl: 'https://i.pravatar.cc/150?img=44', isOnline: true,  role: 'user', zodiac: 'الجوزاء', gender: 'male',   bio: 'كاتب ومدوّن'),
  AppUser(id: '4',  fullName: 'منى',         avatarUrl: 'https://i.pravatar.cc/150?img=55', isOnline: false, role: 'user', zodiac: 'الميزان', gender: 'female', isBanned: true),
  AppUser(id: '5',  fullName: 'عمر',         avatarUrl: 'https://i.pravatar.cc/150?img=21', isOnline: true,  role: 'moderator', zodiac: 'الأسد', gender: 'male', bio: 'مشرف الغرف'),
  AppUser(id: '6',  fullName: 'ليلى',        avatarUrl: 'https://i.pravatar.cc/150?img=41', isOnline: false, role: 'user', zodiac: 'السرطان', gender: 'female', bio: 'طالبة طب'),
  AppUser(id: '7',  fullName: 'يوسف',        avatarUrl: 'https://i.pravatar.cc/150?img=12', isOnline: true,  role: 'user', zodiac: 'القوس',   gender: 'male',   bio: 'رياضي ومحب للسفر'),
];

final List<AppRoom> mockRooms = [
  AppRoom(id: 'r1', name: 'عالم التقنية',   icon: '🚀', description: 'كل ما يخص التقنية والبرمجة',    ownerId: '1', membersCount: 2400),
  AppRoom(id: 'r2', name: 'سوالف القهوة',  icon: '☕', description: 'مكان هادئ للنقاشات الممتعة',    ownerId: '1', membersCount: 842,  isFeatured: true),
  AppRoom(id: 'r3', name: 'ملتقى الفنون',  icon: '🎨', description: 'للفنانين والمبدعين فقط',         ownerId: '2', membersCount: 1100),
  AppRoom(id: 'r4', name: 'الرياضة مباشر', icon: '⚽', description: 'نتائج المباريات والتحاليل',      ownerId: '5', membersCount: 5000),
  AppRoom(id: 'r5', name: 'عشاق الموسيقى', icon: '🎵', description: 'نقاشات الموسيقى العربية والعالمية', ownerId: '6', membersCount: 980, isFeatured: true),
];

final List<AppMessage> mockMessages = [
  AppMessage(id: 'm1', senderId: '1', senderName: 'أحمد',  senderAvatar: 'https://i.pravatar.cc/150?img=11', content: 'السلام عليكم، كيف الحال؟',         time: DateTime.now().subtract(Duration(minutes: 35))),
  AppMessage(id: 'm2', senderId: '3', senderName: 'خالد',  senderAvatar: 'https://i.pravatar.cc/150?img=44', content: 'أهلاً بك يا أحمد، بخير ولله الحمد', time: DateTime.now().subtract(Duration(minutes: 33)), replyToContent: 'السلام عليكم، كيف الحال؟'),
  AppMessage(id: 'm3', senderId: '5', senderName: 'عمر',   senderAvatar: 'https://i.pravatar.cc/150?img=21', content: 'سمعتم عن التحديث الجديد؟',          time: DateTime.now().subtract(Duration(minutes: 20))),
  AppMessage(id: 'm4', senderId: '1', senderName: 'أحمد',  senderAvatar: 'https://i.pravatar.cc/150?img=11', content: 'رسالة صوتية',                       time: DateTime.now().subtract(Duration(minutes: 15)), isAudio: true, audioDuration: '0:15'),
  AppMessage(id: 'm5', senderId: '3', senderName: 'خالد',  senderAvatar: 'https://i.pravatar.cc/150?img=44', content: 'نعم شفته، رائع جداً!',              time: DateTime.now().subtract(Duration(minutes: 13))),
  AppMessage(id: 'm6', senderId: '7', senderName: 'يوسف',  senderAvatar: 'https://i.pravatar.cc/150?img=12', content: 'بالتوفيق للجميع 🎉',                time: DateTime.now().subtract(Duration(minutes: 5))),
];

final List<AppRoomRequest> mockRoomRequests = [
  AppRoomRequest(id: 'req1', requesterId: '1', requesterName: 'أحمد', name: 'عشاق التحدي',   icon: '🏆', description: 'غرفة للمسابقات اليومية',  status: 'pending'),
  AppRoomRequest(id: 'req2', requesterId: '3', requesterName: 'خالد', name: 'مطبخنا العربي', icon: '🍲', description: 'وصفات وحكايات طبخ',        status: 'pending'),
];

final List<AppReport> mockReports = [
  AppReport(id: 'rep1', reporterId: '2', reporterName: 'سارة',  targetId: '5', targetName: 'عمر',  reason: 'إزعاج مستمر',             timestamp: DateTime.now().subtract(Duration(hours: 3)),  status: 'pending'),
  AppReport(id: 'rep2', reporterId: '3', reporterName: 'خالد',  targetId: '4', targetName: 'منى',  reason: 'محتوى مخالف للسياسة',     timestamp: DateTime.now().subtract(Duration(hours: 1)),  status: 'pending'),
];

final List<AppNotification> mockNotifications = [
  AppNotification(id: 'n1', type: 'follow',  title: 'متابع جديد',           body: 'أحمد بدأ متابعتك',                  isRead: false, createdAt: DateTime.now().subtract(Duration(minutes: 10))),
  AppNotification(id: 'n2', type: 'message', title: 'رسالة جديدة من سارة',  body: 'أهلاً، كيف حالك؟',                  isRead: false, createdAt: DateTime.now().subtract(Duration(minutes: 30))),
  AppNotification(id: 'n3', type: 'system',  title: 'تحديث جديد متاح',       body: 'تم إضافة ميزات جديدة للتطبيق',     isRead: true,  createdAt: DateTime.now().subtract(Duration(hours: 2))),
];
