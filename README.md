# تيك شات - Tik Chat Flutter App

## خطوات الإعداد السريع

### 1. إعداد Supabase
- أنشئ مشروعاً جديداً على https://supabase.com
- اذهب إلى **SQL Editor** وانسخ كامل محتوى `supabase_schema.sql` ونفّذه
- من **Settings > API** انسخ: Project URL و anon public key

### 2. بيانات الاتصال
افتح `lib/env.dart` وضع بياناتك:
```dart
class Env {
  static const String supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY_HERE';
}
```

### 3. تشغيل التطبيق
```bash
flutter pub get
flutter run
```

### 4. بناء APK يدوياً
```bash
flutter build apk --release --split-per-abi
```
الملف سيكون في: `build/app/outputs/flutter-apk/`

---

## بناء APK تلقائي عبر GitHub Actions
1. ارفع المشروع على GitHub
2. اذهب إلى **Settings > Secrets and variables > Actions**
3. أضف:
   - `SUPABASE_URL` ← رابط مشروعك
   - `SUPABASE_ANON_KEY` ← مفتاح anon
4. كل push على `main` يبني APK تلقائياً وينشره كـ Release

---

## حذف البيانات الوهمية (بعد ربط Supabase)
1. احذف `lib/mock_data.dart`
2. في كل ملف يستورده ابحث عن `import 'mock_data.dart';` وأزل السطر
3. الكود لديه `try/catch` يستدعي Supabase أولاً — إذا نجح لن يحتاج mock

---

## الميزات المتوفرة

| الميزة | الحالة |
|--------|--------|
| تسجيل الدخول / إنشاء حساب (Supabase Auth) | ✅ حقيقي |
| حفظ الجلسة تلقائياً | ✅ حقيقي |
| رسائل الغرف مع Realtime | ✅ حقيقي |
| الرسائل الخاصة مع Realtime | ✅ حقيقي |
| إشعارات فورية (Realtime) | ✅ حقيقي |
| متابعة / إلغاء متابعة | ✅ حقيقي |
| الإبلاغ عن المستخدمين | ✅ حقيقي |
| الحظر / رفع الحظر (Admin) | ✅ حقيقي |
| طلبات إنشاء غرف | ✅ حقيقي |
| البث الجماعي (Admin) | ✅ حقيقي |
| الثيمات محفوظة بقاعدة البيانات | ✅ حقيقي |
| GitHub Actions → APK | ✅ جاهز |
| ملف SQL جاهز للنسخ | ✅ جاهز |
| بيانات وهمية سهلة الحذف | ✅ في mock_data.dart |
