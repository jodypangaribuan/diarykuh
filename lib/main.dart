import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/splash/splash_page.dart';
import 'utils/theme_manager.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeManager(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, _) {
        return MaterialApp(
          title: 'DiaryKuh',
          theme: themeManager.currentTheme,
          home: const SplashPage(),
        );
      },
    );
  }
}
