import 'package:flutter/material.dart';
import 'models.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'mock_data.dart';
import 'room_chat_screen.dart';
import 'private_chat_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
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
      SearchScreen(theme: t, currentUser: widget.currentUser),
      ProfileScreen(userId: widget.currentUser.id, currentUserId: widget.currentUser.id, theme: t),
    ];

    return Scaffold(
      backgroundColor: t.background,
      body: pages[_tab],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: t.menu, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))]),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_rounded, label: 'الرئيسية', index: 0, current: _tab, theme: t, onTap: (i) => setState(() => _tab = i)),
                _NavItem(icon: Icons.chat_bubble_rounded, label: 'الرسائل', index: 1, current: _tab, theme: t, onTap: (i) => setState(() => _tab = i)),
                _NavItem(icon: Icons.search_rounded, label: 'البحث', index: 2, current: _tab, theme: t, onTap: (i) => setState(() => _tab = i)),
                _NavItem(icon: Icons.person_rounded, label: 'ملفي', index: 3, current: _tab, theme: t, onTap: (i) => setState(() => _tab = i)),
                // زر الإشعارات
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsScreen(theme: t))).then((_) => _loadUnread()),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(14)),
                            child: Icon(Icons.notifications_outlined, color: t.text.withOpacity(0.4), size: 24),
                          ),
                          if (_unreadNotifications > 0)
                            Positioned(
                              top: 2, right: 2,
                              child: Container(
                                width: 16, height: 16,
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: Center(child: Text(_unreadNotifications > 9 ? '9+' : '$_unreadNotifications', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text('إشعارات', style: TextStyle(color: t.text.withOpacity(0.4), fontSize: 10)),
                    ],
                  ),
                ),
                // زر الإدارة
                if (widget.currentUser.isModerator)
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminDashboard(currentTheme: t, onThemeChanged: widget.onThemeChanged))),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: const Icon(Icons.shield_rounded, color: Colors.orange, size: 24)),
                        const SizedBox(height: 3),
                        const Text('الإدارة', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index, current;
  final AppThemeData theme;
  final Function(int) onTap;
  const _NavItem({required this.icon, required this.label, required this.index, required this.current, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: active ? theme.button.withOpacity(0.15) : Colors.transparent, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: active ? theme.button : theme.text.withOpacity(0.4), size: 24),
          ),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: active ? theme.button : theme.text.withOpacity(0.4), fontSize: 10, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

// ========================= تبويب الغرف =========================
class _RoomsTab extends StatefulWidget {
  final AppThemeData theme;
  final AppUser currentUser;
  const _RoomsTab({required this.theme, required this.currentUser});

  @override
  State<_RoomsTab> createState() => _RoomsTabState();
}

class _RoomsTabState extends State<_RoomsTab> {
  List<AppRoom> _rooms = [];
  List<AppUser> _online = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rooms = await DatabaseService.getRooms();
      final users = await DatabaseService.getUsers();
      if (mounted) setState(() {
        _rooms = rooms;
        _online = users.where((u) => u.isOnline && u.id != widget.currentUser.id).toList();
        _loading = false;
      });
    } catch (_) {
      // fallback
      if (mounted) setState(() { _rooms = mockRooms; _online = mockUsers.where((u) => u.isOnline && u.id != widget.currentUser.id).toList(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final featured = _rooms.where((r) => r.isFeatured).toList();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        color: t.button,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header(context, t)),
            if (_online.isNotEmpty) SliverToBoxAdapter(child: _onlineUsers(context, t)),
            if (featured.isNotEmpty) ...[
              SliverToBoxAdapter(child: _sectionTitle('الغرف المميزة', t, t.button)),
              SliverToBoxAdapter(child: _featuredRooms(context, featured, t)),
            ],
            SliverToBoxAdapter(child: _sectionTitle('جميع الغرف', t, t.accent)),
            _loading
                ? SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(40), child: CircularProgressIndicator(color: t.button))))
                : SliverList(delegate: SliverChildBuilderDelegate((ctx, i) => _roomCard(ctx, _rooms[i], t), childCount: _rooms.length)),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, AppThemeData t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('مرحباً، ${widget.currentUser.fullName} 👋', style: TextStyle(color: t.text, fontSize: 20, fontWeight: FontWeight.bold)),
            Text('اكتشف محادثات جديدة اليوم', style: TextStyle(color: t.text.withOpacity(0.5), fontSize: 13)),
          ]),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(currentUser: widget.currentUser, theme: t))),
            child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: t.text.withOpacity(0.1))), child: Icon(Icons.settings_outlined, color: t.text.withOpacity(0.7), size: 22)),
          ),
        ],
      ),
    );
  }

  Widget _onlineUsers(BuildContext context, AppThemeData t) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
        child: Row(children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text('متصلون الآن', style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(width: 6),
          Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Text('${_online.length}', style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold))),
        ]),
      ),
      SizedBox(
        height: 90,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _online.length,
          itemBuilder: (ctx, i) {
            final u = _online[i];
            return GestureDetector(
              onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => PrivateChatScreen(otherUserId: u.id, otherUserName: u.fullName, otherUserAvatar: u.avatarUrl, currentUser: widget.currentUser, theme: t))),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(children: [
                  Stack(children: [
                    CircleAvatar(backgroundImage: u.avatarUrl.isNotEmpty ? NetworkImage(u.avatarUrl) : null, radius: 28, backgroundColor: t.button.withOpacity(0.2), child: u.avatarUrl.isEmpty ? Text(u.fullName[0], style: TextStyle(color: t.button)) : null),
                    Positioned(bottom: 1, right: 1, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: t.background, width: 2)))),
                  ]),
                  const SizedBox(height: 6),
                  Text(u.fullName.split(' ').first, style: TextStyle(color: t.text.withOpacity(0.8), fontSize: 11)),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }

  Widget _sectionTitle(String label, AppThemeData t, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 16)),
      ]),
    );
  }

  Widget _featuredRooms(BuildContext context, List<AppRoom> rooms, AppThemeData t) {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: rooms.length,
        itemBuilder: (ctx, i) {
          final r = rooms[i];
          return GestureDetector(
            onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => RoomChatScreen(room: r, currentUser: widget.currentUser, theme: t))),
            child: Container(
              width: 200,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [t.button.withOpacity(0.8), t.accent.withOpacity(0.5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(r.icon, style: const TextStyle(fontSize: 30)),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)), child: const Text('مميزة', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(r.membersCountLabel, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                ]),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _roomCard(BuildContext context, AppRoom room, AppThemeData t) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RoomChatScreen(room: room, currentUser: widget.currentUser, theme: t))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: t.text.withOpacity(0.08))),
        child: Row(children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: t.button.withOpacity(0.1), borderRadius: BorderRadius.circular(18)), child: Center(child: Text(room.icon, style: const TextStyle(fontSize: 28)))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(room.name, style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(room.description, style: TextStyle(color: t.text.withOpacity(0.5), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(children: [Icon(Icons.people_alt_outlined, size: 13, color: t.text.withOpacity(0.4)), const SizedBox(width: 4), Text(room.membersCountLabel, style: TextStyle(color: t.text.withOpacity(0.4), fontSize: 11))]),
          ])),
          Icon(Icons.arrow_forward_ios, size: 14, color: t.text.withOpacity(0.3)),
        ]),
      ),
    );
  }
}

