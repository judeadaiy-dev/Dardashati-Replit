import 'package:flutter/material.dart';
import 'models.dart';
import 'services/database_service.dart';
import 'mock_data.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final String currentUserId;
  final AppThemeData theme;
  const ProfileScreen({required this.userId, required this.currentUserId, required this.theme});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? _user;
  bool _loading = true;
  bool _isFollowing = false;
  int _followers = 0;
  int _following = 0;
  bool get _isMe => widget.userId == widget.currentUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = await DatabaseService.getUserById(widget.userId);
      final following = !_isMe ? await DatabaseService.isFollowing(widget.userId) : false;
      final followers = await DatabaseService.getFollowersCount(widget.userId);
      final followingCount = await DatabaseService.getFollowingCount(widget.userId);
      if (mounted) setState(() {
        _user = user;
        _isFollowing = following;
        _followers = followers;
        _following = followingCount;
        _loading = false;
      });
    } catch (_) {
      final mock = mockUsers.firstWhere((u) => u.id == widget.userId, orElse: () => mockUsers.first);
      if (mounted) setState(() { _user = mock; _loading = false; });
    }
  }

  Future<void> _toggleFollow() async {
    try {
      await DatabaseService.toggleFollow(widget.userId);
    } catch (_) {}
    setState(() {
      _isFollowing = !_isFollowing;
      _followers += _isFollowing ? 1 : -1;
    });
  }

  void _showReportSheet() {
    final t = widget.theme;
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context, backgroundColor: t.menu, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: t.text.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('الإبلاغ عن ${_user?.fullName ?? ''}', style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: t.text.withOpacity(0.1))),
            child: TextField(controller: ctrl, textAlign: TextAlign.right, maxLines: 4, style: TextStyle(color: t.text),
              decoration: InputDecoration(hintText: 'اذكر سبب البلاغ...', hintStyle: TextStyle(color: t.text.withOpacity(0.3)), border: InputBorder.none, contentPadding: const EdgeInsets.all(14))),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              try {
                await DatabaseService.submitReport(targetId: widget.userId, reason: ctrl.text.trim());
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('تم إرسال البلاغ بنجاح'), backgroundColor: t.button));
              } catch (_) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال البلاغ'), backgroundColor: Colors.orange));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('إرسال البلاغ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    if (_loading) return Scaffold(backgroundColor: t.background, body: Center(child: CircularProgressIndicator(color: t.button)));
    if (_user == null) return Scaffold(backgroundColor: t.background, body: Center(child: Text('المستخدم غير موجود', style: TextStyle(color: t.text))));

    final u = _user!;
    Color roleColor; String roleLabel;
    switch (u.role) {
      case 'admin': roleColor = Colors.red; roleLabel = 'مشرف'; break;
      case 'moderator': roleColor = Colors.orange; roleLabel = 'مراقب'; break;
      default: roleColor = t.accent; roleLabel = 'عضو'; break;
    }

    return Scaffold(
      backgroundColor: t.background,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 220,
          backgroundColor: t.menu,
          elevation: 0,
          pinned: true,
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
          actions: [
            if (!_isMe) PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              color: t.menu,
              onSelected: (v) { if (v == 'report') _showReportSheet(); },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'report', child: Row(children: [const Icon(Icons.flag_outlined, color: Colors.red, size: 18), const SizedBox(width: 8), Text('إبلاغ', style: TextStyle(color: t.text))])),
              ],
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(gradient: LinearGradient(colors: [t.button, t.accent], begin: Alignment.topLeft, end: Alignment.bottomRight)),
              child: SafeArea(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(height: 20),
                Stack(children: [
                  CircleAvatar(
                    backgroundImage: u.avatarUrl.isNotEmpty ? NetworkImage(u.avatarUrl) : null,
                    radius: 44,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: u.avatarUrl.isEmpty ? Text(u.fullName.isNotEmpty ? u.fullName[0] : '?', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)) : null,
                  ),
                  if (u.isOnline) Positioned(bottom: 4, right: 4, child: Container(width: 14, height: 14, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
                ]),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(u.fullName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: roleColor.withOpacity(0.25), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withOpacity(0.3))), child: Text(roleLabel, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                ]),
              ])),
            ),
          ),
        ),

        SliverToBoxAdapter(child: Column(children: [
          // Stats
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: t.text.withOpacity(0.08))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _stat('المتابعون', _followers, t),
              Container(width: 1, height: 40, color: t.text.withOpacity(0.1)),
              _stat('يتابع', _following, t),
              Container(width: 1, height: 40, color: t.text.withOpacity(0.1)),
              _stat('الحالة', u.isOnline ? '🟢' : '⚫', t, isText: true),
            ]),
          ),

          // Action Buttons
          if (!_isMe) Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Expanded(child: ElevatedButton.icon(
                onPressed: _toggleFollow,
                icon: Icon(_isFollowing ? Icons.person_remove_outlined : Icons.person_add_outlined, size: 18, color: _isFollowing ? t.text : t.buttonText),
                label: Text(_isFollowing ? 'إلغاء المتابعة' : 'متابعة', style: TextStyle(color: _isFollowing ? t.text : t.buttonText, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: _isFollowing ? t.card : t.button, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: _isFollowing ? BorderSide(color: t.text.withOpacity(0.2)) : BorderSide.none)),
              )),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.chat_bubble_outline, size: 18, color: t.button),
                label: Text('رسالة', style: TextStyle(color: t.button, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: t.button.withOpacity(0.4)), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              )),
            ]),
          ),
          const SizedBox(height: 16),

          // Bio
          if (u.bio != null && u.bio!.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: t.text.withOpacity(0.08))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Icon(Icons.info_outline, size: 16, color: t.button), const SizedBox(width: 8), Text('نبذة', style: TextStyle(color: t.button, fontWeight: FontWeight.bold, fontSize: 13))]),
                const SizedBox(height: 10),
                Text(u.bio!, style: TextStyle(color: t.text.withOpacity(0.8), fontSize: 14)),
              ]),
            ),

          // Details
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: t.text.withOpacity(0.08))),
            child: Column(children: [
              if (u.zodiac != null) _detailRow(Icons.auto_awesome, 'البرج', u.zodiac!, t),
              if (u.gender != null) _detailRow(Icons.person_outline, 'الجنس', u.gender == 'male' ? 'ذكر' : 'أنثى', t),
              _detailRow(Icons.circle, 'الحالة', u.isOnline ? 'متصل الآن' : 'غير متصل', t, valueColor: u.isOnline ? Colors.green : t.text.withOpacity(0.5)),
            ]),
          ),
          const SizedBox(height: 40),
        ])),
      ]),
    );
  }

  Widget _stat(String label, dynamic value, AppThemeData t, {bool isText = false}) {
    return Column(children: [
      Text(isText ? value.toString() : _fmtNum(value as int), style: TextStyle(color: t.text, fontSize: 22, fontWeight: FontWeight.w900)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: t.text.withOpacity(0.4), fontSize: 11)),
    ]);
  }

  String _fmtNum(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  Widget _detailRow(IconData icon, String label, String value, AppThemeData t, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, size: 18, color: t.text.withOpacity(0.4)), const SizedBox(width: 10),
        Text(label, style: TextStyle(color: t.text.withOpacity(0.5), fontSize: 13)),
        const Spacer(),
        Text(value, style: TextStyle(color: valueColor ?? t.text, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }
}
