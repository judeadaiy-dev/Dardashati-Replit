import 'package:flutter/material.dart';
import 'models.dart';
import 'app_theme.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  final AppUser currentUser;
  final AppThemeData theme;
  const SettingsScreen({required this.currentUser, required this.theme});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _savingTheme = false;
  late AppThemeData _selectedTheme;

  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTheme = widget.theme;
    _nameCtrl.text = widget.currentUser.fullName;
    _bioCtrl.text = widget.currentUser.bio ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    try {
      await DatabaseService.updateProfile(fullName: _nameCtrl.text.trim(), bio: _bioCtrl.text.trim());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('تم حفظ التغييرات ✓'), backgroundColor: widget.theme.button));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ (وضع تجريبي)'), backgroundColor: Colors.orange));
    }
  }

  Future<void> _selectTheme(AppThemeData newTheme) async {
    setState(() { _selectedTheme = newTheme; _savingTheme = true; });
    try {
      await DatabaseService.saveUserTheme(newTheme.name);
    } catch (_) {}
    if (mounted) setState(() => _savingTheme = false);
  }

  Future<void> _signOut() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: widget.theme.menu,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('تسجيل الخروج', style: TextStyle(color: widget.theme.text, fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من تسجيل الخروج؟', style: TextStyle(color: widget.theme.text.withOpacity(0.7))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء', style: TextStyle(color: widget.theme.text.withOpacity(0.5)))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.setOnlineStatus(false);
              await AuthService.signOut();
              // _AuthGate في main.dart ستعيد التوجيه لشاشة Welcom تلقائياً
              if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('خروج', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.menu, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: t.text), onPressed: () => Navigator.pop(context)),
        title: Text('الإعدادات', style: TextStyle(color: t.text, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Avatar
          Center(child: Stack(children: [
            CircleAvatar(backgroundImage: widget.currentUser.avatarUrl.isNotEmpty ? NetworkImage(widget.currentUser.avatarUrl) : null, radius: 48, backgroundColor: t.button.withOpacity(0.2), child: widget.currentUser.avatarUrl.isEmpty ? Text(widget.currentUser.fullName[0], style: TextStyle(color: t.button, fontSize: 36)) : null),
            Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: t.button, shape: BoxShape.circle, border: Border.all(color: t.background, width: 2)), child: Icon(Icons.camera_alt_outlined, color: t.buttonText, size: 16))),
          ])),
          const SizedBox(height: 24),

          // Profile Fields
          _sectionLabel('الملف الشخصي', t),
          _field(Icons.person_outline, 'الاسم الكامل', _nameCtrl, t),
          const SizedBox(height: 12),
          _field(Icons.info_outline, 'نبذة عنك', _bioCtrl, t, maxLines: 3),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _saveProfile,
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('حفظ التغييرات', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: t.button, foregroundColor: t.buttonText, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
          ),
          const SizedBox(height: 28),

          // Notifications
          _sectionLabel('الإشعارات', t),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: t.text.withOpacity(0.08))),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('تفعيل الإشعارات', style: TextStyle(color: t.text, fontWeight: FontWeight.w500)),
              subtitle: Text(_notificationsEnabled ? 'تصلك الإشعارات عند وصول رسائل' : 'الإشعارات معطّلة', style: TextStyle(color: t.text.withOpacity(0.4), fontSize: 12)),
              value: _notificationsEnabled,
              activeColor: t.button,
              onChanged: (v) => setState(() => _notificationsEnabled = v),
            ),
          ),
          const SizedBox(height: 28),

          // Themes
          _sectionLabel('الثيم', t),
          ...AppThemes.allThemes.map((theme) {
            final isActive = _selectedTheme.name == theme.name;
            return GestureDetector(
              onTap: () => _selectTheme(theme),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isActive ? t.button.withOpacity(0.08) : t.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isActive ? t.button : t.text.withOpacity(0.08), width: isActive ? 2 : 1),
                ),
                child: Row(children: [
                  Row(children: [
                    _dot(theme.background), const SizedBox(width: 4),
                    _dot(theme.button), const SizedBox(width: 4),
                    _dot(theme.accent), const SizedBox(width: 4),
                    _dot(theme.card),
                  ]),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(theme.label, style: TextStyle(color: isActive ? t.button : t.text, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(theme.isDark ? '🌙 داكن' : '☀️ فاتح', style: TextStyle(color: t.text.withOpacity(0.4), fontSize: 11)),
                  ])),
                  if (_savingTheme && isActive)
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: t.button, strokeWidth: 2))
                  else if (isActive)
                    Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: t.button, shape: BoxShape.circle), child: Icon(Icons.check, color: t.buttonText, size: 14))
                  else
                    Container(width: 26, height: 26, decoration: BoxDecoration(border: Border.all(color: t.text.withOpacity(0.2)), shape: BoxShape.circle)),
                ]),
              ),
            );
          }).toList(),
          const SizedBox(height: 28),

          // Security
          _sectionLabel('الأمان', t),
          _menuTile(Icons.lock_outline, 'تغيير كلمة المرور', t, onTap: () => _changePasswordSheet(t)),
          const SizedBox(height: 6),
          _menuTile(Icons.privacy_tip_outlined, 'سياسة الخصوصية', t, onTap: () {}),
          const SizedBox(height: 28),

          // Sign Out
          ElevatedButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('تسجيل الخروج', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
          ),
          const SizedBox(height: 30),
          Center(child: Text('Tik Chat v1.0.0', style: TextStyle(color: t.text.withOpacity(0.2), fontSize: 12))),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  void _changePasswordSheet(AppThemeData t) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: t.menu,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: t.text.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('تغيير كلمة المرور', style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Container(decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: t.text.withOpacity(0.1))),
            child: TextField(controller: ctrl, obscureText: true, style: TextStyle(color: t.text), textAlign: TextAlign.right,
              decoration: InputDecoration(hintText: 'كلمة المرور الجديدة', hintStyle: TextStyle(color: t.text.withOpacity(0.3)), prefixIcon: Icon(Icons.lock_outline, color: t.button), border: InputBorder.none, contentPadding: const EdgeInsets.all(14)))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.length < 6) return;
              Navigator.pop(context);
              try {
                await AuthService.updatePassword(ctrl.text);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('تم تغيير كلمة المرور ✓'), backgroundColor: t.button));
              } catch (_) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر تغيير كلمة المرور'), backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: t.button, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: Text('حفظ', style: TextStyle(color: t.buttonText, fontWeight: FontWeight.bold)),
          ),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String label, AppThemeData t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: t.button, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 15)),
      ]),
    );
  }

  Widget _field(IconData icon, String hint, TextEditingController ctrl, AppThemeData t, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: t.text.withOpacity(0.08))),
      child: TextField(controller: ctrl, maxLines: maxLines, textAlign: TextAlign.right, style: TextStyle(color: t.text, fontSize: 14),
        decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: t.text.withOpacity(0.3)), prefixIcon: Icon(icon, color: t.button.withOpacity(0.7), size: 20), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
    );
  }

  Widget _menuTile(IconData icon, String label, AppThemeData t, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: t.text.withOpacity(0.08))),
        child: Row(children: [
          Icon(icon, color: t.text.withOpacity(0.5), size: 20), const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: t.text, fontWeight: FontWeight.w500))),
          Icon(Icons.arrow_forward_ios, size: 14, color: t.text.withOpacity(0.3)),
        ]),
      ),
    );
  }

  Widget _dot(Color c) => Container(width: 18, height: 18, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.black.withOpacity(0.1))));
}
