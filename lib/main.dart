import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // ضروري للـ PlatformDispatcher
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// استدعاء الخدمات والمودلز الخاصة بك
import 'services/supabase_service.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'utils/logger.dart'; // تأكد من وجود ملف الـ Logger الذي أنشأناه
import 'models.dart';
import 'app_theme.dart';
import 'home_screen.dart';
import 'login_screen.dart';

// --- دالة الـ main الموحدة (تم إصلاح التضارب هنا) ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. تثبيت اتجاه الشاشة
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 2. تهيئة Supabase (استخدم بياناتك الحقيقية هنا)
  // ملاحظة: يفضل استخدام SupabaseService.initialize() إذا كان يحتوي على الإعدادات
  await SupabaseService.initialize();

  // 3. --- تفعيل المراقب الصامت الاحترافي ---
  // التقاط أخطاء الواجهة (UI)
  FlutterError.onError = (details) {
    AppLogger.error("UI_ERROR", details.exceptionAsString());
  };
  
  // التقاط أخطاء الخلفية والداتابيز (Async)
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error("SYSTEM_ERROR", error.toString());
    return true;
  };

  runApp(const TikChatApp());
}

class TikChatApp extends StatefulWidget {
  const TikChatApp({super.key}); // إضافة الـ Key بشكل صحيح

  @override
  State<TikChatApp> createState() => _TikChatAppState();
}

class _TikChatAppState extends State<TikChatApp> with WidgetsBindingObserver {
  AppThemeData _currentTheme = AppThemes.allThemes[0];
  bool _initialized = false;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initTheme();
    _setupDeepLinkListener();
  }

  // مستمع الروابط العميقة (Deep Links) لإصلاح الصفحة الفارغة
  void _setupDeepLinkListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        AppLogger.info("AUTH", "تم استقبال رابط استعادة كلمة المرور ✅");
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
    try {
      if (AuthService.isLoggedIn) {
        final savedTheme = await DatabaseService.getUserTheme();
        final found = AppThemes.allThemes.where((t) => t.name == savedTheme).toList();
        if (found.isNotEmpty) setState(() => _currentTheme = found.first);
      }
    } catch (e) {
      AppLogger.error("THEME", "فشل تحميل الثيم", e);
    } finally {
      setState(() => _initialized = true);
    }
  }

  void _changeTheme(AppThemeData newTheme) {
    setState(() => _currentTheme = newTheme);
    DatabaseService.saveUserTheme(newTheme.name);
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
      ),
      // حماية التطبيق بـ AuthGate أو عرض شاشة التحميل
      home: _initialized 
          ? _AuthGate(theme: _currentTheme, onThemeChanged: _changeTheme) 
          : _SplashScreen(theme: _currentTheme),
    );
  }
}

// -------------------------------------------------------------------------
// واجهة تحديث كلمة المرور (معدلة لتناسب الهوية البصرية)
// -------------------------------------------------------------------------
class UpdatePasswordScreen extends StatelessWidget {
  final AppThemeData theme;
  UpdatePasswordScreen({super.key, required this.theme});
  final _passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text('تحديث كلمة المرور', style: TextStyle(color: theme.text)),
        backgroundColor: theme.menu,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _passController,
              style: TextStyle(color: theme.text),
              decoration: InputDecoration(
                labelText: 'كلمة المرور الجديدة',
                labelStyle: TextStyle(color: theme.primaryColor),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.primaryColor)),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: theme.button),
              onPressed: () async {
                try {
                  await Supabase.instance.client.auth.updateUser(
                    UserAttributes(password: _passController.text.trim())
                  );
                  AppLogger.success("AUTH", "تم تحديث كلمة المرور بنجاح");
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  AppLogger.error("AUTH", "فشل تحديث كلمة المرور", e);
                }
              },
              child: Text('حفظ التغييرات', style: TextStyle(color: theme.buttonText)),
            )
          ],
        ),
      ),
    );
  }
}

// استمر بإضافة _AuthGate و _ProfileLoader و _SplashScreen أسفل هذا الملف...
