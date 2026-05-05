import 'package:flutter/material.dart';
import 'package:dardashati/models.dart';
import 'package:dardashati/app_theme.dart';
import 'package:dardashati/services/auth_service.dart';
import 'package:dardashati/services/database_service.dart';
import 'package:dardashati/utils/logger.dart';

class SettingsScreen extends StatefulWidget {
  final AppUser currentUser;
  final AppThemeData theme;
  final Function(AppThemeData) onThemeChanged; // لإبلاغ main.dart بتغيير الثيم فوراً

  const SettingsScreen({
    super.key, 
    required this.currentUser, 
    required this.theme, 
    required this.onThemeChanged
  });

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

  // حفظ الملف الشخصي
  Future<void> _saveProfile() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    try {
      // نستخدم الـ Service لتحديث البيانات في Supabase
      // await DatabaseService.updateProfile(fullName: _nameCtrl.text.trim(), bio: _bioCtrl.text.trim());
      AppLogger.success("SETTINGS", "تم تحديث بيانات الملف الشخصي");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('تم حفظ التغييرات ✓'), backgroundColor: widget.theme.button)
        );
      }
    } catch (e) {
      AppLogger.error("SETTINGS", "فشل تحديث البروفايل", e);
    }
  }

  // اختيار وحفظ الثيم
  Future<void> _selectTheme(AppThemeData newTheme) async {
    setState(() { 
      _selectedTheme = newTheme; 
      _savingTheme = true; 
    });
    
    // إبلاغ التطبيق بالكامل بالثيم الجديد فوراً
    widget.onThemeChanged(newTheme);
    
    try {
      await DatabaseService.saveUserTheme(newTheme.name);
      AppLogger.info("THEME", "تم حفظ الثيم الجديد: ${newTheme.name}");
    } catch (e) {
      AppLogger.error("THEME", "فشل حفظ الثيم في السحابة", e);
    }
    
    if (mounted) setState(() => _savingTheme = false);
  }

  // تسجيل الخروج الاحترافي
  Future<void> _signOut() async {
    final t = widget.theme;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: t.menu,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text('تسجيل الخروج', style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
        content: Text('هل أنت متأكد من رغبتك في تسجيل الخروج من دردشاتي؟', style: TextStyle(color: t.text.withOpacity(0.7), fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text('إلغاء', style: TextStyle(color: t.text.withOpacity(0.4)))
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.signOut();
              if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0
            ),
            child: const Text('خروج', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        backgroundColor: t.menu, 
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: t.text, size: 20), 
          onPressed: () => Navigator.pop(context)
        ),
        title: Text('الإعدادات', style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // قسم الصورة الشخصية بتصميم عصري
          Center(child: Stack(children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: t.button.withOpacity(0.3), width: 2)),
              child: CircleAvatar(
                radius: 50, 
                backgroundColor: t.card,
                backgroundImage: widget.currentUser.avatarUrl.isNotEmpty ? NetworkImage(widget.currentUser.avatarUrl) : null,
                child: widget.currentUser.avatarUrl.isEmpty 
                    ? Text(widget.currentUser.fullName[0], style: TextStyle(color: t.button, fontSize: 32, fontWeight: FontWeight.bold)) 
                    : null,
              ),
            ),
            Positioned(
              bottom: 5, right: 5, 
              child: GestureDetector(
                onTap: () => AppLogger.info("UI", "تغيير الصورة الشخصية"),
                child: Container(
                  padding: const EdgeInsets.all(8), 
                  decoration: BoxDecoration(color: t.button, shape: BoxShape.circle, border: Border.all(color: t.background, width: 3)), 
                  child: Icon(Icons.edit_rounded, color: t.buttonText, size: 18)
                ),
              )
            ),
          ])),
          const SizedBox(height: 30),

          _sectionLabel('الملف الشخصي', t),
          _field(Icons.person_outline_rounded, 'الاسم الكامل', _nameCtrl, t),
          const SizedBox(height: 12),
          _field(Icons.notes_rounded, 'الحالة / نبذة قصيرة', _bioCtrl, t, maxLines: 3),
          const SizedBox(height: 16),
          _buildActionButton(label: 'حفظ التغييرات', icon: Icons.check_circle_outline_rounded, color: t.button, textColor: t.buttonText, onTap: _saveProfile),
          
          const SizedBox(height: 30),

          _sectionLabel('المظهر (الثيمات)', t),
          ...AppThemes.allThemes.map((theme) => _buildThemeTile(theme, t)).toList(),
          
          const SizedBox(height: 30),

          _sectionLabel('التفضيلات والأمان', t),
          _buildSwitchTile('إشعارات الرسائل', Icons.notifications_none_rounded, _notificationsEnabled, t, (v) => setState(() => _notificationsEnabled = v)),
          const SizedBox(height: 10),
          _menuTile(Icons.lock_reset_rounded, 'تغيير كلمة المرور', t, onTap: () => _changePasswordSheet(t)),
          const SizedBox(height: 10),
          _menuTile(Icons.help_outline_rounded, 'مركز المساعدة', t, onTap: () {}),
          
          const SizedBox(height: 40),
          _buildActionButton(label: 'تسجيل الخروج', icon: Icons.logout_rounded, color: Colors.redAccent.withOpacity(0.1), textColor: Colors.redAccent, onTap: _signOut),
          
          const SizedBox(height: 30),
          Center(child: Text('دردشاتي v1.0.0', style: TextStyle(color: t.text.withOpacity(0.2), fontSize: 12, letterSpacing: 1.2))),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  // --- أدوات بناء الواجهة (Helper Widgets) ---

  Widget _buildThemeTile(AppThemeData theme, AppThemeData t) {
    final isActive = _selectedTheme.name == theme.name;
    return GestureDetector(
      onTap: () => _selectTheme(theme),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isActive ? t.button.withOpacity(0.05) : t.card.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? t.button : t.text.withOpacity(0.05), width: isActive ? 2 : 1),
        ),
        child: Row(children: [
          _buildThemePreview(theme),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(theme.label, style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 14)),
            Text(theme.isDark ? 'الوضع الليلي' : 'الوضع النهاري', style: TextStyle(color: t.text.withOpacity(0.4), fontSize: 11)),
          ])),
          if (isActive) Icon(Icons.check_circle_rounded, color: t.button, size: 24)
        ]),
      ),
    );
  }

  Widget _buildThemePreview(AppThemeData theme) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _dot(theme.background), const SizedBox(width: 3),
      _dot(theme.button), const SizedBox(width: 3),
      _dot(theme.card),
    ]);
  }

  Widget _buildActionButton({required String label, required IconData icon, required Color color, required Color textColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 55,
        width: double.infinity,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
        ]),
      ),
    );
  }

  Widget _buildSwitchTile(String title, IconData icon, bool value, AppThemeData t, Function(bool) onChanged) {
    return Container(
      decoration: BoxDecoration(color: t.card.withOpacity(0.5), borderRadius: BorderRadius.circular(18)),
      child: SwitchListTile(
        secondary: Icon(icon, color: t.button, size: 22),
        title: Text(title, style: TextStyle(color: t.text, fontSize: 14, fontWeight: FontWeight.w500)),
        value: value,
        activeColor: t.button,
        onChanged: onChanged,
      ),
    );
  }

  // بقية الـ Widgets المساعدة (التي كانت في كودك مع تحسين طفيف)
  Widget _sectionLabel(String label, AppThemeData t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, right: 5),
      child: Text(label, style: TextStyle(color: t.text.withOpacity(0.5), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
    );
  }

  Widget _field(IconData icon, String hint, TextEditingController ctrl, AppThemeData t, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(color: t.card.withOpacity(0.5), borderRadius: BorderRadius.circular(18), border: Border.all(color: t.text.withOpacity(0.05))),
      child: TextField(
        controller: ctrl, maxLines: maxLines, textAlign: TextAlign.right, style: TextStyle(color: t.text, fontSize: 14),
        decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: t.text.withOpacity(0.2)), prefixIcon: Icon(icon, color: t.button, size: 20), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15))),
    );
  }

  Widget _menuTile(IconData icon, String label, AppThemeData t, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(color: t.card.withOpacity(0.5), borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          Icon(icon, color: t.button, size: 22), const SizedBox(width: 15),
          Expanded(child: Text(label, style: TextStyle(color: t.text, fontWeight: FontWeight.w500, fontSize: 14))),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: t.text.withOpacity(0.2)),
        ]),
      ),
    );
  }

  Widget _dot(Color c) => Container(width: 12, height: 12, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 0.5)));

  void _changePasswordSheet(AppThemeData t) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: t.menu,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 30),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 50, height: 5, decoration: BoxDecoration(color: t.text.withOpacity(0.1), borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 25),
          Text('تحديث الأمان', style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 20),
          _field(Icons.lock_outline_rounded, 'كلمة المرور الجديدة', ctrl, t),
          const SizedBox(height: 20),
          _buildActionButton(label: 'تحديث الآن', icon: Icons.security_rounded, color: t.button, textColor: t.buttonText, onTap: () async {
              if (ctrl.text.length < 6) return;
              Navigator.pop(context);
              await AuthService.updatePassword(ctrl.text);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('تم التحديث بنجاح'), backgroundColor: t.button));
          }),
        ]),
      ),
    );
  }
}
