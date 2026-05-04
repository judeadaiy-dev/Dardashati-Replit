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
        fontFamily: _currentTheme.fontFamily,
        useMaterial3: true,
      ),
      home: _initialized 
          ? _AuthGate(theme: _currentTheme, onThemeChanged: _changeTheme) 
          : _SplashScreen(theme: _currentTheme),
    );
  }
}

// ========================= منطق البوابة والتحميل =========================

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
              email: user.email ?? '',
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

// ========================= الواجهات (UI) =========================

class _SplashScreen extends StatelessWidget {
  final AppThemeData theme;
  const _SplashScreen({required this.theme});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator(color: theme.button)),
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
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE0E7FF), Color(0xFFF8FAFC), Color(0xFFEDE9FE)],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  Text('دردشاتي', style: TextStyle(color: Color(0xFF1E293B), fontSize: 42, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  Text('تواصل بذكاء وخصوصية تامة', style: TextStyle(color: Color(0xFF64748B), fontSize: 16)),
                  const Spacer(flex: 4),
                  _SoftBtn(
                    label: 'تسجيل الدخول',
                    isPrimary: true,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen(theme: theme, onThemeChanged: onThemeChanged, isLogin: true))),
                  ),
                  const SizedBox(height: 16),
                  _SoftBtn(
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

class _SoftBtn extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;
  const _SoftBtn({required this.label, required this.isPrimary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 62,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF6366F1) : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: isPrimary ? Colors.white : Color(0xFF1E293B), fontSize: 17, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
