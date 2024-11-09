import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../presentation/auth/login_page.dart';
import '../presentation/splash/splash_page.dart';
import '../presentation/home/home_page.dart';

class Routes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => SplashPage());
      case login:
        return MaterialPageRoute(builder: (_) => LoginPage());
      case home:
        return MaterialPageRoute(builder: (_) => HomePage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  static Future<String> getInitialRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    return isLoggedIn ? home : login;
  }
}
