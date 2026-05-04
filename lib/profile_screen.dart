import 'package:flutter/material.dart';
import 'models.dart';
import 'services/database_service.dart';
import 'app_theme.dart'; // إصلاح خطأ عدم التعرف على AppThemeData

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
  bool get _isMe => widget.userId == widget.currentUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // استخدام الدالة الحقيقية الموجودة في DatabaseService الخاص بك
      final user = await DatabaseService.getUserById(widget.userId);
      if (mounted) {
        setState(() {
          _user = user;
          _loading = false;
        });
      }
    } catch (e) {
      // تم حذف استخدام mockUsers هنا لأنه غير موجود ويسبب فشل البناء
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showReportSheet() {
    final t = widget.theme;
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context, 
      backgroundColor: Colors.white, // تم التغيير لضمان التوافق مع التصميم الزجاجي
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: t.text.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('الإبلاغ عن ${_user?.fullName ?? ''}', style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl, 
            textAlign: TextAlign.right, 
            maxLines: 3, 
            decoration: InputDecoration(
              hintText: 'اذكر سبب البلاغ...', 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
            )
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              try {
                await DatabaseService.submitReport(targetId: widget.userId, reason: ctrl.text.trim());
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال البلاغ')));
              } catch (_) {}
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size(double.infinity, 50)),
            child: const Text('إرسال البلاغ', style: TextStyle(color: Colors.white)),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    if (_loading) return Scaffold(body: Center(child: CircularProgressIndicator(color: t.button)));
    if (_user == null) return const Scaffold(body: Center(child: Text('المستخدم غير موجود')));

    final u = _user!;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: t.text), onPressed: () => Navigator.pop(context)),
        actions: [
          if (!_isMe) IconButton(icon: const Icon(Icons.flag_outlined, color: Colors.red), onPressed: _showReportSheet),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 50,
            backgroundImage: u.avatarUrl.isNotEmpty ? NetworkImage(u.avatarUrl) : null,
            child: u.avatarUrl.isEmpty ? Text(u.fullName[0], style: const TextStyle(fontSize: 30)) : null,
          ),
          const SizedBox(height: 16),
          Text(u.fullName, style: TextStyle(color: t.text, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: t.button.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(u.role == 'admin' ? 'مشرف' : 'عضو', style: TextStyle(color: t.button, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 30),
          _detailRow(Icons.email_outlined, 'البريد الإلكتروني', u.email, t),
          if (u.bio != null) _detailRow(Icons.info_outline, 'النبذة', u.bio!, t),
          _detailRow(Icons.circle, 'الحالة', u.isOnline ? 'متصل الآن' : 'غير متصل', t, 
              valueColor: u.isOnline ? Colors.green : Colors.grey),
        ]),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, AppThemeData t, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(children: [
        Icon(icon, size: 20, color: t.text.withOpacity(0.5)),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: t.text.withOpacity(0.6))),
        const Spacer(),
        Text(value, style: TextStyle(color: valueColor ?? t.text, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
