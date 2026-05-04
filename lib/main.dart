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
      AuthService.setOnlineStatus(true);
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
    if (_profile == null) {
       return WelcomeScreen(theme: widget.theme, onThemeChanged: widget.onThemeChanged);
    }
    return HomeScreen(currentUser: _profile!, theme: widget.theme, onThemeChanged: widget.onThemeChanged);
  }
}

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

// أضف WelcomeScreen و _Btn هنا كما هما في كودك الأصلي

