import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF121212); // Deep dark background
  static const Color surface = Color(0xFF1E1E1E); // Card surface
  static const Color primary = Color(0xFFFFD600); // Vibrant Yellow
  static const Color primaryDark = Color(0xFFFBC02D);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0A0);
  static const Color divider = Color(0xFF333333);
  static const Color error = Color(0xFFCF6679);
}

class AppTextStyles {
  // GmarketSans for headers and numbers
  static const TextStyle h1 = TextStyle(
    fontFamily: 'GmarketSans',
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle h2 = TextStyle(
    fontFamily: 'GmarketSans',
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: 'GmarketSans',
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  // GmarketSans for body text
  static const TextStyle body1 = TextStyle(
    fontFamily: 'GmarketSans',
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle body2 = TextStyle(
    fontFamily: 'GmarketSans',
    fontSize: 14,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle button = TextStyle(
    fontFamily: 'GmarketSans',
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.background, // Black text on yellow button
  );
}
