import 'dart:ui';
import 'package:flutter/material.dart';
import 'models.dart';
import 'services/database_service.dart';
import 'room_chat_screen.dart';
import 'private_chat_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'admin_dashboard.dart';
import 'search_screen.dart'; // تأكد من وجود هذا الملف أو استبدله بـ Placeholder
import 'profile_screen.dart'; // تأكد من وجود هذا الملف

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
      SearchScreen(theme: t, currentUser: widget.currentUser), 
      ProfileScreen(userId: widget.currentUser.id, currentUserId: widget.currentUser.id, theme: t),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF6F3FF), Color(0xFFEAF8F6)],
              ),
            ),
          ),
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

// ========================= تبويب الغرف (معدل ليجلب البيانات) =========================

class _RoomsTab extends StatefulWidget {
  final AppThemeData theme;
  final AppUser currentUser;
  const _RoomsTab({required this.theme, required this.currentUser});

  @override
  State<_RoomsTab> createState() => _RoomsTabState();
}

class _RoomsTabState extends State<_RoomsTab> {
  List<AppRoom> _rooms = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  Future<void> _fetchRooms() async {
    try {
      final rooms = await DatabaseService.getRooms();
      if (mounted) setState(() { _rooms = rooms; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

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
                  Text('دردشاتي', style: TextStyle(color: widget.theme.text, fontSize: 28, fontWeight: FontWeight.w900)),
                  Text('مرحباً، ${widget.currentUser.fullName}', style: TextStyle(color: widget.theme.text.withOpacity(0.6), fontSize: 14)),
                ]),
                _CircularAction(icon: Icons.settings_suggest_outlined, theme: widget.theme),
              ],
            ),
          ),
        ),
        if (_loading)
          const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _GlassRoomCard(theme: widget.theme, room: _rooms[index], currentUser: widget.currentUser),
                childCount: _rooms.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

// ========================= تبويب الرسائل (معدل ليجلب المستخدمين) =========================

class _MessagesTab extends StatefulWidget {
  final AppThemeData theme;
  final AppUser currentUser;
  const _MessagesTab({required this.theme, required this.currentUser});

  @override
  State<_MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<_MessagesTab> {
  List<AppUser> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final users = await DatabaseService.getUsers();
      // استثناء المستخدم الحالي من القائمة
      if (mounted) setState(() { 
        _users = users.where((u) => u.id != widget.currentUser.id).toList(); 
        _loading = false; 
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('المحادثات', style: TextStyle(color: widget.theme.text, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: _loading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) => _GlassUserTile(theme: widget.theme, user: _users[index], currentUser: widget.currentUser),
                ),
          ),
        ],
      ),
    );
  }
}

// ========================= الودجت الفرعية المصلحة =========================

class _GlassRoomCard extends StatelessWidget {
  final AppThemeData theme;
  final AppRoom room;
  final AppUser currentUser;
  const _GlassRoomCard({required this.theme, required this.room, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RoomChatScreen(room: room, currentUser: currentUser, theme: theme))),
      child: Container(
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
              child: Center(child: Text(room.icon.isEmpty ? '💬' : room.icon, style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 15),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(room.name, style: TextStyle(color: theme.text, fontWeight: FontWeight.bold)),
              Text(room.description, style: TextStyle(color: theme.text.withOpacity(0.5), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.text.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}

class _GlassUserTile extends StatelessWidget {
  final AppThemeData theme;
  final AppUser user;
  final AppUser currentUser;
  const _GlassUserTile({required this.theme, required this.user, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PrivateChatScreen(otherUserId: user.id, otherUserName: user.fullName, otherUserAvatar: user.avatarUrl, currentUser: currentUser, theme: theme))),
      leading: CircleAvatar(
        backgroundColor: theme.accent.withOpacity(0.2), 
        backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
        radius: 25,
        child: user.avatarUrl.isEmpty ? Text(user.fullName[0], style: TextStyle(color: theme.text)) : null,
      ),
      title: Text(user.fullName, style: TextStyle(color: theme.text, fontWeight: FontWeight.w600)),
      subtitle: Text(user.isOnline ? 'متصل الآن' : 'غير متصل', style: TextStyle(color: theme.text.withOpacity(0.5), fontSize: 13)),
      trailing: Icon(Icons.circle, size: 10, color: user.isOnline ? Colors.green : Colors.transparent),
    );
  }
}

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

class _CircularAction extends StatelessWidget {
  final IconData icon;
  final AppThemeData theme;
  const _CircularAction({required this.icon, required this.theme});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(currentUser: (context.findAncestorStateOfType<_HomeScreenState>()!).widget.currentUser, theme: theme))),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle, border: Border.all(color: Colors.white)),
        child: Icon(icon, color: theme.text.withOpacity(0.7), size: 22),
      ),
    );
  }
}
