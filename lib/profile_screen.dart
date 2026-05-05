import 'package:flutter/material.dart';
import 'package:dardashati/models.dart';
import 'package:dardashati/app_theme.dart';
import 'package:dardashati/services/database_service.dart';
import 'package:dardashati/utils/logger.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final String currentUserId;
  final AppThemeData theme;
  
  const ProfileScreen({
    super.key, 
    required this.userId, 
    required this.currentUserId, 
    required this.theme
  });

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
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await DatabaseService.getUserById(widget.userId);
      if (mounted) {
        setState(() {
          _user = user;
          _loading = false;
        });
      }
    } catch (e) {
      AppLogger.error("PROFILE", "فشل تحميل بيانات البروفايل", e);
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showReportSheet() {
    final t = widget.theme;
    final ctrl = TextEditingController();
    
    showModalBottomSheet(
      context: context, 
      backgroundColor: t.menu,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 30),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 50, height: 5, decoration: BoxDecoration(color: t.text.withOpacity(0.1), borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 25),
          Text('الإبلاغ عن مخالفة', style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Tajawal')),
          const SizedBox(height: 10),
          Text('يرجى ذكر السبب بوضوح لمساعدة فريق الإدارة', style: TextStyle(color: t.text.withOpacity(0.5), fontSize: 13)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: t.card.withOpacity(0.5), borderRadius: BorderRadius.circular(18)),
            child: TextField(
              controller: ctrl, 
              textAlign: TextAlign.right, 
              maxLines: 3, 
              style: TextStyle(color: t.text),
              decoration: InputDecoration(
                hintText: 'مثلاً: انتحال شخصية، كلام غير لائق...', 
                hintStyle: TextStyle(color: t.text.withOpacity(0.2)),
                border: InputBorder.none
              )
            ),
          ),
          const SizedBox(height: 25),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              try {
                await DatabaseService.submitReport(targetId: widget.userId, reason: ctrl.text.trim());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text('تم إرسال البلاغ وسيقوم المشرفون بمراجعته'), backgroundColor: t.button)
                  );
                }
              } catch (e) {
                AppLogger.error("REPORT", "فشل إرسال البلاغ", e);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent, 
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 0
            ),
            child: const Text('تأكيد الإبلاغ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    
    if (_loading) return Scaffold(backgroundColor: t.background, body: Center(child: CircularProgressIndicator(color: t.button)));
    if (_user == null) return Scaffold(backgroundColor: t.background, body: const Center(child: Text('المستخدم غير موجود')));

    final u = _user!;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: t.text, size: 20), 
          onPressed: () => Navigator.pop(context)
        ),
        actions: [
          if (!_isMe) 
            IconButton(
              icon: const Icon(Icons.report_gmailerrorred_rounded, color: Colors.redAccent), 
              onPressed: _showReportSheet
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(children: [
          const SizedBox(height: 20),
          
          // الصورة الشخصية مع حالة الاتصال
          Stack(children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: t.button.withOpacity(0.2), width: 2)),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: t.card,
                backgroundImage: u.avatarUrl.isNotEmpty ? NetworkImage(u.avatarUrl) : null,
                child: u.avatarUrl.isEmpty ? Text(u.fullName[0], style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: t.button)) : null,
              ),
            ),
            if (u.isOnline)
              Positioned(
                bottom: 8, right: 8,
                child: Container(
                  width: 20, height: 20, 
                  decoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle, border: Border.all(color: t.background, width: 3))
                ),
              ),
          ]),
          
          const SizedBox(height: 20),
          Text(u.fullName, style: TextStyle(color: t.text, fontSize: 26, fontWeight: FontWeight.w900, fontFamily: 'Tajawal')),
          const SizedBox(height: 8),
          
          // شارة الرتبة (Admin / Member)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: u.role == 'admin' ? Colors.amber.withOpacity(0.1) : t.button.withOpacity(0.1), 
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: u.role == 'admin' ? Colors.amber.withOpacity(0.3) : t.button.withOpacity(0.3))
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(u.role == 'admin' ? Icons.verified_rounded : Icons.person_rounded, size: 14, color: u.role == 'admin' ? Colors.amber : t.button),
              const SizedBox(width: 6),
              Text(u.role == 'admin' ? 'مشرف النظام' : 'عضو مجتمع دردشاتي', style: TextStyle(color: u.role == 'admin' ? Colors.amber : t.button, fontWeight: FontWeight.bold, fontSize: 12)),
            ]),
          ),
          
          const SizedBox(height: 40),
          
          // قسم المعلومات
          _buildInfoSection(t, u),
          
          const SizedBox(height: 30),
          
          // زر مراسلة إذا لم يكن المستخدم هو الحالي
          if (!_isMe)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton.icon(
                onPressed: () {
                  // الانتقال لدردشة خاصة (ستقوم ببنائها لاحقاً)
                },
                icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                label: const Text('إرسال رسالة خاصة', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.button,
                  foregroundColor: t.buttonText,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0
                ),
              ),
            ),
          
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _buildInfoSection(AppThemeData t, AppUser u) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.card.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05))
      ),
      child: Column(children: [
        _detailRow(Icons.alternate_email_rounded, 'البريد الإلكتروني', u.email, t),
        const Divider(height: 30, thickness: 0.5, color: Colors.white10),
        _detailRow(Icons.description_outlined, 'النبذة التعريفية', u.bio ?? 'لا توجد نبذة حالياً', t),
        const Divider(height: 30, thickness: 0.5, color: Colors.white10),
        _detailRow(Icons.history_toggle_off_rounded, 'آخر ظهور', u.isOnline ? 'نشط الآن' : 'منذ فترة', t, 
            valueColor: u.isOnline ? Colors.greenAccent : t.text.withOpacity(0.4)),
      ]),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, AppThemeData t, {Color? valueColor}) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 22, color: t.button.withOpacity(0.6)),
      const SizedBox(width: 15),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.right, children: [
          Text(label, style: TextStyle(color: t.text.withOpacity(0.4), fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, textAlign: TextAlign.right, style: TextStyle(color: valueColor ?? t.text, fontWeight: FontWeight.w600, fontSize: 14)),
        ]),
      ),
    ]);
  }
}
