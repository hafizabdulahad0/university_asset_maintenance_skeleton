// File: lib/main.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/supabase_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'models/user_model.dart';
import 'services/supabase_service.dart';
import 'models/complaint_model.dart';

// Local DB removed
import 'providers/auth_provider.dart';
import 'providers/complaint_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_provider.dart';

import 'screens/home_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/staff/staff_home_screen.dart';
import 'screens/teacher/teacher_home_screen.dart';
import 'screens/teacher/add_complaint_screen.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'auth/forgot_password_screen.dart';
import 'auth/reset_password_screen.dart';
import 'auth/change_password_screen.dart';
import 'auth/profile_screen.dart';

// Notifications/FCM disabled for simplified flow

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initSupabase();

  // Local DB removed

  // Notifications/FCM removed

  

  runApp(const MyApp());
}

Future<void> _seedSupabaseIfRequested() async {}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _flushed = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ComplaintProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (ctx, theme, auth, _) {
          // FCM flush removed
          final lightScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5));
          final darkScheme  = ColorScheme.fromSeed(seedColor: const Color(0xFF7C3AED), brightness: Brightness.dark);
          return MaterialApp(
            title: 'University Asset Maintenance',
            debugShowCheckedModeBanner: false,
            themeMode: theme.mode,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: lightScheme,
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: ZoomPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.windows: ZoomPageTransitionsBuilder(),
                },
              ),
              inputDecorationTheme: const InputDecorationTheme(
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: lightScheme.primary,
                  foregroundColor: lightScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: lightScheme.primary, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              cardTheme: const CardThemeData(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: darkScheme,
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: ZoomPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.windows: ZoomPageTransitionsBuilder(),
                },
              ),
              inputDecorationTheme: const InputDecorationTheme(
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkScheme.primary,
                  foregroundColor: darkScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: darkScheme.primary, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              cardTheme: const CardThemeData(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
            home: const AuthWrapper(),
            routes: {
              '/login':           (_) => const LoginScreen(),
              '/register':        (_) => const RegisterScreen(),
              '/forgot-password': (_) => const ForgotPasswordScreen(),
              '/change-password': (_) => const ChangePasswordScreen(),
              '/profile':         (_) => const ProfileScreen(),
              '/notifications':   (_) => const NotificationsScreen(),
              '/admin-dashboard': (_) => const AdminDashboardScreen(),
              '/staff-home':      (_) => const StaffHomeScreen(),
              '/teacher-home':    (_) => const TeacherHomeScreen(),
              '/add-complaint':   (_) => const AddComplaintScreen(),
            },
          );
        },
      ),
    );
  }
}

/// Routes the user to either the public HomeScreen or their role-specific dashboard.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    Widget target;
    if (user == null) {
      target = const HomeScreen();
    } else {
      switch (user.role) {
        case 'admin':
          target = const AdminDashboardScreen();
          break;
        case 'staff':
          target = const StaffHomeScreen();
          break;
        case 'teacher':
        default:
          target = const TeacherHomeScreen();
      }
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: KeyedSubtree(key: ValueKey(target.runtimeType), child: target),
    );
  }
}
