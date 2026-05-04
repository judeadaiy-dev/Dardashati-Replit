import 'dart:ui';
import 'package:flutter/material.dart';
import 'models.dart';
import 'services/database_service.dart';
import 'room_chat_screen.dart';
import 'private_chat_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'admin_dashboard.dart';

class HomeScreen extends StatefulWidget {
  final AppUser currentUser;
  final AppThemeData theme;
  final Function(AppThemeData) onThemeChanged;
  const HomeScreen({required this.currentUser, required this.theme, required this.onThemeChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadUnread();
    _listenNotifications();
  }

  Future<void> _loadUnread() async {
    try {
      final count = await DatabaseService.getUnreadNotificationsCount();
      if (mounted) setState(() => _unreadNotifications = count);
    } catch (_) {}
  }

  void _listenNotifications() {
    DatabaseService.subscribeToNotifications((_) {
      if (mounted) setState(() => _unreadNotifications++);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final pages = [
      _RoomsTab(theme: t, currentUser: widget.currentUser),
      _MessagesTab(theme: t, currentUser: widget.currentUser),
      const Center(child: Text("قريباً: البحث المتقدم")), // Placeholder
      const Center(child: Text("ملفي الشخصي")), // Placeholder
    ];

    return Scaffold(
      extendBody: true, // للسماح للمحتوى بالظهور خلف شريط التنقل الشفاف
      body: Stack(
        children: [
          // خلفية بتدرج ناعم وأوربات ضبابية
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF6F3FF), Color(0xFFEAF8F6)],
              ),
            ),
          ),
          // دوائر خلفية ضبابية
          Positioned(top: -50, left: -50, child: _BlurOrb(color: const Color(0xFFC9BEFF).withOpacity(0.3), size: 250)),
          Positioned(bottom: 100, right: -50, child: _BlurOrb(color: const Color(0xFFA6ECE7).withOpacity(0.3), size: 200)),
          
          SafeArea(child: pages[_tab]),
        ],
      ),
      bottomNavigationBar: _buildGlassBottomNav(t),
    );
  }

  Widget _buildGlassBottomNav(AppThemeData t) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.grid_view_rounded, index: 0, current: _tab, theme: t, onTap: (i) => setState(() => _tab = i)),
              _NavItem(icon: Icons.chat_bubble_outline_rounded, index: 1, current: _tab, theme: t, onTap: (i) => setState(() => _tab = i)),
              _buildNotificationIcon(t),
              _NavItem(icon: Icons.person_outline_rounded, index: 3, current: _tab, theme: t, onTap: (i) => setState(() => _tab = i)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(AppThemeData t) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsScreen(theme: t))).then((_) => _loadUnread()),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, color: t.text.withOpacity(0.5), size: 28),
          if (_unreadNotifications > 0)
            Positioned(
              top: 15, right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                child: Text('$_unreadNotifications', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}

// ========================= بطاقة الغرف الزجاجية =========================

class _RoomsTab extends StatelessWidget {
  final AppThemeData theme;
  final AppUser currentUser;
  const _RoomsTab({required this.theme, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('دردشاتي', style: TextStyle(color: theme.text, fontSize: 28, fontWeight: FontWeight.w900)),
                  Text('مرحباً، ${currentUser.fullName}', style: TextStyle(color: theme.text.withOpacity(0.6), fontSize: 14)),
                ]),
                _CircularAction(icon: Icons.settings_suggest_outlined, theme: theme),
              ],
            ),
          ),
        ),
        // هنا يتم إضافة الـ ListView الخاص بالغرف بتصميم الـ Glass Card
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _GlassRoomCard(theme: theme), // سنقوم بربطها بالداتابيز لاحقاً
              childCount: 5,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)), // مساحة لشريط التنقل
      ],
    );
  }
}

// اليدجت المساعد للأوربات الضبابية
class _BlurOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _BlurOrb({required this.color, required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40), child: Container(color: Colors.transparent)),
    );
  }
}

// شاشة المحادثات والرسائل (تعديل بسيط للألوان)
class _MessagesTab extends StatelessWidget {
  final AppThemeData theme;
  final AppUser currentUser;
  const _MessagesTab({required this.theme, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('المحادثات', style: TextStyle(color: theme.text, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) => _GlassUserTile(theme: theme),
            ),
          ),
        ],
      ),
    );
  }
}

// تصميم البطاقة الزجاجية للغرفة
class _GlassRoomCard extends StatelessWidget {
  final AppThemeData theme;
  const _GlassRoomCard({required this.theme});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: theme.button.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
            child: const Center(child: Text('💬', style: TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('غرفة عامة', style: TextStyle(color: theme.text, fontWeight: FontWeight.bold)),
            Text('154 عضواً متصل الآن', style: TextStyle(color: theme.text.withOpacity(0.5), fontSize: 12)),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.text.withOpacity(0.3)),
        ],
      ),
    );
  }
}

class _CircularAction extends StatelessWidget {
  final IconData icon;
  final AppThemeData theme;
  const _CircularAction({required this.icon, required this.theme});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle, border: Border.all(color: Colors.white)),
      child: Icon(icon, color: theme.text.withOpacity(0.7), size: 22),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final int index, current;
  final AppThemeData theme;
  final Function(int) onTap;
  const _NavItem({required this.icon, required this.index, required this.current, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active ? theme.button.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon, color: active ? theme.button : theme.text.withOpacity(0.4), size: 26),
      ),
    );
  }
}

class _GlassUserTile extends StatelessWidget {
  final AppThemeData theme;
  const _GlassUserTile({required this.theme});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(backgroundColor: theme.accent.withOpacity(0.2), radius: 25),
      title: Text('اسم المستخدم', style: TextStyle(color: theme.text, fontWeight: FontWeight.w600)),
      subtitle: Text('آخر رسالة تظهر هنا...', style: TextStyle(color: theme.text.withOpacity(0.5), fontSize: 13)),
      trailing: Icon(Icons.circle, size: 10, color: theme.accent),
    );
  }
}
