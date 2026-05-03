import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';

class LoginScreen extends StatefulWidget {
  final AppThemeData theme;
  final Function(AppThemeData) onThemeChanged;
  final bool isLogin;
  const LoginScreen({required this.theme, required this.onThemeChanged, this.isLogin = true});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late bool _isLogin;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isLogin = widget.isLogin;
  }

  @override
  void dispose() {
    _name.dispose(); _email.dispose(); _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (_isLogin) {
        await AuthService.signIn(email: _email.text, password: _password.text);
        // تحميل الإعدادات بعد الدخول
        final savedTheme = await DatabaseService.getUserTheme();
        // HomeScreen ستُفتح تلقائياً عبر _AuthGate في main.dart
        if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
      } else {
        if (_name.text.trim().isEmpty) {
          setState(() { _error = 'يرجى إدخال الاسم'; _loading = false; });
          return;
        }
        await AuthService.signUp(email: _email.text, password: _password.text, fullName: _name.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('تم إنشاء الحساب! تحقق من بريدك للتفعيل إن كان مطلوباً'), backgroundColor: widget.theme.button));
          Navigator.of(context).popUntil((r) => r.isFirst);
        }
      }
    } on AuthException catch (e) {
      String msg = e.message;
      if (msg.contains('Invalid login')) msg = 'البريد أو كلمة المرور غير صحيحة';
      if (msg.contains('already registered')) msg = 'هذا البريد مسجل مسبقاً';
      if (msg.contains('Password should be')) msg = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
      setState(() => _error = msg);
    } catch (e) {
      setState(() => _error = 'حدث خطأ غير متوقع، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    if (_email.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('أدخل بريدك الإلكتروني أولاً'), backgroundColor: Colors.orange));
      return;
    }
    try {
      await AuthService.resetPassword(_email.text);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('تم إرسال رابط إعادة التعيين لبريدك'), backgroundColor: widget.theme.button));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: t.text), onPressed: () => Navigator.pop(context))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: t.button.withOpacity(0.1), borderRadius: BorderRadius.circular(24)), child: Icon(Icons.chat_bubble_outline_rounded, size: 40, color: t.button)),
              const SizedBox(height: 20),
              Text(_isLogin ? 'أهلاً بعودتك!' : 'انضم إلينا', style: TextStyle(color: t.text, fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(_isLogin ? 'سجّل دخولك للمتابعة' : 'أنشئ حسابك الجديد مجاناً', style: TextStyle(color: t.text.withOpacity(0.5), fontSize: 14)),
              const SizedBox(height: 28),

              // Toggle
              Container(
                decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: t.text.withOpacity(0.08))),
                child: Row(children: [
                  _tab('تسجيل الدخول', _isLogin, t, () => setState(() => _isLogin = true)),
                  _tab('إنشاء حساب', !_isLogin, t, () => setState(() => _isLogin = false)),
                ]),
              ),
              const SizedBox(height: 24),

              // رسالة الخطأ
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withOpacity(0.3))),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              // الحقول
              if (!_isLogin) ...[
                _field(Icons.person_outline, 'الاسم الكامل', false, _name, t),
                const SizedBox(height: 14),
              ],
              _field(Icons.email_outlined, 'البريد الإلكتروني', false, _email, t, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 14),
              _passwordField(t),
              const SizedBox(height: 8),
              if (_isLogin)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(onPressed: _forgotPassword, child: Text('نسيت كلمة المرور؟', style: TextStyle(color: t.button, fontSize: 13))),
                ),
              const SizedBox(height: 20),

              // زر الإرسال
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: t.button, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 0),
                  child: _loading
                      ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: t.buttonText, strokeWidth: 2.5))
                      : Text(_isLogin ? 'دخول' : 'إنشاء الحساب', style: TextStyle(color: t.buttonText, fontSize: 17, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(String label, bool active, AppThemeData t, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: active ? t.button : Colors.transparent, borderRadius: BorderRadius.circular(14)),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: active ? t.buttonText : t.text.withOpacity(0.5), fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _field(IconData icon, String hint, bool obscure, TextEditingController ctrl, AppThemeData t, {TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: t.text.withOpacity(0.08))),
      child: TextField(
        controller: ctrl, obscureText: obscure, textAlign: TextAlign.right,
        keyboardType: keyboardType,
        style: TextStyle(color: t.text, fontSize: 14),
        decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: t.text.withOpacity(0.3)), prefixIcon: Icon(icon, color: t.button.withOpacity(0.7), size: 20), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
      ),
    );
  }

  Widget _passwordField(AppThemeData t) {
    return Container(
      decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: t.text.withOpacity(0.08))),
      child: TextField(
        controller: _password, obscureText: _obscure, textAlign: TextAlign.right,
        style: TextStyle(color: t.text, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'كلمة المرور',
          hintStyle: TextStyle(color: t.text.withOpacity(0.3)),
          prefixIcon: Icon(Icons.lock_outline, color: t.button.withOpacity(0.7), size: 20),
          suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: t.text.withOpacity(0.4), size: 20), onPressed: () => setState(() => _obscure = !_obscure)),
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
