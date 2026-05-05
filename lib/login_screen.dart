import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dardashati/models.dart';
import 'package:dardashati/services/database_service.dart';

class LoginScreen extends StatefulWidget {
  final AppThemeData theme;
  final Function(AppThemeData) onThemeChanged;
  final bool isLogin;

  const LoginScreen({
    super.key, 
    required this.theme, 
    required this.onThemeChanged, 
    required this.isLogin
  });

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

  final SupabaseClient supabase = Supabase.instance.client;

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

  // --- دالة تسجيل الدخول عبر جوجل ---
  Future<void> _handleGoogleSignIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await DatabaseService.signInWithGoogle();
      if (res != null && mounted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } catch (e) {
      setState(() => _error = "فشل تسجيل الدخول عبر جوجل، حاول مجدداً");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // --- دالة إعادة تعيين كلمة المرور ---
  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'يرجى إدخال بريدك الإلكتروني أولاً');
      return;
    }
    setState(() => _loading = true);
    try {
      await supabase.auth.resetPasswordForEmail(email, redirectTo: 'dardashati://callback');
      if (mounted) _showSuccess('تم إرسال رابط إعادة التعيين لبريدك');
    } catch (e) {
      setState(() => _error = 'فشل الإرسال، تأكد من صحة البريد');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // --- دالة الإرسال الأساسية (Email/Password) ---
  Future<void> _submit() async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });
    try {
      if (_isLogin) {
        await supabase.auth.signInWithPassword(
          email: _email.text.trim(), 
          password: _password.text.trim()
        );
        if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
      } else {
        if (_name.text.trim().isEmpty) {
          setState(() { _error = 'الاسم مطلوب'; _loading = false; });
          return;
        }
        await supabase.auth.signUp(
          email: _email.text.trim(), 
          password: _password.text.trim(),
          data: {'full_name': _name.text.trim()},
        );
        if (mounted) {
          _showSuccess('تم إنشاء الحساب! يرجى التحقق من بريدك');
          setState(() => _isLogin = true);
        }
      }
    } on AuthException catch (e) {
      setState(() => _error = _mapAuthError(e.message));
    } catch (e) {
      setState(() => _error = 'تأكد من اتصالك بالإنترنت');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Scaffold(
      backgroundColor: t.background,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: t.gradientColors,
              ),
            ),
          ),
          Positioned(top: -50, left: -50, child: _BlurOrb(color: t.button.withOpacity(0.2), size: 200)),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBackButton(t),
                    const SizedBox(height: 20),
                    Text(_isLogin ? 'مرحباً بك مجدداً' : 'ابدأ رحلتك معنا',
                      style: TextStyle(color: t.text, fontSize: 30, fontWeight: FontWeight.w900, fontFamily: 'Tajawal')),
                    const SizedBox(height: 8),
                    Text(_isLogin ? 'سجل دخولك لمتابعة محادثاتك' : 'أنشئ حسابك واستمتع بتجربة دردشة فريدة',
                      style: TextStyle(color: t.text.withOpacity(0.6), fontSize: 14)),
                    const SizedBox(height: 30),

                    if (_error != null) _buildErrorBox(t),

                    if (!_isLogin) ...[
                      _buildField(t, label: 'الاسم الكامل', icon: Icons.person_outline_rounded, controller: _name),
                      const SizedBox(height: 16),
                    ],
                    _buildField(t, label: 'البريد الإلكتروني', icon: Icons.alternate_email_rounded, controller: _email, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    _buildField(t, label: 'كلمة المرور', icon: Icons.lock_outline_rounded, controller: _password, isPassword: true),
                    
                    if (_isLogin) 
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _resetPassword,
                          child: Text('نسيت كلمة المرور؟', style: TextStyle(color: t.button, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),

                    const SizedBox(height: 25),
                    _buildSubmitButton(t),
                    
                    const SizedBox(height: 16),
                    _buildDivider(t),
                    const SizedBox(height: 16),
                    
                    _buildGoogleButton(t),

                    const SizedBox(height: 25),
                    _buildToggleAuth(t),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- زر تسجيل الدخول العادي ---
  Widget _buildSubmitButton(AppThemeData t) {
    return InkWell(
      onTap: _submit,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          color: t.button,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: t.button.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Center(
          child: _loading 
            ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: t.buttonText, strokeWidth: 2))
            : Text(_isLogin ? 'تسجيل الدخول' : 'إنشاء الحساب', 
                style: TextStyle(color: t.buttonText, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // --- زر جوجل المدمج والمنسق ---
  Widget _buildGoogleButton(AppThemeData t) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        fixedSize: const Size(double.maxFinite, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: t.button.withOpacity(0.3), width: 1.5),
        backgroundColor: t.card.withOpacity(0.2),
      ),
      icon: Image.network('https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.png', height: 22),
      label: Text('الدخول عبر جوجل', 
        style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 15)),
      onPressed: _loading ? null : _handleGoogleSignIn,
    );
  }

  // --- فاصل "أو" ---
  Widget _buildDivider(AppThemeData t) {
    return Row(
      children: [
        Expanded(child: Divider(color: t.text.withOpacity(0.1))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text('أو', style: TextStyle(color: t.text.withOpacity(0.3), fontSize: 12)),
        ),
        Expanded(child: Divider(color: t.text.withOpacity(0.1))),
      ],
    );
  }

  Widget _buildField(AppThemeData t, {required String label, required IconData icon, required TextEditingController controller, bool isPassword = false, TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: t.card.withOpacity(0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscure,
        keyboardType: keyboardType,
        textAlign: TextAlign.right,
        style: TextStyle(color: t.text, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: t.text.withOpacity(0.3), fontSize: 14),
          prefixIcon: Icon(icon, color: t.button, size: 22),
          suffixIcon: isPassword ? IconButton(
            icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: t.text.withOpacity(0.2)),
            onPressed: () => setState(() => _obscure = !_obscure),
          ) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildBackButton(AppThemeData t) => IconButton(
    onPressed: () => Navigator.pop(context),
    icon: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: t.card.withOpacity(0.5), shape: BoxShape.circle),
      child: Icon(Icons.arrow_back_ios_new_rounded, color: t.button, size: 18),
    ),
  );

  Widget _buildErrorBox(AppThemeData t) => Container(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(15)),
    child: Row(children: [
      const Icon(Icons.error_outline, color: Colors.red, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500))),
    ]),
  );

  Widget _buildToggleAuth(AppThemeData t) => Center(
    child: TextButton(
      onPressed: () => setState(() => _isLogin = !_isLogin),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontFamily: 'Tajawal', color: t.text, fontSize: 14),
          children: [
            TextSpan(text: _isLogin ? 'ليس لديك حساب؟ ' : 'لديك حساب بالفعل؟ '),
            TextSpan(text: _isLogin ? 'سجل الآن' : 'ادخل من هنا', style: TextStyle(color: t.button, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    ),
  );

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  String _mapAuthError(String error) {
    if (error.contains('Invalid login')) return 'البريد أو كلمة المرور غير صحيحة';
    if (error.contains('already registered')) return 'هذا البريد مستخدم بالفعل';
    return error;
  }
}

class _BlurOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _BlurOrb({required this.color, required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
