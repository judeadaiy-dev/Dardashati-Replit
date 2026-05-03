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

  // قفل الشاشة بالوضع الرأسي فقط
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // تهيئة Supabase
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

  // تحديث حالة الاتصال عند تغيير حالة التطبيق
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (AuthService.isLoggedIn) {
      if (state == AppLifecycleState.resumed) {
        AuthService.setOnlineStatus(true);
      } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
        AuthService.setOnlineStatus(false);
      }
    }
  }

  Future<void> _initTheme() async {
    // جلب ثيم المستخدم المحفوظ إن وُجد
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
      title: 'تيك شات',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        fontFamily: _currentTheme.fontFamily,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _currentTheme.button,
          brightness: _currentTheme.isDark ? Brightness.dark : Brightness.light,
        ),
      ),
      home: _initialized ? _AuthGate(theme: _currentTheme, onThemeChanged: _changeTheme) : _SplashScreen(theme: _currentTheme),
    );
  }
}

// ========================= بوابة المصادقة =========================
class _AuthGate extends StatefulWidget {
  final AppThemeData theme;
  final Function(AppThemeData) onThemeChanged;
  const _AuthGate({required this.theme, required this.onThemeChanged});

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        final session = SupabaseService.client.auth.currentSession;
        if (session != null) {
          return _ProfileLoader(theme: widget.theme, onThemeChanged: widget.onThemeChanged);
        }
        return WelcomeScreen(theme: widget.theme, onThemeChanged: widget.onThemeChanged);
      },
    );
  }
}

// ========================= تحميل الملف الشخصي =========================
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
    if (profile != null) AuthService.setOnlineStatus(true);
    if (mounted) setState(() { _profile = profile; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _SplashScreen(theme: widget.theme);
    if (_profile == null) return WelcomeScreen(theme: widget.theme, onThemeChanged: widget.onThemeChanged);
    return HomeScreen(currentUser: _profile!, theme: widget.theme, onThemeChanged: widget.onThemeChanged);
  }
}

// ========================= شاشة التحميل =========================
class _SplashScreen extends StatelessWidget {
  final AppThemeData theme;
  const _SplashScreen({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.button,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: theme.button.withOpacity(0.4), blurRadius: 30, spreadRadius: 5)],
              ),
              child: Icon(Icons.chat_bubble_outline_rounded, size: 52, color: theme.buttonText),
            ),
            const SizedBox(height: 24),
            Text('تيك شات', style: TextStyle(color: theme.text, fontSize: 32, fontWeight: FontWeight.w900)),
            const SizedBox(height: 32),
            SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: theme.button, strokeWidth: 2.5)),
          ],
        ),
      ),
    );
  }
}

// ========================= شاشة الترحيب =========================
class WelcomeScreen extends StatelessWidget {
  final AppThemeData theme;
  final Function(AppThemeData) onThemeChanged;
  const WelcomeScreen({required this.theme, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.background,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: theme.isDark
              ? RadialGradient(colors: [theme.button.withOpacity(0.2), theme.background], center: Alignment.topLeft, radius: 1.5)
              : LinearGradient(colors: [theme.button.withOpacity(0.06), theme.background], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: theme.button,
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [BoxShadow(color: theme.button.withOpacity(0.4), blurRadius: 40, spreadRadius: 8, offset: const Offset(0, 10))],
                  ),
                  child: Icon(Icons.chat_bubble_outline_rounded, size: 64, color: theme.buttonText),
                ),
              ),
              const SizedBox(height: 32),
              Text('تيك شات', style: TextStyle(color: theme.text, fontSize: 44, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('عالمك الخاص للمحادثات الراقية', style: TextStyle(color: theme.text.withOpacity(0.55), fontSize: 16)),
              const Spacer(flex: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    _Btn(
                      label: 'ابدأ رحلتك',
                      bg: theme.button,
                      fg: theme.buttonText,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen(theme: theme, onThemeChanged: onThemeChanged, isLogin: true))),
                    ),
                    const SizedBox(height: 12),
                    _Btn(
                      label: 'إنشاء حساب جديد',
                      bg: Colors.transparent,
                      fg: theme.text.withOpacity(0.7),
                      border: theme.text.withOpacity(0.2),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen(theme: theme, onThemeChanged: onThemeChanged, isLogin: false))),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text('Tik Chat v1.0.0', style: TextStyle(color: theme.text.withOpacity(0.2), fontSize: 11)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final Color bg, fg;
  final Color? border;
  final VoidCallback onTap;
  const _Btn({required this.label, required this.bg, required this.fg, required this.onTap, this.border});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: bg == Colors.transparent ? 0 : 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: border != null ? BorderSide(color: border!) : BorderSide.none),
        ),
        child: Text(label, style: TextStyle(color: fg, fontSize: 17, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