// ========================= تبويب الرسائل =========================
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
    _load();
  }

  Future<void> _load() async {
    try {
      final users = await DatabaseService.getUsers();
      if (mounted) setState(() { _users = users.where((u) => u.id != widget.currentUser.id).toList(); _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _users = mockUsers.where((u) => u.id != widget.currentUser.id).toList(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return SafeArea(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 16), child: Text('الرسائل', style: TextStyle(color: t.text, fontSize: 26, fontWeight: FontWeight.w900))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: t.text.withOpacity(0.08))),
            child: Row(children: [
              Icon(Icons.search, color: t.text.withOpacity(0.4), size: 20),
              const SizedBox(width: 10),
              Expanded(child: TextField(
                decoration: InputDecoration(hintText: 'ابحث عن محادثة...', hintStyle: TextStyle(color: t.text.withOpacity(0.3), fontSize: 14), border: InputBorder.none),
                style: TextStyle(color: t.text),
              )),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: t.button))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: t.button,
                  child: ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (ctx, i) {
                      final u = _users[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => PrivateChatScreen(otherUserId: u.id, otherUserName: u.fullName, otherUserAvatar: u.avatarUrl, currentUser: widget.currentUser, theme: t))),
                        leading: Stack(children: [
                          CircleAvatar(backgroundImage: u.avatarUrl.isNotEmpty ? NetworkImage(u.avatarUrl) : null, radius: 26, backgroundColor: t.button.withOpacity(0.2), child: u.avatarUrl.isEmpty ? Text(u.fullName[0], style: TextStyle(color: t.button)) : null),
                          if (u.isOnline) Positioned(bottom: 0, right: 0, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: t.background, width: 2)))),
                        ]),
                        title: Text(u.fullName, style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: Text(u.isOnline ? 'متصل الآن' : 'غير متصل', style: TextStyle(color: u.isOnline ? Colors.green : t.text.withOpacity(0.4), fontSize: 12)),
                        trailing: _roleBadge(u.role, t),
                      );
                    },
                  ),
                ),
        ),
      ]),
    );
  }

  Widget _roleBadge(String role, AppThemeData t) {
    Color c; String label;
    switch (role) {
      case 'admin': c = Colors.red; label = 'مشرف'; break;
      case 'moderator': c = Colors.orange; label = 'مراقب'; break;
      default: c = t.accent; label = 'عضو'; break;
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withOpacity(0.3))), child: Text(label, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)));
  }
}
