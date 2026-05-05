import 'package:flutter/material.dart';
import 'package:dardashati/models.dart';
import 'package:dardashati/app_theme.dart';
import 'package:dardashati/services/database_service.dart';
import 'package:dardashati/profile_screen.dart';
import 'package:dardashati/room_chat_screen.dart';

class SearchScreen extends StatefulWidget {
  final AppThemeData theme;
  final AppUser currentUser;
  const SearchScreen({super.key, required this.theme, required this.currentUser});

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
      // البحث المتزامن عن المستخدمين والغرف
      final results = await Future.wait([
        DatabaseService.searchUsers(trimmedQuery),
        DatabaseService.searchRooms(trimmedQuery),
      ]);

      if (mounted) {
        setState(() {
          _users = (results[0] as List<AppUser>)
              .where((u) => u.id != widget.currentUser.id)
              .toList();
          _rooms = results[1] as List<AppRoom>;
          _searching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Scaffold(
      backgroundColor: Colors.transparent, // لجعل الخلفية تظهر من الـ Stack في الرئيسي
      body: SafeArea(
        child: Column(children: [
          // العنوان
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('اكتشف', 
                style: TextStyle(color: t.text, fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'Tajawal'))
            ),
          ),

          // شريط البحث الزجاجي
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: t.card.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(children: [
                if (_searching)
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: t.button))
                else
                  Icon(Icons.search_rounded, color: t.text.withOpacity(0.3), size: 22),
                const SizedBox(width: 12),
                Expanded(child: TextField(
                  controller: _ctrl,
                  style: TextStyle(color: t.text, fontSize: 15),
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن أصدقاء أو غرف...',
                    hintStyle: TextStyle(color: t.text.withOpacity(0.2)),
                    border: InputBorder.none
                  ),
                  onChanged: (v) { if (v.length >= 2 || v.isEmpty) _search(v); },
                )),
                if (_ctrl.text.isNotEmpty) 
                  GestureDetector(
                    onTap: () { _ctrl.clear(); _search(''); }, 
                    child: Icon(Icons.cancel_rounded, color: t.text.withOpacity(0.2), size: 20)
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 20),

          // تبويبات البحث
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 45,
            decoration: BoxDecoration(
              color: t.card.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: t.button, 
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: t.button.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
              ),
              labelColor: t.buttonText,
              unselectedLabelColor: t.text.withOpacity(0.4),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Tajawal'),
              tabs: [
                Tab(text: 'أشخاص (${_users.length})'),
                Tab(text: 'غرف (${_rooms.length})'),
              ],
            ),
          ),
          const SizedBox(height: 15),

          // محتوى البحث
          Expanded(child: TabBarView(
            controller: _tabController,
            children: [
              _buildUsersList(t),
              _buildRoomsList(t),
            ],
          )),
        ]),
      ),
    );
  }

  Widget _buildUsersList(AppThemeData t) {
    if (_ctrl.text.isEmpty) return _buildHint(t, 'ابحث عن أصدقاء جدد لتبدأ المحادثة', Icons.person_add_alt_1_rounded);
    if (_users.isEmpty && !_searching) return _buildHint(t, 'لم نجد أحداً بهذا الاسم', Icons.search_off_rounded);
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: _users.length,
      itemBuilder: (ctx, i) {
        final u = _users[i];
        return _buildResultCard(
          t: t,
          onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => ProfileScreen(userId: u.id, currentUserId: widget.currentUser.id, theme: t))),
          title: u.fullName,
          subtitle: u.isOnline ? 'نشط الآن' : 'غير متصل',
          subtitleColor: u.isOnline ? Colors.greenAccent : t.text.withOpacity(0.3),
          image: u.avatarUrl.isNotEmpty ? NetworkImage(u.avatarUrl) : null,
          placeholder: u.fullName[0],
        );
      },
    );
  }

  Widget _buildRoomsList(AppThemeData t) {
    if (_ctrl.text.isEmpty) return _buildHint(t, 'اكتشف غرف الدردشة الجماعية', Icons.explore_rounded);
    if (_rooms.isEmpty && !_searching) return _buildHint(t, 'لا توجد غرف بهذا الاسم حالياً', Icons.comments_disabled_rounded);
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: _rooms.length,
      itemBuilder: (ctx, i) {
        final r = _rooms[i];
        return _buildResultCard(
          t: t,
          onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => RoomChatScreen(room: r, currentUser: widget.currentUser, theme: t))),
          title: r.name,
          subtitle: r.description,
          iconText: r.icon.isEmpty ? '💬' : r.icon,
          isRoom: true,
        );
      },
    );
  }

  Widget _buildResultCard({
    required AppThemeData t,
    required VoidCallback onTap,
    required String title,
    required String subtitle,
    Color? subtitleColor,
    ImageProvider? image,
    String? placeholder,
    String? iconText,
    bool isRoom = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: t.card.withOpacity(0.3),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: t.text.withOpacity(0.2)),
        trailing: isRoom 
          ? Container(
              width: 45, height: 45,
              decoration: BoxDecoration(color: t.button.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(iconText!, style: const TextStyle(fontSize: 20))),
            )
          : CircleAvatar(
              radius: 22,
              backgroundColor: t.button.withOpacity(0.2),
              backgroundImage: image,
              child: image == null ? Text(placeholder!, style: TextStyle(color: t.button, fontWeight: FontWeight.bold)) : null,
            ),
        title: Text(title, textAlign: TextAlign.right, style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, 
            style: TextStyle(color: subtitleColor ?? t.text.withOpacity(0.5), fontSize: 12)),
      ),
    );
  }

  Widget _buildHint(AppThemeData t, String msg, IconData icon) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: t.button.withOpacity(0.05), shape: BoxShape.circle),
        child: Icon(icon, size: 45, color: t.button.withOpacity(0.2)),
      ),
      const SizedBox(height: 16),
      Text(msg, style: TextStyle(color: t.text.withOpacity(0.3), fontSize: 14, fontFamily: 'Tajawal')),
    ]));
  }
}
