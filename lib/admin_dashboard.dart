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

  List<AppUser> _users = [];
  List<AppReport> _reports = [];
  List<AppRoomRequest> _requests = [];
  bool _loadingUsers = true;
  bool _loadingReports = true;
  bool _loadingRequests = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        backgroundColor: t.menu, 
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: t.text), 
          onPressed: () => Navigator.pop(context)
        ),
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.shield_rounded, color: Colors.orange, size: 22),
          const SizedBox(width: 10),
          Text('لوحة التحكم الإدارية', 
            style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: t.text.withOpacity(0.7)), 
            onPressed: _loadAll
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: t.button,
          indicatorWeight: 4,
          labelColor: t.button,
          unselectedLabelColor: t.text.withOpacity(0.4),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            const Tab(text: 'نظرة عامة', icon: Icon(Icons.analytics_outlined, size: 20)),
            const Tab(text: 'الثيمات والأسلوب', icon: Icon(Icons.palette_outlined, size: 20)),
            Tab(text: 'المستخدمون (${_users.length})', icon: const Icon(Icons.people_alt_outlined, size: 20)),
            Tab(text: 'الطلبات المعلقة (${_requests.where((r) => r.status == "pending").length})', icon: const Icon(Icons.note_add_outlined, size: 20)),
            Tab(text: 'بلاغات الأمان (${_reports.where((r) => r.status == "pending").length})', icon: const Icon(Icons.flag_outlined, size: 20)),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [t.menu, t.background],
          )
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _overviewTab(t),
            _themesTab(t),
            _usersTab(t),
            _requestsTab(t),
            _reportsTab(t),
          ],
        ),
      ),
    );
  }

  Widget _overviewTab(AppThemeData t) {
    final online = _users.where((u) => u.isOnline).length;
    final pendingReports = _reports.where((r) => r.status == 'pending').length;
    final pendingRequests = _requests.where((r) => r.status == 'pending').length;

    return RefreshIndicator(
      onRefresh: _loadAll, 
      color: t.button,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          GridView.count(
            shrinkWrap: true, 
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2, 
            childAspectRatio: 1.4,
            crossAxisSpacing: 15, 
            mainAxisSpacing: 15,
            children: [
              _statCard('نشط الآن', '$online', Icons.wifi_rounded, Colors.green, t),
              _statCard('الأعضاء', '${_users.length}', Icons.people_alt_rounded, t.button, t),
              _statCard('بلاغات معلقة', '$pendingReports', Icons.flag_rounded, Colors.redAccent, t),
              _statCard('طلبات الغرف', '$pendingRequests', Icons.room_preferences_outlined, Colors.orange, t),
            ],
          ),
          const SizedBox(height: 25),
          _latestUsersSection(t),
          const SizedBox(height: 25),
          // يمكنك إضافة قسم إحصائي طويل هنا مستقبلاً
        ]),
      ),
    );
  }

  Widget _latestUsersSection(AppThemeData t) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.card.withOpacity(0.5), 
        borderRadius: BorderRadius.circular(30), 
        border: Border.all(color: t.text.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('أحدث المنضمين', style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 16)),
          Icon(Icons.person_add_alt_1_outlined, color: t.button, size: 20),
        ]),
        const SizedBox(height: 15),
        if (_loadingUsers) const Center(child: CircularProgressIndicator())
        else ..._users.take(5).map((u) => _userMiniRow(u, t)).toList(),
      ]),
    );
  }

  Widget _userMiniRow(AppUser u, AppThemeData t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        CircleAvatar(
          radius: 20, 
          backgroundColor: t.button.withOpacity(0.1), 
          child: Text(u.fullName.isNotEmpty ? u.fullName[0] : '?', style: TextStyle(color: t.button, fontWeight: FontWeight.bold))
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(u.fullName, style: TextStyle(color: t.text, fontSize: 14))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (u.isOnline ? Colors.green : Colors.grey).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)
          ),
          child: Text(u.isOnline ? 'نشط' : 'أوفلاين', style: TextStyle(color: u.isOnline ? Colors.green : Colors.grey, fontSize: 10)),
        ),
      ]),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, AppThemeData t) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.card, 
        borderRadius: BorderRadius.circular(25), 
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 15)]
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(color: t.text, fontSize: 26, fontWeight: FontWeight.w900)),
          Text(title, style: TextStyle(color: t.text.withOpacity(0.6), fontSize: 11)),
        ]),
      ]),
    );
  }

  Widget _themesTab(AppThemeData t) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: AppThemes.allThemes.length,
      itemBuilder: (ctx, i) {
        final theme = AppThemes.allThemes[i];
        bool isSelected = t.label == theme.label;
        return GestureDetector(
          onTap: () => widget.onThemeChanged(theme),
          child: Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: theme.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? t.button : Colors.transparent, width: 2),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)]
            ),
            child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: theme.button, shape: BoxShape.circle)),
              const SizedBox(width: 15),
              Text(theme.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (isSelected) Icon(Icons.check_circle_rounded, color: t.button)
            ]),
          ),
        );
      },
    );
  }

  // ميزات إدارة المستخدمين والطلبات والبلاغات كاملة
  Widget _usersTab(AppThemeData t) {
    if (_loadingUsers) return Center(child: CircularProgressIndicator(color: t.button));
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _users.length,
      itemBuilder: (ctx, i) => Card(
        color: t.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: ListTile(
          leading: CircleAvatar(backgroundColor: t.button.withOpacity(0.2), child: Text(_users[i].fullName[0], style: TextStyle(color: t.text))),
          title: Text(_users[i].fullName, style: TextStyle(color: t.text, fontWeight: FontWeight.bold)),
          subtitle: Text(_users[i].isBanned ? "محظور" : "نشط", style: TextStyle(color: _users[i].isBanned ? Colors.red : Colors.green)),
          trailing: Switch(
            activeColor: Colors.red,
            value: _users[i].isBanned, 
            onChanged: (v) => _toggleBan(_users[i], i)
          ),
        ),
      ),
    );
  }

  Future<void> _toggleBan(AppUser u, int index) async {
    await DatabaseService.banUser(u.id, !u.isBanned);
    _loadUsers();
  }

  Widget _requestsTab(AppThemeData t) {
    if (_loadingRequests) return Center(child: CircularProgressIndicator(color: t.button));
    return ListView(
      padding: const EdgeInsets.all(16), 
      children: _requests.map((r) => _requestCard(r, t)).toList().cast<Widget>()
    );
  }

  Widget _reportsTab(AppThemeData t) {
    if (_loadingReports) return Center(child: CircularProgressIndicator(color: t.button));
    return ListView(
      padding: const EdgeInsets.all(16), 
      children: _reports.map((r) => _reportCard(r, t)).toList().cast<Widget>()
    );
  }

  Widget _requestCard(AppRoomRequest req, AppThemeData t) {
    return Card(
      color: t.card, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        title: Text(req.name, style: TextStyle(color: t.text, fontWeight: FontWeight.bold)), 
        subtitle: Text('الحالة: ${req.status}', style: TextStyle(color: t.text.withOpacity(0.6))),
        trailing: Icon(Icons.more_vert, color: t.text),
      )
    );
  }

  Widget _reportCard(AppReport rep, AppThemeData t) {
    return Card(
      color: t.card, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
        title: Text(rep.reason, style: TextStyle(color: t.text, fontWeight: FontWeight.bold)), 
        subtitle: Text('ضد: ${rep.targetName}', style: TextStyle(color: t.text.withOpacity(0.6))),
        trailing: Text(rep.status, style: const TextStyle(color: Colors.orange, fontSize: 12)),
      )
    );
  }
}
