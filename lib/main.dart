import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// استدعاء المكونات المعتمدة لمشروع دردشاتي
import 'package:dardashati/models.dart';
import 'package:dardashati/app_theme.dart'; // الملف الذي يحتوي على AppThemes
import 'package:dardashati/services/database_service.dart';
import 'package:dardashati/home_screen.dart';
import 'package:dardashati/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. إعدادات الشاشة (الوضع العمودي فقط لضمان جمالية التصميم)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // 2. تهيئة Supabase (تأكد من وضع رابط الـ URL والـ Anon Key الخاص بك)
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL', 
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  runApp(const DardashatiApp());
}

class DardashatiApp extends StatefulWidget {
  const DardashatiApp({super.key});

  @override
  State<DardashatiApp> createState() => _DardashatiAppState();
}

class _DardashatiAppState extends State<DardashatiApp> {
  // الثيم الافتراضي عند أول تشغيل
  AppThemeData _currentTheme = AppThemes.allThemes[0];
  bool _initialized = false;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _loadInitialSettings();
    _listenToAuthChanges();
  }

  // تحميل الإعدادات الأولية (الثيم المحفوظ)
  Future<void> _loadInitialSettings() async {
    try {
      // محاولة جلب الثيم من قاعدة البيانات إذا كان المستخدم مسجلاً
      if (Supabase.instance.client.auth.currentUser != null) {
        // هنا يمكن استدعاء دالة جلب الثيم من DatabaseService
        // final savedThemeName = await DatabaseService.getUserTheme();
        // _applyThemeByName(savedThemeName);
      }
    } catch (e) {
      debugPrint("Theme Error: $e");
    } finally {
      setState(() => _initialized = true);
    }
  }

  // مراقبة حالة الدخول للتعامل مع روابط استعادة كلمة المرور
  void _listenToAuthChanges() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => UpdatePasswordScreen(theme: _currentTheme)),
        );
      }
    });
  }

  void _changeTheme(AppThemeData newTheme) {
    setState(() => _currentTheme = newTheme);
    // حفظ الثيم في السحابة ليكون متاحاً على أي جهاز آخر
    // DatabaseService.saveUserTheme(newTheme.name);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'دردشاتي',
      debugShowCheckedModeBanner: false,
      // دعم كامل للغة العربية من اليمين لليسار (RTL)
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        fontFamily: 'Tajawal', // الخط العربي المعتمد للتطبيق
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
      body: Center(child: CircularProgressIndicator(color: _currentTheme.primaryColor)),
    );
  }
}

// -------------------------------------------------------------------------
// بوابة التحقق (AuthGate): هي التي تقرر أين يذهب المستخدم
// -------------------------------------------------------------------------
class _AuthGate extends StatelessWidget {
  final AppThemeData theme;
  final Function(AppThemeData) onThemeChanged;

  const _AuthGate({required this.theme, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;

        if (session != null) {
          // المستخدم مسجل دخول -> وجهه للرئيسية
          final user = AppUser(
            id: session.user.id,
            fullName: session.user.userMetadata?['full_name'] ?? 'مستخدم',
            avatarUrl: session.user.userMetadata?['avatar_url'] ?? '',
            isOnline: true,
          );
          return HomeScreen(currentUser: user, theme: theme, onThemeChanged: onThemeChanged);
        }

        // المستخدم غير مسجل -> وجهه لشاشة الدخول
        return LoginScreen(theme: theme, onThemeChanged: onThemeChanged, isLogin: true);
      },
    );
  }
}

// -------------------------------------------------------------------------
// شاشة تحديث كلمة المرور (عند استلام رابط الإيميل)
// -------------------------------------------------------------------------
class UpdatePasswordScreen extends StatelessWidget {
  final AppThemeData theme;
  const UpdatePasswordScreen({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    final passController = TextEditingController();
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(title: const Text('كلمة مرور جديدة'), backgroundColor: Colors.transparent),
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
