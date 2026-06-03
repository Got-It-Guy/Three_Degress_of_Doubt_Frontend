import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/signup_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/chat/presentation/screens/chat_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/profile/presentation/screens/profile_setup_screen.dart';
import 'features/profile/presentation/screens/metadata_setup_screen.dart';
import 'features/profile/presentation/screens/account_settings_screen.dart';
import 'features/profile/presentation/screens/game_help_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF020911),
        canvasColor: const Color(0xFF020911),
      ),
      builder: (context, child) {
        return ColoredBox(
          color: const Color(0xFF020911),
          child: child ?? const SizedBox.shrink(),
        );
      },
      initialRoute: '/login',
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return _buildFastRoute(const LoginScreen(), settings);
      case '/signup':
        return _buildSignupRoute(const SignupScreen(), settings);
      case '/main':
        return _buildFastRoute(const HomeScreen(), settings);
      case '/chat':
        final args = settings.arguments;
        final safeArgs = args is ChatScreenArgs
            ? args
            : const ChatScreenArgs(stageId: 6, stageTitle: '랜덤');
        return _buildFastRoute(ChatScreen(args: safeArgs), settings);
      case '/profile-setup':
        final args = settings.arguments;
        final safeArgs = args is ProfileSetupArgs
            ? args
            : const ProfileSetupArgs();
        return _buildFastRoute(ProfileSetupScreen(args: safeArgs), settings);
      case '/profile':
        return _buildFastRoute(const ProfileScreen(), settings);
      case '/metadata-setup':
        return _buildFastRoute(const MetadataSetupScreen(), settings);
      case '/account-settings':
        return _buildFastRoute(const AccountSettingsScreen(), settings);
      case '/game-help':
        return _buildFastRoute(const GameHelpScreen(), settings);
      default:
        return _buildFastRoute(const LoginScreen(), settings);
    }
  }

  PageRouteBuilder<dynamic> _buildFastRoute(
    Widget page,
    RouteSettings settings,
  ) {
    return PageRouteBuilder<dynamic>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 180),
      reverseTransitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final primary = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        final secondary = CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        final topScale = Tween<double>(begin: 0.96, end: 1.0).animate(primary);
        final topOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(primary);

        final underScale = Tween<double>(
          begin: 1.0,
          end: 0.99,
        ).animate(secondary);
        final underOpacity = Tween<double>(
          begin: 1.0,
          end: 0.96,
        ).animate(secondary);

        return ColoredBox(
          color: const Color(0xFF020911),
          child: FadeTransition(
            opacity: underOpacity,
            child: ScaleTransition(
              scale: underScale,
              child: FadeTransition(
                opacity: topOpacity,
                child: ScaleTransition(scale: topScale, child: child),
              ),
            ),
          ),
        );
      },
    );
  }

  PageRouteBuilder<dynamic> _buildSignupRoute(
    Widget page,
    RouteSettings settings,
  ) {
    return PageRouteBuilder<dynamic>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final primary = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        final secondary = CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        final topScale = Tween<double>(begin: 0.92, end: 1.0).animate(primary);
        final topOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(primary);

        final underScale = Tween<double>(
          begin: 1.0,
          end: 0.98,
        ).animate(secondary);
        final underOpacity = Tween<double>(
          begin: 1.0,
          end: 0.92,
        ).animate(secondary);

        return ColoredBox(
          color: const Color(0xFF020911),
          child: FadeTransition(
            opacity: underOpacity,
            child: ScaleTransition(
              scale: underScale,
              child: FadeTransition(
                opacity: topOpacity,
                child: ScaleTransition(scale: topScale, child: child),
              ),
            ),
          ),
        );
      },
    );
  }
}
