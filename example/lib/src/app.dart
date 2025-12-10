import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bid4mission/bid4mission.dart' as bid4mission;
import 'package:bid4mission/src/infrastructure/theme/theme_service.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => GetMaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeService.lightTheme(),
    darkTheme: ThemeService.darkTheme(),
    themeMode: ThemeService.getThemeMode(),
    initialRoute: bid4mission.RouteNames.splash,
    getPages: bid4mission.RoutePages.pages,
    locale: const Locale('en','Us'),
    translationsKeys: bid4mission.LocalizationService.keys,
  );
}
