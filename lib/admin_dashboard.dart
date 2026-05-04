import 'package:flutter/material.dart';
import 'models.dart';
import 'app_theme.dart'; 
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'profile_screen.dart';

class AdminDashboard extends StatefulWidget {
  final AppThemeData currentTheme;
  final Function(AppThemeData) onThemeChanged;
  const AdminDashboard({required this.currentTheme, required this.onThemeChanged});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _broadcastCtrl = TextEditingController();

  List<AppUser> _users = [];
  List<AppReport> _reports = [];
  List<AppRoomRequest> _requests = [];
  bool _loadingUsers = true;
  bool _loadingReports = true;
  bool _loadingRequests = true;
  bool _broadcasting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _broadcastCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    _loadUsers();
    _loadReports();
    _loadRequests();
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    try {
      final data = await DatabaseService.getUsers();
      if (mounted) setState(() { _users = data; _loadingUsers = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  Future<void> _loadReports() async {
    setState(() => _loadingReports = true);
    try {
      final data = await DatabaseService.getReports();
      if (mounted) setState(() { _reports = data; _loadingReports = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingReports = false);
    }
  }

  Future<void> _loadRequests() async {
    setState(() => _loadingRequests = true);
    try {
      final data = await DatabaseService.getRoomRequests();
      if (mounted) setState(() { _requests = data; _loadingRequests = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingRequests = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.currentTheme;
    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.menu, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: t.text), onPressed: () => Navigator.pop(context)),
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.shield_rounded, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Text('لوحة التحكم', style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        centerTitle: true,
        actions: [IconButton(icon: Icon(Icons.refresh_rounded, color: t.text.withOpacity(0.7)), onPressed: _loadAll)],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: t.button,
          indicatorWeight: 3,
          labelColor: t.button,
          unselectedLabelColor: t.text.withOpacity(0.4),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: [
            const Tab(text: 'نظرة عامة', icon: Icon(Icons.analytics_outlined, size: 18)),
            const Tab(text: 'الثيمات', icon: Icon(Icons.palette_outlined, size: 18)),
            Tab(text: 'المستخدمون (${_users.length})', icon: const Icon(Icons.people_alt_outlined, size: 18)),
            Tab(text: 'الطلبات (${_requests.where((r) => r.status == "pending").length})', icon: const Icon(Icons.note_add_outlined, size: 18)),
            Tab(text: 'البلاغات (${_reports.where((r) => r.status == "pending").length})', icon: const Icon(Icons.flag_outlined, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _overviewTab(t),
          _themesTab(t),
          _usersTab(t),
          _requestsTab(t),
          _reportsTab(t),
        ],
      ),
    );
  }

  Widget _overviewTab(AppThemeData t) {
    final online = _users.where((u) => u.isOnline).length;
    final pendingReports = _reports.where((r) => r.status == 'pending').length;
    final pendingRequests = _requests.where((r) => r.status == 'pending').length;

    return RefreshIndicator(
      onRefresh: _loadAll, color: t.button,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          GridView.count(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2, childAspectRatio: 1.6,
            crossAxisSpacing: 12, mainAxisSpacing: 12,
            children: [
              _statCard('متصلون الآن', '$online', Icons.wifi_rounded, Colors.green, t),
              _statCard('إجمالي المستخدمين', '${_users.length}', Icons.people_alt_rounded, t.button, t),
              _statCard('بلاغات معلّقة', '$pendingReports', Icons.flag_rounded, Colors.red, t),
              _statCard('طلبات غرف', '$pendingRequests', Icons.room_preferences_outlined, Colors.orange, t),
            ],
          ),
          const SizedBox(height: 20),
          _broadcastSection(t),
          const SizedBox(height: 20),
          _latestUsersSection(t),
        ]),
      ),
    );
  }

  Widget _latestUsersSection(AppThemeData t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: t.text.withOpacity(0.08))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('آخر المستخدمين', style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        ..._users.take(5).map((u) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            CircleAvatar(radius: 18, backgroundColor: t.button.withOpacity(0.2), child: Text(u.fullName.isNotEmpty ? u.fullName[0] : '?')),
            const SizedBox(width: 10),
            Expanded(child: Text(u.fullName, style: TextStyle(color: t.text, fontSize: 13))),
            Container(width: 8, height: 8, decoration: BoxDecoration(color: u.isOnline ? Colors.green : Colors.grey, shape: BoxShape.circle)),
          ]),
        )).toList(),
      ]),
    );
  }

  Widget _requestsTab(AppThemeData t) {
    if (_loadingRequests) return Center(child: CircularProgressIndicator(color: t.button));
    // إصلاح خطأ List<dynamic> بإضافة .cast<Widget>()
    return ListView(
      padding: const EdgeInsets.all(16), 
      children: _requests.map((r) => _requestCard(r, t, r.status == 'pending')).toList().cast<Widget>()
    );
  }

  Widget _reportsTab(AppThemeData t) {
    if (_loadingReports) return Center(child: CircularProgressIndicator(color: t.button));
    // إصلاح خطأ List<dynamic> بإضافة .cast<Widget>()
    return ListView(
      padding: const EdgeInsets.all(16), 
      children: _reports.map((r) => _reportCard(r, t, r.status == 'pending')).toList().cast<Widget>()
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, AppThemeData t) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Icon(icon, color: color, size: 20),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(color: t.text, fontSize: 24, fontWeight: FontWeight.w900)),
          Text(title, style: TextStyle(color: t.text.withOpacity(0.5), fontSize: 10)),
        ]),
      ]),
    );
  }

  Widget _broadcastSection(AppThemeData t) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        TextField(
          controller: _broadcastCtrl, maxLines: 2, textAlign: TextAlign.right,
          decoration: InputDecoration(hintText: 'بث رسالة لجميع المستخدمين...', border: InputBorder.none, hintStyle: TextStyle(color: t.text.withOpacity(0.5))),
          style: TextStyle(color: t.text),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_broadcastCtrl.text.isEmpty) return;
            // التأكد من استدعاء الدالة الصحيحة في DatabaseService
            await DatabaseService.broadcastMessage(_broadcastCtrl.text);
            _broadcastCtrl.clear();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text('إرسال الآن', style: TextStyle(color: Colors.white)),
        )
      ]),
    );
  }

  Widget _themesTab(AppThemeData t) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: AppThemes.allThemes.length,
      itemBuilder: (ctx, i) {
        final theme = AppThemes.allThemes[i];
        return ListTile(
          title: Text(theme.label, style: TextStyle(color: t.text)),
          onTap: () => widget.onThemeChanged(theme),
        );
      },
    );
  }

  Widget _usersTab(AppThemeData t) {
    if (_loadingUsers) return Center(child: CircularProgressIndicator());
    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (ctx, i) => ListTile(
        title: Text(_users[i].fullName, style: TextStyle(color: t.text)),
        trailing: Switch(
          value: _users[i].isBanned, 
          onChanged: (v) => _toggleBan(_users[i], i)
        ),
      ),
    );
  }

  Future<void> _toggleBan(AppUser u, int index) async {
    await DatabaseService.banUser(u.id, !u.isBanned);
    _loadUsers();
  }

  Widget _requestCard(AppRoomRequest req, AppThemeData t, bool actions) {
    return Card(
      color: t.card, 
      child: ListTile(
        title: Text(req.name, style: TextStyle(color: t.text)), 
        subtitle: Text(req.status, style: TextStyle(color: t.text.withOpacity(0.7)))
      )
    );
  }

  Widget _reportCard(AppReport rep, AppThemeData t, bool actions) {
    return Card(
      color: t.card, 
      child: ListTile(
        title: Text(rep.reason, style: TextStyle(color: t.text)), 
        subtitle: Text(rep.targetName, style: TextStyle(color: t.text.withOpacity(0.7)))
      )
    );
  }
}
