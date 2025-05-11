// File: lib/main.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

import 'helpers/db_helper.dart';
import 'helpers/notification_helper.dart';
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
import 'auth/verify_otp_screen.dart';
import 'auth/reset_password_screen.dart';
import 'auth/change_password_screen.dart';
import 'auth/profile_screen.dart';

/// Background handler for FCM when the app is killed or in background
Future<void> _firebaseBackgroundHandler(RemoteMessage msg) async {
  await Firebase.initializeApp();
  await NotificationHelper.instance.showNotification(msg);
}

/// Buffer for any FCM messages arriving before UI is ready
final List<RemoteMessage> _pendingMessages = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize local DB (skip on web)
  if (!kIsWeb) {
    await DBHelper.initDb();
  }

  // Initialize local notifications & FCM listeners
  await NotificationHelper.instance.initialize();
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  FirebaseMessaging.onMessage.listen((msg) {
    NotificationHelper.instance.showNotification(msg);
    _pendingMessages.add(msg);
  });

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // After first frame, flush buffered messages into NotificationProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifProv = context.read<NotificationProvider>();
      for (var msg in _pendingMessages) {
        final n = msg.notification;
        if (n != null) {
          notifProv.add(title: n.title ?? '', body: n.body ?? '');
        }
      }
      _pendingMessages.clear();
    });
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
          return MaterialApp(
            title: 'University Asset Maintenance',
            debugShowCheckedModeBanner: false,

            // Light / Dark theming
            themeMode: theme.mode,
            theme: ThemeData(
              brightness: Brightness.light,
              primarySwatch: Colors.blue,
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.deepPurple,
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              ),
            ),

            // Pick the correct startup screen
            home: const AuthWrapper(),

            // Named routes
            routes: {
              '/login':           (_) => const LoginScreen(),
              '/register':        (_) => const RegisterScreen(),
              '/forgot-password': (_) => const ForgotPasswordScreen(),
              '/verify-otp':      (_) => const VerifyOtpScreen(mode: '', email: null),
              '/reset-password':  (_) => ResetPasswordScreen(email: ''),
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
    if (user == null) {
      // Not logged in yet
      return const HomeScreen();
    }
    // Logged in → go to role home
    switch (user.role) {
      case 'admin':
        return const AdminDashboardScreen();
      case 'staff':
        return const StaffHomeScreen();
      case 'teacher':
      default:
        return const TeacherHomeScreen();
    }
  }
}
