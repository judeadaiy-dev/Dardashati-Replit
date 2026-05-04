import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_service.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'models.dart';
import 'app_theme.dart';
import 'home_screen.dart';
import 'login_screen.dart';
// تم حذف import 'mock_data.dart' نهائياً ✅

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await SupabaseService.initialize();
  runApp(TikChatApp());
}

class TikChatApp extends StatefulWidget {
  @override
  _TikChatAppState createState() => _TikChatAppState();
}

class _TikChatAppState extends State<TikChatApp> with WidgetsBindingObserver {
  AppThemeData _currentTheme = AppThemes.allThemes[0];
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initTheme();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initTheme() async {
    if (AuthService.isLoggedIn) {
      final savedTheme = await DatabaseService.getUserTheme();
      final found = AppThemes.allThemes.where((t) => t.name == savedTheme).toList();
      if (found.isNotEmpty) setState(() => _currentTheme = found.first);
    }
    setState(() => _initialized = true);
  }

  void _changeTheme(AppThemeData newTheme) {
    setState(() => _currentTheme = newTheme);
    DatabaseService.saveUserTheme(newTheme.name);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'دردشاتي',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        fontFamily: 'Tajawal',
        useMaterial3: true,
      ),
      home: _initialized 
          ? _AuthGate(theme: _currentTheme, onThemeChanged: _changeTheme) 
          : _SplashScreen(theme: _currentTheme),
    );
  }
}

class _AuthGate extends StatelessWidget {
  final AppThemeData theme;
  final Function(AppThemeData) onThemeChanged;
  const _AuthGate({required this.theme, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        final session = SupabaseService.client.auth.currentSession;
        if (session != null) {
          return _ProfileLoader(theme: theme, onThemeChanged: onThemeChanged);
        }
        return WelcomeScreen(theme: theme, onThemeChanged: onThemeChanged);
      },
    );
  }
}

class _ProfileLoader extends StatefulWidget {
  final AppThemeData theme;
  final Function(AppThemeData) onThemeChanged;
  const _ProfileLoader({required this.theme, required this.onThemeChanged});
  @override
  State<_ProfileLoader> createState() => _ProfileLoaderState();
}

class _ProfileLoaderState extends State<_ProfileLoader> {
  AppUser? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await AuthService.getCurrentProfile();
    if (profile != null) {
      if (mounted) setState(() { _profile = profile; _loading = false; });
    } else {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        if (mounted) {
          setState(() {
            _profile = AppUser(
              id: user.id,
              fullName: user.userMetadata?['full_name'] ?? 'مستخدم جديد',
              email: user.email ?? '', // تم توفير الإيميل لحل خطأ الـ Build ✅
              avatarUrl: '',
            );
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() { _loading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _SplashScreen(theme: widget.theme);
    if (_profile == null) return WelcomeScreen(theme: widget.theme, onThemeChanged: widget.onThemeChanged);
    return HomeScreen(currentUser: _profile!, theme: widget.theme, onThemeChanged: widget.onThemeChanged);
  }
}

class _SplashScreen extends StatelessWidget {
  final AppThemeData theme;
  const _SplashScreen({required this.theme});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF6F3FF), Color(0xFFEAF8F6)],
          ),
        ),
        child: const Center(child: CircularProgressIndicator(color: Color(0xFF7C6BE0))),
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  final AppThemeData theme;
  final Function(AppThemeData) onThemeChanged;
  const WelcomeScreen({required this.theme, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF6F3FF), Color(0xFFEAF8F6)],
              ),
            ),
          ),
          Positioned(top: -100, right: -50, child: _BlurOrb(color: const Color(0xFFC9BEFF).withOpacity(0.4), size: 300)),
          Positioned(bottom: 50, left: -80, child: _BlurOrb(color: const Color(0xFFA6ECE7).withOpacity(0.4), size: 250)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.5)),
                    ),
                    child: const Icon(Icons.waves_rounded, size: 50, color: Color(0xFF7C6BE0)),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'دردشاتي',
                    style: TextStyle(color: Color(0xFF7C6BE0), fontSize: 48, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'محادثات ناعمة كالأمواج',
                    style: TextStyle(color: const Color(0xFF2A2750).withOpacity(0.7), fontSize: 16),
                  ),
                  const Spacer(flex: 4),
                  _GlassBtn(
                    label: 'تسجيل الدخول',
                    isPrimary: true,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen(theme: theme, onThemeChanged: onThemeChanged, isLogin: true))),
                  ),
                  const SizedBox(height: 16),
                  _GlassBtn(
                    label: 'إنشاء حساب جديد',
                    isPrimary: false,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen(theme: theme, onThemeChanged: onThemeChanged, isLogin: false))),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

class _GlassBtn extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;
  const _GlassBtn({required this.label, required this.isPrimary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF7C6BE0) : Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.6)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: isPrimary ? Colors.white : const Color(0xFF2A2750), fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
