import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/collector/collector_dashboard.dart';
import 'services/api_service.dart';
import 'services/mqtt_service.dart';
import 'services/push_notifications_service.dart';
import 'firebase_options.dart';

void main() async {
  // Ensure Flutter is initialized before calling asynchronous services
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (required for FCM).
  // NOTE: Replace placeholder options in `firebase_options.dart` (or generate with FlutterFire).
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // If Firebase isn't configured yet, we still allow the app to run.
    debugPrint('Firebase init skipped/failed: $e');
  }
  
  // Initialize API service
  final apiService = ApiService();
  await apiService.init();

  // Initialize push notifications (FCM)
  final pushService = PushNotificationsService();
  try {
    await pushService.init();
    // After permissions and FirebaseMessaging init, fetch FCM token and sync to backend
    if (apiService.hasToken) {
      final token = await pushService.getToken();
      if (token != null && token.isNotEmpty) {
        try {
          await apiService.updateFcmToken(token);
        } catch (e) {
          debugPrint('Failed to update FCM token: $e');
        }
      }
    }
  } catch (e) {
    debugPrint('Push notifications init failed: $e');
  }
  
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<MqttService>(create: (_) => MqttService()),
        Provider<PushNotificationsService>.value(value: pushService),
      ],
      child: const SmartBinApp(),
    ),
  );
}

class SmartBinApp extends StatelessWidget {
  const SmartBinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartBin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    // Splash screen delay
    await Future.delayed(const Duration(seconds: 2));

    // Check if token exists
    if (!apiService.hasToken) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    try {
      final profile = await apiService.getProfile();

      if (!mounted) return;

      if (profile['role'] == 'admin') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => AdminDashboard(user: profile)),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => CollectorDashboard(user: profile)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.delete_outline,
                size: 60,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'SmartBin',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Intelligent Waste Management',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}