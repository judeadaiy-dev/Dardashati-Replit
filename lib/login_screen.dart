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
          // خلفية متدرجة (نفس تيم شاشة الترحيب)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF6F3FF), Color(0xFFEAF8F6)],
              ),
            ),
          ),

          // الأوربات (Orbs) الضبابية للخلفية
          Positioned(
            top: -50,
            left: -50,
            child: _BlurOrb(color: const Color(0xFFC9BEFF).withOpacity(0.3), size: 200),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // زر الرجوع بتصميم ناعم
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF7C6BE0), size: 20),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // العناوين بتصميم عصري
                  Text(
                    _isLogin ? 'مرحباً بك مجدداً' : 'انضم لأسرتنا',
                    style: const TextStyle(
                      color: Color(0xFF2A2750),
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin ? 'سجل دخولك لمتابعة محادثاتك' : 'ابدأ تجربتك الفريدة في دردشاتي',
                    style: TextStyle(color: const Color(0xFF2A2750).withOpacity(0.6), fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  
                  const SizedBox(height: 35),

                  // رسالة الخطأ بتصميم زجاجي محذر
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // حقول الإدخال بتصميم Glassmorphism المحسن
                  if (!_isLogin) ...[
                    _buildField(label: 'الاسم الكامل', icon: Icons.person_outline_rounded, controller: _name),
                    const SizedBox(height: 16),
                  ],
                  _buildField(label: 'البريد الإلكتروني', icon: Icons.alternate_email_rounded, controller: _email, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildField(label: 'كلمة المرور', icon: Icons.lock_open_rounded, controller: _password, isPassword: true),
                  
                  const SizedBox(height: 40),
                  
                  // زر الإجراء الرئيسي المتدرج
                  GestureDetector(
                    onTap: _submit,
                    child: Container(
                      height: 62,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C6BE0), Color(0xFF3FB8B0)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C6BE0).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Center(
                        child: _loading 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Text(
                              _isLogin ? 'تسجيل الدخول' : 'إنشاء حساب جديد',
                              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 25),
                  
                  // التبديل بين الحالات
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF7C6BE0)),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14),
                          children: [
                            TextSpan(text: _isLogin ? 'ليس لديك حساب؟ ' : 'لديك حساب بالفعل؟ ', style: const TextStyle(color: Color(0xFF2A2750))),
                            TextSpan(text: _isLogin ? 'سجل الآن' : 'ادخل من هنا', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3FB8B0))),
                          ],
                        ),
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
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscure,
        keyboardType: keyboardType,
        textAlign: TextAlign.right,
        style: const TextStyle(color: Color(0xFF2A2750), fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: const Color(0xFF2A2750).withOpacity(0.4), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF7C6BE0), size: 22),
          suffixIcon: isPassword ? IconButton(
            icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: const Color(0xFF2A2750).withOpacity(0.3), size: 20),
            onPressed: () => setState(() => _obscure = !_obscure),
          ) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
  }
}

// ويدجت مساعدة للأوربات الضبابية
class _BlurOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _BlurOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 40, spreadRadius: 20)],
      ),
    );
  }
}

