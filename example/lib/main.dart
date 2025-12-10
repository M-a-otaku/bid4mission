import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // initialize local storage so ThemeService.getThemeMode() can read stored theme synchronously
  try {
    await GetStorage.init();
  } catch (_) {}
  runApp(const App());
}