import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';

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
    if (_loading) return;
    setState(() { _loading = true; _error = null; });
    
    try {
      if (_isLogin) {
        await AuthService.signIn(email: _email.text.trim(), password: _password.text.trim());
        await DatabaseService.getUserTheme();
        if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
      } else {
        if (_name.text.trim().isEmpty) {
          setState(() { _error = 'يرجى إدخال الاسم'; _loading = false; });
          return;
        }
        await AuthService.signUp(
          email: _email.text.trim(), 
          password: _password.text.trim(), 
          fullName: _name.text.trim()
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إنشاء الحساب بنجاح!'))
          );
          Navigator.of(context).popUntil((r) => r.isFirst);
        }
      }
    } on AuthException catch (e) {
      String msg = e.message;
      if (msg.contains('Invalid login')) msg = 'البريد أو كلمة المرور غير صحيحة';
      if (msg.contains('already registered')) msg = 'هذا البريد مسجل مسبقاً';
      if (msg.contains('Password should be')) msg = 'كلمة المرور ضعيفة (6 أحرف على الأقل)';
      setState(() => _error = msg);
    } catch (e) {
      setState(() => _error = 'حدث خطأ، تأكد من اتصالك بالإنترنت');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // الخلفية الناعمة
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE0E7FF), Color(0xFFF8FAFC), Color(0xFFEDE9FE)],
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 20),
                  
                  Text(
                    _isLogin ? 'أهلاً بعودتك' : 'انضم إلينا',
                    style: const TextStyle(color: Color(0xFF1E293B), fontSize: 34, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin ? 'سجل دخولك للمتابعة' : 'أنشئ حسابك الجديد بلمسة واحدة',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 16),
                  ),
                  
                  const SizedBox(height: 35),

                  // رسالة الخطأ إن وجدت
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.withOpacity(0.2))),
                      child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 14)),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // الحقول
                  if (!_isLogin) ...[
                    _buildField(label: 'الاسم الكامل', icon: Icons.person_outline, controller: _name),
                    const SizedBox(height: 16),
                  ],
                  _buildField(label: 'البريد الإلكتروني', icon: Icons.email_outlined, controller: _email, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildField(label: 'كلمة المرور', icon: Icons.lock_outline, controller: _password, isPassword: true),
                  
                  const SizedBox(height: 40),
                  
                  // زر الدخول / التسجيل
                  GestureDetector(
                    onTap: _submit,
                    child: Container(
                      height: 62,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                        ],
                      ),
                      child: Center(
                        child: _loading 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                          : Text(_isLogin ? 'دخول' : 'بدء الرحلة', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 25),
                  
                  // التبديل بين الدخول والتسجيل
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      child: Text(
                        _isLogin ? 'ليس لديك حساب؟ سجل الآن' : 'لديك حساب بالفعل؟ ادخل',
                        style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({required String label, required IconData icon, required TextEditingController controller, bool isPassword = false, TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscure,
        keyboardType: keyboardType,
        textAlign: TextAlign.right,
        style: const TextStyle(color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: const Color(0xFF64748B).withOpacity(0.5)),
          prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 22),
          suffixIcon: isPassword ? IconButton(
            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF64748B).withOpacity(0.5)),
            onPressed: () => setState(() => _obscure = !_obscure),
          ) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
  }
}
