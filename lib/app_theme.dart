import 'package:flutter/material.dart';
import 'package:dardashati/models.dart'; // المسار المعتمد الجديد

class AppThemes {
  static List<AppThemeData> allThemes = [
    
    // 1. الثيم الافتراضي (أمواج دردشاتي) - لمسة زجاجية ناعمة
    AppThemeData(
      name: 'dardashati_wave',
      label: 'أمواج دردشاتي',
      primaryColor: const Color(0xFF7C6BE0),
      gradientColors: [const Color(0xFFF6F3FF), const Color(0xFFEAF8F6)],
      background: const Color(0xFFF6F3FF),
      text: const Color(0xFF2A2750),      
      button: const Color(0xFF7C6BE0),    
      // تقليل الشفافية لزيادة وضوح التأثير الزجاجي
      card: Colors.white.withOpacity(0.5), 
      accent: const Color(0xFF3FB8B0),   
      menu: Colors.white.withOpacity(0.85),
      buttonText: Colors.white,
      isDark: false,
      borderRadius: 40.0, // توحيد الانحناء الكبير الذي تفضله
    ),
    
    // 2. الثيم المودرن الزجاجي (Soft Glass)
    AppThemeData(
      name: 'soft_glass',
      label: 'مودرن زجاجي',
      primaryColor: const Color(0xFF6366F1),
      gradientColors: [const Color(0xFFF8FAFD), const Color(0xFFE2E8F0)],
      background: const Color(0xFFF8FAFD),
      text: const Color(0xFF1E293B),
      button: const Color(0xFF6366F1),
      card: Colors.white.withOpacity(0.6),
      accent: const Color(0xFF38BDF8),
      menu: const Color(0xFFF1F5F9).withOpacity(0.8),
      buttonText: Colors.white,
      isDark: false,
      borderRadius: 40.0,
    ),
    
    // 3. الثيم الملكي (Royal Dark) - فخامة الذهب والأسود
    AppThemeData(
      name: 'royal_gold',
      label: 'الملكي المذهب',
      primaryColor: const Color(0xFFD4AF37),
      gradientColors: [const Color(0xFF0F0F0F), const Color(0xFF1C1C1C)],
      background: const Color(0xFF0F0F0F),
      text: const Color(0xFFEFDEC1),
      button: const Color(0xFFD4AF37),
      card: const Color(0xFF2C2C2C).withOpacity(0.7),
      accent: const Color(0xFFF9F1D2),
      menu: const Color(0xFF1A1A1A).withOpacity(0.9),
      buttonText: const Color(0xFF1A1A1A),
      isDark: true,
      borderRadius: 40.0,
    ),
    
    // 4. الغابة الليلية (Night Forest) - الراحة البصرية
    AppThemeData(
      name: 'night_forest',
      label: 'الغابة الليلية',
      primaryColor: const Color(0xFF4CAF50),
      gradientColors: [const Color(0xFF0A0F0D), const Color(0xFF141A18)],
      background: const Color(0xFF0A0F0D),
      text: const Color(0xFFE8F5E9),
      button: const Color(0xFF2E7D32),
      card: const Color(0xFF1B2420).withOpacity(0.6),
      accent: const Color(0xFF81C784),
      menu: const Color(0xFF0D1310).withOpacity(0.9),
      buttonText: Colors.white,
      isDark: true,
      borderRadius: 40.0,
    ),
  ];

  // دالة لجلب الثيم الافتراضي عند تشغيل التطبيق لأول مرة
  static AppThemeData get defaultTheme => allThemes[0];
}
