import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import '../commons/local_storage_keys.dart';
import 'app_colors.dart';

class ThemeService {
  ThemeService._();

  static final _box = GetStorage();

  static ThemeMode getThemeMode() {
    try {
      final box = GetStorage();
      final stored = box.read(LocalStorageKeys.themeMode) as String?;
      if (stored == null) return ThemeMode.light;
      return stored == 'dark' ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {
      // If storage isn't ready for some reason, default to light
      return ThemeMode.light;
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    // Ensure GetStorage initialized before writing.
    try {
      await GetStorage.init();
    } catch (_) {}
    final box = GetStorage();
    await box.write(LocalStorageKeys.themeMode, mode == ThemeMode.dark ? 'dark' : 'light');
  }

  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      onPrimary: AppColors.onPrimary,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
    );

    return ThemeData(
      brightness: Brightness.light,
      colorScheme: colorScheme,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        color: AppColors.brown,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        // use accent in light theme so FAB stands out
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
      ),
    );
  }

  static ThemeData darkTheme() {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.darkPrimary,
      primaryContainer: AppColors.darkPrimary,
      secondary: AppColors.darkAccent,
      surface: AppColors.darkSurface,
      onPrimary: AppColors.onDarkPrimary,
      onPrimaryContainer: AppColors.onDarkPrimary,
      onSurface: AppColors.darkTextPrimary,
      error: AppColors.error,
    );

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      primaryColor: AppColors.darkPrimary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardColor: AppColors.darkCard,
      dividerColor: AppColors.darkDivider,
      disabledColor: AppColors.darkDisabled,
      appBarTheme: AppBarTheme(
        color: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        // choose a distinct accent for dark theme so change is visible
        backgroundColor: AppColors.darkAccent,
        foregroundColor: AppColors.darkTextPrimary,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: AppColors.darkTextPrimary),
        bodyMedium: TextStyle(color: AppColors.darkTextSecondary),
        titleMedium: TextStyle(color: AppColors.darkTextPrimary),
        titleSmall: TextStyle(color: AppColors.darkTextSecondary),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
