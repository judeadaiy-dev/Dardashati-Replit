import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dardashati/models.dart';
import 'package:dardashati/services/session_manager.dart';
import 'package:dardashati/login_screen.dart';
import 'package:dardashati/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final AppUser currentUser;
  final AppThemeData theme;
  final Function(AppThemeData) onThemeChanged;

  const SettingsScreen({
    super.key,
    required this.currentUser,
    required this.theme,
    required this.onThemeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoggingOut = false;

  // دالة تسجيل الخروج - الطريقة الوحيدة لحذف الجلسة
  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.menu,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text(
          'تسجيل الخروج',
          style: TextStyle(
            color: widget.theme.text,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
        content: Text(
          'هل أنت متأكد من رغبتك في تسجيل الخروج من دردشاتي؟\nستحتاج إلى إدخال بيانات دخول جديدة في المرة القادمة.',
          style: TextStyle(
            color: widget.theme.text.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'إلغاء',
              style: TextStyle(color: widget.theme.text.withOpacity(0.4)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'نعم، سجل الخروج',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    setState(() => _isLoggingOut = true);

    try {
      // تسجيل الخروج من Supabase (الطريقة الوحيدة لحذف الجلسة)
      await SessionManager().signOut();

      if (mounted) {
        // الانتقال إلى شاشة الدخول بعد تسجيل الخروج
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => LoginScreen(
              theme: widget.theme,
              onThemeChanged: widget.onThemeChanged,
              isLogin: true,
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تسجيل الخروج: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
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
        title: Text(
          'الإعدادات',
          style: TextStyle(
            color: t.text,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // قسم معلومات الحساب
            _buildSectionLabel('معلومات الحساب', t),
            _buildInfoCard(
              icon: Icons.person_outline_rounded,
              label: 'الاسم',
              value: widget.currentUser.fullName,
              theme: t,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.email_outlined,
              label: 'البريد الإلكتروني',
              value: SessionManager().getCurrentUser()?.email ?? 'غير متوفر',
              theme: t,
            ),
            const SizedBox(height: 30),

            // قسم الجلسة والأمان
            _buildSectionLabel('الجلسة والأمان', t),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'جلسة نشطة',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'جلستك محفوظة بأمان\nستبقى مسجلاً دخول حتى تختار تسجيل الخروج',
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // قسم تسجيل الخروج
            _buildSectionLabel('تسجيل الخروج', t),
            ElevatedButton.icon(
              onPressed: _isLoggingOut ? null : _handleLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.1),
                disabledBackgroundColor: Colors.grey.withOpacity(0.1),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: Colors.red.withOpacity(0.3)),
                ),
              ),
              icon: _isLoggingOut
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.red,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(Icons.logout_rounded, color: Colors.red),
              label: Text(
                _isLoggingOut ? 'جاري التحميل...' : 'تسجيل الخروج',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'سيؤدي تسجيل الخروج إلى حذف الجلسة\nوستحتاج إلى تسجيل الدخول مرة أخرى',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // معلومات التطبيق
            Center(
              child: Text(
                'دردشاتي v1.0.0',
                style: TextStyle(
                  color: t.text.withOpacity(0.2),
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        label,
        style: TextStyle(
          color: theme.text.withOpacity(0.5),
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required AppThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.card.withOpacity(0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.text.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.button, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.text.withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.text,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
