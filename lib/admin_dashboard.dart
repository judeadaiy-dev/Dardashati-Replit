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
    // السطر التالي يجلب معرف المستخدم الحالي من سوبابيز
    final String currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    
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
        // ... باقي الكود
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

          // بث جماعي
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
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✓ تم الإرسال (تجريبي) لـ ${_users.length} مستخدم'), backgroundColor: Colors.orange.shade700));
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
          const SizedBox(height: 20),

          // آخر المستخدمين
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: t.text.withOpacity(0.08))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('آخر المستخدمين', style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              ..._users.take(5).map((u) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  CircleAvatar(backgroundImage: u.avatarUrl.isNotEmpty ? NetworkImage(u.avatarUrl) : null, radius: 18, backgroundColor: t.button.withOpacity(0.2), child: u.avatarUrl.isEmpty ? Text(u.fullName[0], style: TextStyle(color: t.button)) : null),
                  const SizedBox(width: 10),
                  Expanded(child: Text(u.fullName, style: TextStyle(color: t.text, fontWeight: FontWeight.w500, fontSize: 13))),
                  if (u.isBanned) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: const Text('محظور', style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 6),
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: u.isOnline ? Colors.green : Colors.grey.shade400, shape: BoxShape.circle)),
                ]),
              )).toList(),
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
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تطبيق ثيم "${theme.label}"'), backgroundColor: theme.button));
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive ? t.button.withOpacity(0.08) : t.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isActive ? t.button : t.text.withOpacity(0.08), width: isActive ? 2 : 1),
              boxShadow: isActive ? [BoxShadow(color: t.button.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 4))] : null,
            ),
            child: Row(children: [
              Row(children: [_dot(theme.background), const SizedBox(width: 4), _dot(theme.button), const SizedBox(width: 4), _dot(theme.accent)]),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(theme.label, style: TextStyle(color: isActive ? t.button : t.text, fontWeight: FontWeight.bold, fontSize: 13)),
                Text(theme.isDark ? '🌙 داكن' : '☀️ فاتح', style: TextStyle(color: t.text.withOpacity(0.4), fontSize: 11)),
              ])),
              if (isActive)
                Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: t.button, shape: BoxShape.circle), child: Icon(Icons.check, color: t.buttonText, size: 14))
              else
                Container(width: 28, height: 28, decoration: BoxDecoration(border: Border.all(color: t.text.withOpacity(0.2)), shape: BoxShape.circle)),
            ]),
          ),
        );
      },
    );
  }

  Widget _dot(Color c) => Container(width: 20, height: 20, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.black.withOpacity(0.08))));

  // ==================== المستخدمون ====================
  Widget _usersTab(AppThemeData t) {
    if (_loadingUsers) return Center(child: CircularProgressIndicator(color: t.button));
    return RefreshIndicator(
      onRefresh: _loadUsers, color: t.button,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (ctx, i) => _userCard(_users[i], t, i),
      ),
    );
  }

  Widget _userCard(AppUser u, AppThemeData t, int index) {
    Color roleColor; String roleLabel;
    switch (u.role) {
      case 'admin': roleColor = Colors.red; roleLabel = 'مشرف'; break;
      case 'moderator': roleColor = Colors.orange; roleLabel = 'مراقب'; break;
      default: roleColor = t.accent; roleLabel = 'عضو'; break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: u.isBanned ? Colors.red.withOpacity(0.05) : t.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: u.isBanned ? Colors.red.withOpacity(0.2) : t.text.withOpacity(0.08)),
      ),
      child: Column(children: [
        Row(children: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: u.id, currentUserId: AuthService.currentUserId ?? '', theme: t))),
            child: Stack(children: [
              CircleAvatar(backgroundImage: u.avatarUrl.isNotEmpty ? NetworkImage(u.avatarUrl) : null, radius: 22, backgroundColor: t.button.withOpacity(0.2), child: u.avatarUrl.isEmpty ? Text(u.fullName[0], style: TextStyle(color: t.button)) : null),
              if (u.isOnline) Positioned(bottom: 0, right: 0, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: t.card, width: 2)))),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(u.fullName, style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: roleColor.withOpacity(0.12), borderRadius: BorderRadius.circular(7)), child: Text(roleLabel, style: TextStyle(color: roleColor, fontSize: 9, fontWeight: FontWeight.bold))),
              if (u.isBanned) ...[const SizedBox(width: 4), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.red.withOpacity(0.12), borderRadius: BorderRadius.circular(7)), child: const Text('محظور', style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold)))],
            ]),
            const SizedBox(height: 3),
            Text(u.isOnline ? '🟢 متصل' : '⚫ غير متصل', style: TextStyle(color: t.text.withOpacity(0.4), fontSize: 11)),
          ])),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: ElevatedButton(
            onPressed: () => _toggleBan(u, index),
            style: ElevatedButton.styleFrom(backgroundColor: u.isBanned ? Colors.green.shade600 : Colors.red.shade600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0, padding: const EdgeInsets.symmetric(vertical: 8)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(u.isBanned ? Icons.lock_open_outlined : Icons.block_rounded, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(u.isBanned ? 'رفع الحظر' : 'حظر', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ]),
          )),
        ]),
      ]),
    );
  }

  Future<void> _toggleBan(AppUser u, int index) async {
    final isBanned = u.isBanned;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: widget.currentTheme.menu,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isBanned ? 'رفع الحظر' : 'حظر المستخدم', style: TextStyle(color: widget.currentTheme.text, fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من ${isBanned ? "رفع الحظر عن" : "حظر"} ${u.fullName}؟', style: TextStyle(color: widget.currentTheme.text.withOpacity(0.7))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء', style: TextStyle(color: widget.currentTheme.text.withOpacity(0.4)))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try { await DatabaseService.banUser(u.id, !isBanned); } catch (_) {}
              await _loadUsers();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isBanned ? 'تم رفع الحظر عن ${u.fullName}' : 'تم حظر ${u.fullName}'), backgroundColor: isBanned ? Colors.green.shade600 : Colors.red.shade600));
            },
            style: ElevatedButton.styleFrom(backgroundColor: isBanned ? Colors.green.shade600 : Colors.red.shade600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(isBanned ? 'رفع الحظر' : 'حظر', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==================== الطلبات ====================
  Widget _requestsTab(AppThemeData t) {
    if (_loadingRequests) return Center(child: CircularProgressIndicator(color: t.button));
    final pending = _requests.where((r) => r.status == 'pending').toList();
    final reviewed = _requests.where((r) => r.status != 'pending').toList();

    return RefreshIndicator(
      onRefresh: _loadRequests, color: t.button,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (pending.isEmpty) _emptyState('لا توجد طلبات جديدة', Icons.check_circle_outline, Colors.green, t),
          if (pending.isNotEmpty) ...[
            _sectionHeader('معلّقة (${pending.length})', Colors.orange, t),
            ...pending.map((r) => _requestCard(r, t, true)).toList(),
            const SizedBox(height: 16),
          ],
          if (reviewed.isNotEmpty) ...[
            _sectionHeader('مراجَعة (${reviewed.length})', t.text.withOpacity(0.4), t),
            ...reviewed.map((r) => _requestCard(r, t, false)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _requestCard(AppRoomRequest req, AppThemeData t, bool showActions) {
    Color statusColor = req.status == 'approved' ? Colors.green : req.status == 'rejected' ? Colors.red : Colors.orange;
    String statusLabel = req.status == 'approved' ? 'موافق عليه' : req.status == 'rejected' ? 'مرفوض' : 'معلّق';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: t.button.withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: Center(child: Text(req.icon, style: const TextStyle(fontSize: 24)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(req.name, style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 3),
            Text(req.description, style: TextStyle(color: t.text.withOpacity(0.5), fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 10),
        Text('طلب من: ${req.requesterName}', style: TextStyle(color: t.text.withOpacity(0.45), fontSize: 12)),
        if (showActions) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: ElevatedButton(
              onPressed: () => _updateRequest(req, 'approved'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              child: const Text('قبول', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton(
              onPressed: () => _updateRequest(req, 'rejected'),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text('رفض', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold)),
            )),
          ]),
        ],
      ]),
    );
  }

  Future<void> _updateRequest(AppRoomRequest req, String status) async {
    try {
      await DatabaseService.updateRoomRequestStatus(req.id, status);
      await _loadRequests();
    } catch (_) {
      setState(() {
        final idx = _requests.indexWhere((r) => r.id == req.id);
        if (idx != -1) _requests[idx].status = status;
      });
    }
    final label = status == 'approved' ? 'تمت الموافقة' : 'تم الرفض';
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label على غرفة "${req.name}"'), backgroundColor: status == 'approved' ? Colors.green.shade600 : Colors.red.shade600));
  }

  // ==================== البلاغات ====================
  Widget _reportsTab(AppThemeData t) {
    if (_loadingReports) return Center(child: CircularProgressIndicator(color: t.button));
    final pending = _reports.where((r) => r.status == 'pending').toList();
    final resolved = _reports.where((r) => r.status == 'resolved').toList();

    return RefreshIndicator(
      onRefresh: _loadReports, color: t.button,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (pending.isEmpty) _emptyState('لا توجد بلاغات معلّقة ✅', Icons.security_rounded, Colors.green, t),
          if (pending.isNotEmpty) ...[
            _sectionHeader('معلّقة (${pending.length})', Colors.red, t),
            ...pending.map((r) => _reportCard(r, t, true)).toList(),
            const SizedBox(height: 16),
          ],
          if (resolved.isNotEmpty) ...[
            _sectionHeader('محلولة (${resolved.length})', t.text.withOpacity(0.4), t),
            ...resolved.map((r) => _reportCard(r, t, false)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _reportCard(AppReport rep, AppThemeData t, bool showActions) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: rep.status == 'pending' ? Colors.red.withOpacity(0.2) : t.text.withOpacity(0.08))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Icon(Icons.flag_rounded, color: rep.status == 'pending' ? Colors.red : Colors.grey, size: 18),
            const SizedBox(width: 6),
            Text('بلاغ', style: TextStyle(color: rep.status == 'pending' ? Colors.red : t.text.withOpacity(0.5), fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
          Text(_fmtDate(rep.timestamp), style: TextStyle(color: t.text.withOpacity(0.3), fontSize: 11)),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: t.background, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Expanded(child: Column(children: [
              CircleAvatar(backgroundImage: NetworkImage('https://i.pravatar.cc/80?u=${rep.targetId}'), radius: 18),
              const SizedBox(height: 4),
              Text('المُبلَّغ عنه', style: TextStyle(color: t.text.withOpacity(0.35), fontSize: 9)),
              Text(rep.targetName, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
            ])),
            Container(width: 1, height: 40, color: t.text.withOpacity(0.1)),
            Expanded(child: Column(children: [
              CircleAvatar(backgroundImage: NetworkImage('https://i.pravatar.cc/80?u=${rep.reporterId}'), radius: 18),
              const SizedBox(height: 4),
              Text('المُبلِّغ', style: TextStyle(color: t.text.withOpacity(0.35), fontSize: 9)),
              Text(rep.reporterName, style: TextStyle(color: t.text.withOpacity(0.7), fontWeight: FontWeight.bold, fontSize: 12)),
            ])),
          ]),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: t.button.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: t.button.withOpacity(0.1))),
          child: Row(children: [
            Icon(Icons.format_quote_rounded, color: t.button, size: 16),
            const SizedBox(width: 6),
            Expanded(child: Text(rep.reason, style: TextStyle(color: t.text.withOpacity(0.7), fontSize: 12, fontStyle: FontStyle.italic))),
          ]),
        ),
        if (showActions) ...[
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _resolveReport(rep),
            icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
            label: const Text('تحديد كمحلول', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: t.button, minimumSize: const Size(double.infinity, 44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
          ),
        ] else Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: [const Icon(Icons.check_circle, color: Colors.green, size: 16), const SizedBox(width: 6), const Text('تم الحل', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold))])),
      ]),
    );
  }

  Future<void> _resolveReport(AppReport rep) async {
    try {
      await DatabaseService.updateReportStatus(rep.id, 'resolved');
      await _loadReports();
    } catch (_) {
      setState(() {
        final idx = _reports.indexWhere((r) => r.id == rep.id);
        if (idx != -1) _reports[idx].status = 'resolved';
      });
    }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('تم تحديد البلاغ كمحلول'), backgroundColor: Colors.green.shade600));
  }

  // ==================== مساعدات ====================
  Widget _sectionHeader(String label, Color color, AppThemeData t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
    );
  }

  Widget _emptyState(String msg, IconData icon, Color color, AppThemeData t) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 40),
      child: Column(children: [
        Icon(icon, size: 52, color: color.withOpacity(0.35)),
        const SizedBox(height: 12),
        Text(msg, style: TextStyle(color: t.text.withOpacity(0.35), fontSize: 14), textAlign: TextAlign.center),
      ]),
    );
  }

  String _fmtDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
} 
فلنصلح هذة اولا import 'package:supabase_flutter/supabase_flutter.dart';
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
    // السطر التالي يجلب معرف المستخدم الحالي من سوبابيز
    final String currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    
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
        // ... باقي الكود
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

          // بث جماعي
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
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✓ تم الإرسال (تجريبي) لـ ${_users.length} مستخدم'), backgroundColor: Colors.orange.shade700));
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
          const SizedBox(height: 20),

          // آخر المستخدمين
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: t.text.withOpacity(0.08))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('آخر المستخدمين', style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              ..._users.take(5).map((u) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  CircleAvatar(backgroundImage: u.avatarUrl.isNotEmpty ? NetworkImage(u.avatarUrl) : null, radius: 18, backgroundColor: t.button.withOpacity(0.2), child: u.avatarUrl.isEmpty ? Text(u.fullName[0], style: TextStyle(color: t.button)) : null),
                  const SizedBox(width: 10),
                  Expanded(child: Text(u.fullName, style: TextStyle(color: t.text, fontWeight: FontWeight.w500, fontSize: 13))),
                  if (u.isBanned) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: const Text('محظور', style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 6),
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: u.isOnline ? Colors.green : Colors.grey.shade400, shape: BoxShape.circle)),
                ]),
              )).toList(),
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
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تطبيق ثيم "${theme.label}"'), backgroundColor: theme.button));
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive ? t.button.withOpacity(0.08) : t.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isActive ? t.button : t.text.withOpacity(0.08), width: isActive ? 2 : 1),
              boxShadow: isActive ? [BoxShadow(color: t.button.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 4))] : null,
            ),
            child: Row(children: [
              Row(children: [_dot(theme.background), const SizedBox(width: 4), _dot(theme.button), const SizedBox(width: 4), _dot(theme.accent)]),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(theme.label, style: TextStyle(color: isActive ? t.button : t.text, fontWeight: FontWeight.bold, fontSize: 13)),
                Text(theme.isDark ? '🌙 داكن' : '☀️ فاتح', style: TextStyle(color: t.text.withOpacity(0.4), fontSize: 11)),
              ])),
              if (isActive)
                Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: t.button, shape: BoxShape.circle), child: Icon(Icons.check, color: t.buttonText, size: 14))
              else
                Container(width: 28, height: 28, decoration: BoxDecoration(border: Border.all(color: t.text.withOpacity(0.2)), shape: BoxShape.circle)),
            ]),
          ),
        );
      },
    );
  }

  Widget _dot(Color c) => Container(width: 20, height: 20, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.black.withOpacity(0.08))));

  // ==================== المستخدمون ====================
  Widget _usersTab(AppThemeData t) {
    if (_loadingUsers) return Center(child: CircularProgressIndicator(color: t.button));
    return RefreshIndicator(
      onRefresh: _loadUsers, color: t.button,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (ctx, i) => _userCard(_users[i], t, i),
      ),
    );
  }

  Widget _userCard(AppUser u, AppThemeData t, int index) {
    Color roleColor; String roleLabel;
    switch (u.role) {
      case 'admin': roleColor = Colors.red; roleLabel = 'مشرف'; break;
      case 'moderator': roleColor = Colors.orange; roleLabel = 'مراقب'; break;
      default: roleColor = t.accent; roleLabel = 'عضو'; break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: u.isBanned ? Colors.red.withOpacity(0.05) : t.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: u.isBanned ? Colors.red.withOpacity(0.2) : t.text.withOpacity(0.08)),
      ),
      child: Column(children: [
        Row(children: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: u.id, currentUserId: AuthService.currentUserId ?? '', theme: t))),
            child: Stack(children: [
              CircleAvatar(backgroundImage: u.avatarUrl.isNotEmpty ? NetworkImage(u.avatarUrl) : null, radius: 22, backgroundColor: t.button.withOpacity(0.2), child: u.avatarUrl.isEmpty ? Text(u.fullName[0], style: TextStyle(color: t.button)) : null),
              if (u.isOnline) Positioned(bottom: 0, right: 0, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: t.card, width: 2)))),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(u.fullName, style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: roleColor.withOpacity(0.12), borderRadius: BorderRadius.circular(7)), child: Text(roleLabel, style: TextStyle(color: roleColor, fontSize: 9, fontWeight: FontWeight.bold))),
              if (u.isBanned) ...[const SizedBox(width: 4), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.red.withOpacity(0.12), borderRadius: BorderRadius.circular(7)), child: const Text('محظور', style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold)))],
            ]),
            const SizedBox(height: 3),
            Text(u.isOnline ? '🟢 متصل' : '⚫ غير متصل', style: TextStyle(color: t.text.withOpacity(0.4), fontSize: 11)),
          ])),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: ElevatedButton(
            onPressed: () => _toggleBan(u, index),
            style: ElevatedButton.styleFrom(backgroundColor: u.isBanned ? Colors.green.shade600 : Colors.red.shade600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0, padding: const EdgeInsets.symmetric(vertical: 8)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(u.isBanned ? Icons.lock_open_outlined : Icons.block_rounded, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(u.isBanned ? 'رفع الحظر' : 'حظر', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ]),
          )),
        ]),
      ]),
    );
  }

  Future<void> _toggleBan(AppUser u, int index) async {
    final isBanned = u.isBanned;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: widget.currentTheme.menu,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isBanned ? 'رفع الحظر' : 'حظر المستخدم', style: TextStyle(color: widget.currentTheme.text, fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من ${isBanned ? "رفع الحظر عن" : "حظر"} ${u.fullName}؟', style: TextStyle(color: widget.currentTheme.text.withOpacity(0.7))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء', style: TextStyle(color: widget.currentTheme.text.withOpacity(0.4)))),
          ElevatedButton(
                        onPressed: () async {
              Navigator.pop(context);
              try { await DatabaseService.banUser(u.id, !isBanned); } catch (_) {}
              await _loadUsers();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isBanned ? 'تم رفع الحظر عن ${u.fullName}' : 'تم حظر ${u.fullName}'),
                    backgroundColor: isBanned ? Colors.green.shade600 : Colors.red.shade600,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isBanned ? Colors.green.shade600 : Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(isBanned ? 'رفع الحظر' : 'حظر', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}


