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
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: '...', anonKey: '...');

  // --- السطر السحري الاحترافي ---
  // هذا السطر يلتقط أي خطأ يحدث في واجهة المستخدم (UI) أو المنطق (Logic) ويرسله للمراقب
  FlutterError.onError = (details) => AppLogger.error("GLOBAL", details.exceptionAsString());
  
  // وهذا السطر يلتقط الأخطاء التي تحدث في الخلفية (Asynchronous errors) مثل فشل الاتصال بالداتابيز
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error("DATABASE/AUTH", error.toString());
    return true;
  };

  runApp(const MyApp());
}

class TikChatApp extends StatefulWidget {
  @override
  _TikChatAppState createState() => _TikChatAppState();
}

class _TikChatAppState extends State<TikChatApp> with WidgetsBindingObserver {
  AppThemeData _currentTheme = AppThemes.allThemes[0];
  bool _initialized = false;
  final _navigatorKey = GlobalKey<NavigatorState>(); // مفتاح التنقل للتحكم من خارج الواجهات

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initTheme();
    _setupDeepLinkListener(); // إعداد المستمع للروابط العميقة
  }

  // دالة الاستماع للروابط القادمة من الإيميل (إصلاح مشكلة الصفحة الفارغة)
  void _setupDeepLinkListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        // إذا كان الرابط هو استعادة كلمة مرور، وجه المستخدم لصفحة التحديث
        debugPrint("تم استقبال رابط استعادة كلمة المرور ✅");
        _navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => UpdatePasswordScreen(theme: _currentTheme),
          ),
        );
      }
    });
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
      navigatorKey: _navigatorKey, // ربط المفتاح هنا
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

// -------------------------------------------------------------------------
// واجهات المساعدة والبوابات (AuthGate, ProfileLoader, WelcomeScreen) كما هي في الكود الأصلي مع تحسينات طفيفة
// -------------------------------------------------------------------------

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

// الكلاسات الأخرى (WelcomeScreen, _SplashScreen, _GlassBtn, _BlurOrb) تبقى كما أرسلتها في كودك...

// -------------------------------------------------------------------------
// واجهة تحديث كلمة المرور (يجب إضافتها لكي لا يظهر خطأ Build)
// -------------------------------------------------------------------------
class UpdatePasswordScreen extends StatelessWidget {
  final AppThemeData theme;
  UpdatePasswordScreen({required this.theme});
  final _passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تحديث كلمة المرور')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _passController, decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await Supabase.instance.client.auth.updateUser(UserAttributes(password: _passController.text.trim()));
                Navigator.pop(context);
              },
              child: const Text('حفظ'),
            )
          ],
        ),
      ),
    );
  }
}
