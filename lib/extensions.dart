import 'dart:ui';
import 'package:flutter/material.dart';

/// Extension لتطبيق تأثير Glassmorphism (التأثير الزجاجي) 
/// على أي Widget داخل التطبيق بمجرد استدعاء .frozen()
extension GlassmorphismEffect on Widget {
  
  Widget frozen({
    double blur = 15.0, 
    Color? color, 
    double borderRadius = 20.0,
    double borderWidth = 1.0,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            // لون زجاجي شفاف جداً ليعطي فخامة للتصميم
            color: color ?? Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: borderWidth,
            ),
          ),
          child: this,
        ),
      ),
    );
  }
}
