import '../models.dart';
import 'package:flutter/material.dart';
import 'models.dart';
import 'services/database_service.dart';
import 'mock_data.dart';

class NotificationsScreen extends StatefulWidget {
  final AppThemeData theme;
  const NotificationsScreen({required this.theme});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await DatabaseService.getNotifications();
      if (mounted) setState(() { _notifications = data; _loading = false; });
    } catch (_) {
      // fallback to mock
      if (mounted) setState(() { _notifications = mockNotifications; _loading = false; });
    }
  }

  Future<void> _markAllRead() async {
    await DatabaseService.markAllNotificationsRead();
    setState(() { for (final n in _notifications) n.isRead = true; });
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final unread = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.menu,
        elevation: 0,
        title: Row(children: [
          Text('الإشعارات', style: TextStyle(color: t.text, fontWeight: FontWeight.bold)),
          if (unread > 0) ...[
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)), child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
          ],
        ]),
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: t.text), onPressed: () => Navigator.pop(context)),
        actions: [
          if (unread > 0)
            TextButton(onPressed: _markAllRead, child: Text('قراءة الكل', style: TextStyle(color: t.button, fontSize: 13))),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: t.button))
          : _notifications.isEmpty
              ? _empty(t)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: t.button,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (ctx, i) => _item(_notifications[i], t),
                  ),
                ),
    );
  }

  Widget _item(AppNotification n, AppThemeData t) {
    return GestureDetector(
      onTap: () async {
        if (!n.isRead) {
          await DatabaseService.markNotificationRead(n.id);
          setState(() => n.isRead = true);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: n.isRead ? t.card : t.button.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: n.isRead ? t.text.withOpacity(0.07) : t.button.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: n.iconColor(t.accent).withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
              child: Icon(n.icon, color: n.iconColor(t.accent), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title, style: TextStyle(color: t.text, fontWeight: n.isRead ? FontWeight.w500 : FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(n.body, style: TextStyle(color: t.text.withOpacity(0.55), fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(_relativeTime(n.createdAt), style: TextStyle(color: t.text.withOpacity(0.3), fontSize: 10)),
                ],
              ),
            ),
            if (!n.isRead)
              Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 4), decoration: BoxDecoration(color: t.button, shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }

  Widget _empty(AppThemeData t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 56, color: t.text.withOpacity(0.2)),
          const SizedBox(height: 14),
          Text('لا توجد إشعارات حتى الآن', style: TextStyle(color: t.text.withOpacity(0.35), fontSize: 15)),
        ],
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }
}
