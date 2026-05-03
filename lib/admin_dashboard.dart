import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'models.dart';
import 'app_theme.dart';
import 'mock_data.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'profile_screen.dart';

class AdminDashboard extends StatefulWidget {
  final AppThemeData currentTheme;
  final Function(AppThemeData) onThemeChanged;
  const AdminDashboard({required this.currentTheme, required this.onThemeChanged, super.key});

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
      if (mounted) setState(() { _users = List.from(mockUsers); _loadingUsers = false; });
    }
  }

  Future<void> _loadReports() async {
    setState(() => _loadingReports = true);
    try {
      final data = await DatabaseService.getReports();
      if (mounted) setState(() { _reports = data; _loadingReports = false; });
    } catch (_) {
      if (mounted) setState(() { _reports = List.from(mockReports); _loadingReports = false; });
    }
  }

  Future<void> _loadRequests() async {
    setState(() => _loadingRequests = true);
    try {
      final data = await DatabaseService.getRoomRequests();
      if (mounted) setState(() { _requests = data; _loadingRequests = false; });
    } catch (_) {
      if (mounted) setState(() { _requests = List.from(mockRoomRequests); _loadingRequests = false; });
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

  // ==================== نظرة عامة ====================
  Widget _overviewTab(AppThemeData t) {
    final online = _users.where((u) => u.isOnline).length;
    final banned = _users.where((u) => u.isBanned).length;
    final pendingReports = _reports.where((r) => r.status == 'pending').length;
    final pendingRequests = _requests.where((r) => r.status == 'pending').length;

    return RefreshIndicator(
      onRefresh: _loadAll, color: t.button,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.orange.withOpacity(0.2))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.campaign_rounded, color: Colors.orange, size: 20)),
                const SizedBox(width: 10),
                Text('بث رسالة جماعية', style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 15)),
              ]),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: t.text.withOpacity(0.08))),
                child: TextField(
                  controller: _broadcastCtrl, maxLines: 3, textAlign: TextAlign.right,
                  style: TextStyle(color: t.text, fontSize: 13),
                  decoration: InputDecoration(hintText: 'اكتب رسالتك لجميع المستخدمين...', hintStyle: TextStyle(color: t.text.withOpacity(0.3), fontSize: 13), border: InputBorder.none, contentPadding: const EdgeInsets.all(14)),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _broadcasting ? null : () async {
                  if (_broadcastCtrl.text.trim().isEmpty) return;
                  setState(() => _broadcasting = true);
                  try {
                    await DatabaseService.broadcastMessage(_broadcastCtrl.text.trim());
                    _broadcastCtrl.clear();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✓ تم الإرسال لـ ${_users.length} مستخدم'), backgroundColor: Colors.orange.shade700));
                  } catch (_) {
                    _broadcastCtrl.clear();
                  }
                  if (mounted) setState(() => _broadcasting = false);
                },
                icon: _broadcasting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                label: const Text('إرسال الآن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, AppThemeData t) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(color: t.text, fontSize: 24, fontWeight: FontWeight.w900)),
          Text(title, style: TextStyle(color: t.text.withOpacity(0.5), fontSize: 10)),
        ]),
      ]),
    );
  }

  // ==================== الثيمات ====================
  Widget _themesTab(AppThemeData t) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: AppThemes.allThemes.length,
      itemBuilder: (ctx, i) {
        final theme = AppThemes.allThemes[i];
        final isActive = widget.currentTheme.name == theme.name;
        return GestureDetector(
          onTap: () {
            widget.onThemeChanged(theme);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: isActive ? t.button : t.text.withOpacity(0.08))),
            child: Row(children: [
              _dot(theme.background), const SizedBox(width: 4), _dot(theme.button),
              const SizedBox(width: 14),
              Expanded(child: Text(theme.label, style: TextStyle(color: t.text, fontWeight: FontWeight.bold))),
              if (isActive) Icon(Icons.check_circle, color: t.button)
            ]),
          ),
        );
      },
    );
  }

  Widget _dot(Color c) => Container(width: 20, height: 20, decoration: BoxDecoration(color: c, shape: BoxShape.circle));

  // ==================== المستخدمون ====================
  Widget _usersTab(AppThemeData t) {
    if (_loadingUsers) return Center(child: CircularProgressIndicator(color: t.button));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (ctx, i) => _userCard(_users[i], t, i),
    );
  }

  Widget _userCard(AppUser u, AppThemeData t, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(18)),
      child: Column(children: [
        Row(children: [
          CircleAvatar(backgroundImage: u.avatarUrl.isNotEmpty ? NetworkImage(u.avatarUrl) : null, radius: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(u.fullName, style: TextStyle(color: t.text, fontWeight: FontWeight.bold))),
          ElevatedButton(
            onPressed: () => _toggleBan(u, index),
            style: ElevatedButton.styleFrom(backgroundColor: u.isBanned ? Colors.green : Colors.red),
            child: Text(u.isBanned ? 'فك الحظر' : 'حظر', style: const TextStyle(color: Colors.white)),
          )
        ]),
      ]),
    );
  }

  Future<void> _toggleBan(AppUser u, int index) async {
    try {
      await DatabaseService.banUser(u.id, !u.isBanned);
      _loadUsers();
    } catch (_) {}
  }

  // ==================== الطلبات ====================
  Widget _requestsTab(AppThemeData t) {
    if (_loadingRequests) return Center(child: CircularProgressIndicator(color: t.button));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      itemBuilder: (ctx, i) => _requestCard(_requests[i], t, _requests[i].status == 'pending'),
    );
  }

  Widget _requestCard(AppRoomRequest req, AppThemeData t, bool showActions) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        ListTile(title: Text(req.name, style: TextStyle(color: t.text)), subtitle: Text(req.description, style: TextStyle(color: t.text.withOpacity(0.5)))),
        if (showActions) Row(children: [
          Expanded(child: TextButton(onPressed: () => _updateRequest(req, 'approved'), child: const Text('قبول'))),
          Expanded(child: TextButton(onPressed: () => _updateRequest(req, 'rejected'), child: const Text('رفض', style: TextStyle(color: Colors.red)))),
        ])
      ]),
    );
  }

  Future<void> _updateRequest(AppRoomRequest req, String status) async {
    await DatabaseService.updateRoomRequestStatus(req.id, status);
    _loadRequests();
  }

  // ==================== البلاغات ====================
  Widget _reportsTab(AppThemeData t) {
    if (_loadingReports) return Center(child: CircularProgressIndicator(color: t.button));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length,
      itemBuilder: (ctx, i) => _reportCard(_reports[i], t, _reports[i].status == 'pending'),
    );
  }

  Widget _reportCard(AppReport rep, AppThemeData t, bool showActions) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Text('بلاغ ضد: ${rep.targetName}', style: TextStyle(color: t.text, fontWeight: FontWeight.bold)),
        Text(rep.reason, style: TextStyle(color: t.text.withOpacity(0.7))),
        if (showActions) ElevatedButton(onPressed: () => _resolveReport(rep), child: const Text('تم الحل'))
      ]),
    );
  }

  Future<void> _resolveReport(AppReport rep) async {
    await DatabaseService.updateReportStatus(rep.id, 'resolved');
    _loadReports();
  }

  Widget _sectionHeader(String label, Color color, AppThemeData t) {
    return Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold));
  }

  Widget _emptyState(String msg, IconData icon, Color color, AppThemeData t) {
    return Center(child: Text(msg, style: TextStyle(color: t.text.withOpacity(0.5))));
  }

  String _fmtDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}
