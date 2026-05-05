import 'package:dardashati/extensions.dart';
import 'package:flutter/material.dart';
import 'package:blur/blur.dart'; // مكتبة التأثير الزجاجي
import 'package:dardashati/models.dart'; 
import 'package:dardashati/services/database_service.dart';

class NotificationsScreen extends StatefulWidget {
  final AppThemeData theme;
  const NotificationsScreen({super.key, required this.theme});

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
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await DatabaseService.getNotifications();
      if (mounted) {
        setState(() { 
          _notifications = data; 
          _loading = false; 
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { 
          _notifications = []; 
          _loading = false; 
        });
      }
    }
  }

  Future<void> _markAllRead() async {
    try {
      await DatabaseService.markAllNotificationsRead();
      setState(() { 
        for (var n in _notifications) {
          n.isRead = true; 
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: t.background,
      // AppBar بنظام Glassmorphism
      appBar: AppBar(
        flexibleSpace: Container().frozen(blur: 15, color: t.menu.withOpacity(0.7)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Text('الإشعارات', 
              style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Tajawal')),
            if (unreadCount > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: t.button,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$unreadCount جديد', 
                  style: TextStyle(color: t.buttonText, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: t.text),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text('تحديد الكل كمقروء', 
                style: TextStyle(color: t.button, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: t.button))
          : _notifications.isEmpty
              ? _buildEmptyState(t)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: t.button,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (ctx, i) => _buildNotificationItem(_notifications[i], t),
                  ),
                ),
    );
  }

  Widget _buildNotificationItem(AppNotification n, AppThemeData t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: n.isRead ? t.card.withOpacity(0.4) : t.card,
        borderRadius: BorderRadius.circular(25), // انحناء كبير ومتناسق مع تصميمنا
        border: Border.all(
          color: n.isRead ? Colors.transparent : t.button.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: () async {
          if (!n.isRead) {
            setState(() => n.isRead = true);
            await DatabaseService.markNotificationRead(n.id);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // أيقونة الإشعار بتصميم دائري عصري
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [t.button.withOpacity(0.2), t.button.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(n.icon, color: t.button, size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.title, 
                      style: TextStyle(
                        color: t.text, 
                        fontWeight: n.isRead ? FontWeight.w500 : FontWeight.bold, 
                        fontSize: 15,
                        fontFamily: 'Tajawal'
                      )),
                    const SizedBox(height: 4),
                    Text(n.body, 
                      style: TextStyle(color: t.text.withOpacity(0.6), fontSize: 13),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Text(_relativeTime(n.createdAt), 
                      style: TextStyle(color: t.text.withOpacity(0.3), fontSize: 10)),
                  ],
                ),
              ),
              if (!n.isRead)
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(color: t.button, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppThemeData t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 80, color: t.text.withOpacity(0.1)),
          const SizedBox(height: 20),
          Text('هدوء تام هنا..', 
            style: TextStyle(color: t.text.withOpacity(0.4), fontSize: 18, fontWeight: FontWeight.bold)),
          Text('لا توجد إشعارات جديدة بانتظارك', 
            style: TextStyle(color: t.text.withOpacity(0.3), fontSize: 14)),
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
