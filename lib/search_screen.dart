import 'package:flutter/material.dart';
import 'models.dart';
import 'services/database_service.dart';
// تم حذف import 'mock_data.dart' نهائياً ✅
import 'profile_screen.dart';
import 'room_chat_screen.dart';

class SearchScreen extends StatefulWidget {
  final AppThemeData theme;
  final AppUser currentUser;
  const SearchScreen({required this.theme, required this.currentUser});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _ctrl = TextEditingController();
  List<AppUser> _users = [];
  List<AppRoom> _rooms = [];
  bool _searching = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery == _lastQuery) return;
    _lastQuery = trimmedQuery;

    if (trimmedQuery.isEmpty) {
      if (mounted) setState(() { _users = []; _rooms = []; _searching = false; });
      return;
    }

    setState(() => _searching = true);

    try {
      // الاعتماد الكلي على قاعدة البيانات الحقيقية
      final users = await DatabaseService.searchUsers(trimmedQuery);
      final rooms = await DatabaseService.searchRooms(trimmedQuery);
      
      if (mounted) {
        setState(() {
          // استثناء المستخدم الحالي من نتائج البحث لضمان تجربة مستخدم أفضل
          _users = users.where((u) => u.id != widget.currentUser.id).toList();
          _rooms = rooms;
          _searching = false;
        });
      }
    } catch (e) {
      // في حالة الخطأ، نكتفي بعرض قائمة فارغة بدل استخدام بيانات وهمية تسبب تضارب
      if (mounted) {
        setState(() {
          _users = [];
          _rooms = [];
          _searching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return SafeArea(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Text('البحث', style: TextStyle(color: t.text, fontSize: 26, fontWeight: FontWeight.w900)),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4), // تصميم زجاجي متوافق مع HomeScreen
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.6)),
            ),
            child: Row(children: [
              _searching
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: t.button))
                  : Icon(Icons.search, color: t.text.withOpacity(0.4), size: 22),
              const SizedBox(width: 10),
              Expanded(child: TextField(
                controller: _ctrl,
                style: TextStyle(color: t.text, fontSize: 14),
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: 'ابحث عن مستخدمين أو غرف...',
                  hintStyle: TextStyle(color: t.text.withOpacity(0.3)),
                  border: InputBorder.none
                ),
                onChanged: (v) { if (v.length >= 2 || v.isEmpty) _search(v); },
              )),
              if (_ctrl.text.isNotEmpty) 
                GestureDetector(
                  onTap: () { _ctrl.clear(); _search(''); }, 
                  child: Icon(Icons.close, color: t.text.withOpacity(0.4), size: 20)
                ),
            ]),
          ),
        ),
        const SizedBox(height: 14),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(color: t.button, borderRadius: BorderRadius.circular(12)),
            labelColor: Colors.white,
            unselectedLabelColor: t.text.withOpacity(0.5),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(child: Text('أشخاص (${_users.length})')),
              Tab(child: Text('غرف (${_rooms.length})')),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Expanded(child: TabBarView(
          controller: _tabController,
          children: [
            _usersTab(t),
            _roomsTab(t),
          ],
        )),
      ]),
    );
  }

  Widget _usersTab(AppThemeData t) {
    if (_ctrl.text.isEmpty) return _hint(t, 'ابحث عن أصدقاء بالاسم', Icons.people_alt_outlined);
    if (_users.isEmpty && !_searching) return _hint(t, 'لا توجد نتائج', Icons.search_off);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _users.length,
      itemBuilder: (ctx, i) {
        final u = _users[i];
        return ListTile(
          onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => ProfileScreen(userId: u.id, currentUserId: widget.currentUser.id, theme: t))),
          leading: CircleAvatar(
            backgroundImage: u.avatarUrl.isNotEmpty ? NetworkImage(u.avatarUrl) : null,
            child: u.avatarUrl.isEmpty ? Text(u.fullName[0]) : null,
          ),
          title: Text(u.fullName, style: TextStyle(color: t.text, fontWeight: FontWeight.bold)),
          subtitle: Text(u.isOnline ? 'متصل' : 'غير متصل', style: TextStyle(color: u.isOnline ? Colors.green : t.text.withOpacity(0.4))),
          trailing: Icon(Icons.arrow_forward_ios, size: 14, color: t.text.withOpacity(0.3)),
        );
      },
    );
  }

  Widget _roomsTab(AppThemeData t) {
    if (_ctrl.text.isEmpty) return _hint(t, 'ابحث عن غرفة بالاسم أو الوصف', Icons.chat_bubble_outline);
    if (_rooms.isEmpty && !_searching) return _hint(t, 'لا توجد نتائج', Icons.search_off);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _rooms.length,
      itemBuilder: (ctx, i) {
        final r = _rooms[i];
        return ListTile(
          onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => RoomChatScreen(room: r, currentUser: widget.currentUser, theme: t))),
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: t.button.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(r.icon.isEmpty ? '💬' : r.icon)),
          ),
          title: Text(r.name, style: TextStyle(color: t.text, fontWeight: FontWeight.bold)),
          subtitle: Text(r.description, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Icon(Icons.arrow_forward_ios, size: 14, color: t.text.withOpacity(0.3)),
        );
      },
    );
  }

  Widget _hint(AppThemeData t, String msg, IconData icon) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 50, color: t.text.withOpacity(0.15)),
      const SizedBox(height: 14),
      Text(msg, style: TextStyle(color: t.text.withOpacity(0.3), fontSize: 14)),
    ]));
  }
}
