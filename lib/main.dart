import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// استدعاء المكونات المعتمدة لمشروع دردشاتي
import 'package:dardashati/models.dart';
import 'package:dardashati/app_theme.dart';
import 'package:dardashati/services/database_service.dart';
import 'package:dardashati/services/session_manager.dart';
import 'package:dardashati/home_screen.dart';
import 'package:dardashati/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. إعدادات الشاشة (الوضع العمودي فقط)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // 2. تهيئة Supabase
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL', 
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  // 3. تهيئة SessionManager للحفاظ على الجلسة
  await SessionManager().initialize();

  runApp(const DardashatiApp());
}

class DardashatiApp extends StatefulWidget {
  const DardashatiApp({super.key});

  @override
  State<DardashatiApp> createState() => _DardashatiAppState();
}

class _DardashatiAppState extends State<DardashatiApp> {
  AppThemeData _currentTheme = AppThemes.allThemes[0];
  bool _initialized = false;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _loadInitialSettings();
    _listenToAuthChanges();
  }

  // تحميل الإعدادات الأولية والتحقق من الجلسة المحفوظة
  Future<void> _loadInitialSettings() async {
    try {
      // محاولة استعادة الجلسة المحفوظة (مثل Instagram)
      final sessionRestored = await SessionManager().restoreSession();
      
      if (sessionRestored) {
        debugPrint("✅ جلسة محفوظة تم استعادتها - المستخدم مسجل دخول");
      } else {
        debugPrint("❌ لا توجد جلسة محفوظة - المستخدم يحتاج للدخول");
      }
    } catch (e) {
      debugPrint("خطأ في استعادة الجلسة: $e");
    } finally {
      setState(() => _initialized = true);
    }
  }

  // مراقبة حالة الدخول للتعامل مع روابط استعادة كلمة المرور
  void _listenToAuthChanges() {
    SessionManager().authStateChanges.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => UpdatePasswordScreen(theme: _currentTheme)),
        );
      }
    });
  }

  void _changeTheme(AppThemeData newTheme) {
    setState(() => _currentTheme = newTheme);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
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
        brightness: _currentTheme.isDark ? Brightness.dark : Brightness.light,
      ),
      home: !_initialized 
          ? _buildLoadingScreen() 
          : _AuthGate(theme: _currentTheme, onThemeChanged: _changeTheme),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: _currentTheme.background,
      body: Center(
        child: CircularProgressIndicator(color: _currentTheme.primaryColor),
      ),
    );
  }
}

// -------------------------------------------------------------------------
// بوابة التحقق (AuthGate): تقرر أين يذهب المستخدم
// -------------------------------------------------------------------------
class _AuthGate extends StatelessWidget {
  final AppThemeData theme;
  final Function(AppThemeData) onThemeChanged;

  const _AuthGate({required this.theme, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: SessionManager().authStateChanges,
      builder: (context, snapshot) {
        // التحقق من وجود جلسة نشطة
        final session = SessionManager().getCurrentSession();

        if (session != null) {
          // المستخدم مسجل دخول → عرض الشاشة الرئيسية
          final user = SessionManager().getCurrentUser();
          if (user != null) {
            final appUser = AppUser(
              id: user.id,
              fullName: user.userMetadata?['full_name'] ?? 'مستخدم',
              avatarUrl: user.userMetadata?['avatar_url'] ?? '',
              isOnline: true,
            );
            return HomeScreen(
              currentUser: appUser,
              theme: theme,
              onThemeChanged: onThemeChanged,
            );
          }
        }

        // لا توجد جلسة → عرض شاشة الدخول
        return LoginScreen(
          theme: theme,
          onThemeChanged: onThemeChanged,
          isLogin: true,
        );
      },
    );
  }
}

// -------------------------------------------------------------------------
// شاشة تحديث كلمة المرور
// -------------------------------------------------------------------------
class UpdatePasswordScreen extends StatelessWidget {
  final AppThemeData theme;
  const UpdatePasswordScreen({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    final passController = TextEditingController();
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('كلمة مرور جديدة'),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            TextField(
              controller: passController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'أدخل كلمة المرور الجديدة',
                labelStyle: TextStyle(color: theme.primaryColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.button,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () async {
                await Supabase.instance.client.auth.updateUser(
                  UserAttributes(password: passController.text.trim())
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: Text('تحديث الآن', style: TextStyle(color: theme.buttonText)),
            )
          ],
        ),
      ),
    );
  }
}
