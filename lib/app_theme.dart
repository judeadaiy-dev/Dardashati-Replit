import 'package:flutter/material.dart';
import 'models.dart';

class AppThemes {
  static List<AppThemeData> allThemes = [
    // 1. الثيم الافتراضي الجديد (متطابق مع شاشة الترحيب)
    AppThemeData(
      name: 'dardashati_wave',
      label: 'أمواج دردشاتي (الافتراضي)',
      background: Color(0xFFF6F3FF), // البنفسجي الفاتح جداً
      text: Color(0xFF2A2750),      // اللون الكحلي العميق للنصوص
      button: Color(0xFF7C6BE0),    // البنفسجي الأساسي (الآرجواني)
      buttonText: Colors.white,
      accent: Color(0xFF3FB8B0),    // الفيروزي (التركواز) للتوازن
      card: Colors.white.withOpacity(0.45),
      menu: Colors.white.withOpacity(0.8),
      fontFamily: 'Tajawal',
      iconStyle: IconStyle.soft,
      isDark: false,
    ),
    
    // 2. ثيم زجاجي هادئ (معدل)
    AppThemeData(
      name: 'soft_glass',
      label: 'مودرن زجاجي',
      background: Color(0xFFF8FAFD),
      text: Color(0xFF1E293B),
      button: Color(0xFF6366F1), // Indigo
      buttonText: Colors.white,
      accent: Color(0xFF38BDF8),
      card: Colors.white.withOpacity(0.7),
      menu: Color(0xFFF1F5F9).withOpacity(0.9),
      fontFamily: 'Tajawal', // توحيد الخط لتقليل حجم التطبيق
      iconStyle: IconStyle.minimal,
      isDark: false,
    ),
    
    // 3. الثيم الملكي (ممتاز، لا يحتاج تعديل كبير)
    AppThemeData(
      name: 'royal_gold',
      label: 'الملكي المذهب',
      background: Color(0xFF1A1A1A),
      text: Color(0xFFEFDEC1),
      button: Color(0xFFD4AF37),
      buttonText: Color(0xFF1A1A1A),
      accent: Color(0xFFF9F1D2),
      card: Color(0xFFD4AF25).withOpacity(0.08),
      menu: Color(0xFF2C2C2C),
      fontFamily: 'Tajawal',
      iconStyle: IconStyle.bold,
      isDark: true,
    ),
    
    // 4. الثيم الليلي (رسمي وفخم)
    AppThemeData(
      name: 'night_forest',
      label: 'الغابة الليلية',
      background: Color(0xFF0D1310),
      text: Color(0xFFE8F5E9),
      button: Color(0xFF2E7D32),
      buttonText: Colors.white,
      accent: Color(0xFF66BB6A),
      card: Colors.white.withOpacity(0.04),
      menu: Color(0xFF0D1310).withOpacity(0.95),
      fontFamily: 'Tajawal',
      iconStyle: IconStyle.bold,
      isDark: true,
    ),
  ];
}
