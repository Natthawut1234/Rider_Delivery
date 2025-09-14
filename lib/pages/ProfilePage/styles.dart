import 'package:flutter/material.dart';

/// 🎨 Colors & Gradients
class AppColors {
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const greenGradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const blueGradient = LinearGradient(
    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const purpleGradient = LinearGradient(
    colors: [Color(0xFF9C27B0), Color(0xFF6A1B9A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const orangeGradient = LinearGradient(
    colors: [Color(0xFFFF9800), Color(0xFFE65100)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const redGradient = LinearGradient(
    colors: [Color(0xFFFF5722), Color(0xFFD32F2F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const darkRedGradient = LinearGradient(
    colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const bgGreen = LinearGradient(
    colors: [Color(0xFFE8F5E8), Color(0xFFF1F8E9), Color(0xFFF8F9FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const bgBlueLight = LinearGradient(
    colors: [Color(0xFFF8F9FA), Color(0xFFE3F2FD)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

/// 📝 Text Styles
class AppTextStyles {
  static const appBarTitle = TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.white,
    fontSize: 20,
  );

  static const sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const bodyLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: Color(0xFF424242),
  );

  static const bodyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Color(0xFF616161),
  );

  static const subtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Color(0xFF757575),
  );

  static const danger = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Color(0xFFD32F2F),
  );

  static const success = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Color(0xFF2E7D32),
  );
}

/// 📦 Box Decorations & Widgets Style
class AppDecorations {
  static const appBarGreen = BoxDecoration(gradient: AppColors.greenGradient);
  static const appBarBlue = BoxDecoration(gradient: AppColors.blueGradient);
  static const appBarPurple = BoxDecoration(gradient: AppColors.purpleGradient);
  static const appBarRed = BoxDecoration(gradient: AppColors.redGradient);

  static const bgGreen = BoxDecoration(gradient: AppColors.bgGreen);
  static const bgBlueLight = BoxDecoration(gradient: AppColors.bgBlueLight);

  static final card = BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(25),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static final cardShadowed = BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(25),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: Colors.blue.withOpacity(0.05),
        blurRadius: 40,
        offset: const Offset(0, 16),
      ),
    ],
  );

  static final iconButton = BoxDecoration(
    color: Colors.white.withOpacity(0.2),
    borderRadius: BorderRadius.circular(12),
  );

  static final dangerButton = BoxDecoration(
    gradient: AppColors.redGradient,
    borderRadius: BorderRadius.circular(25),
    boxShadow: [
      BoxShadow(
        color: Colors.red.withOpacity(0.3),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static final successButton = BoxDecoration(
    gradient: AppColors.greenGradient,
    borderRadius: BorderRadius.circular(25),
    boxShadow: [
      BoxShadow(
        color: Colors.green.withOpacity(0.3),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
