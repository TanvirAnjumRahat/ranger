import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'auth/auth_home_page.dart';
import 'providers/auth_provider.dart';
import 'providers/routine_provider.dart';
import 'routes.dart';
import 'providers/notifications_provider.dart';
import 'app_navigator.dart';
import 'providers/filters_provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized in background isolate
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    Future<void> initFirebase() async {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        // FCM background messages
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );
        // If app opened from terminated by tapping a notification
        final initial = await FirebaseMessaging.instance.getInitialMessage();
        if (initial != null) {
          // Optionally surface a simple snackbar after first frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final ctx = appNavigatorKey.currentContext;
            if (ctx != null) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Opened from notification')),
              );
            }
          });
        }
        // When app is in background and brought to foreground via notification tap
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          final ctx = appNavigatorKey.currentContext;
          if (ctx != null) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('Notification tapped')),
            );
          }
        });
      } on UnsupportedError catch (e) {
        if (kIsWeb) {
          throw UnsupportedError(
            'Firebase is not configured for Web in firebase_options.dart.\n'
            'Run on Android/iOS or configure Web with FlutterFire (flutterfire configure).\n\n$e',
          );
        }
        rethrow;
      }
    }

    return FutureBuilder(
      future: initFirebase(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Failed to initialize Firebase:\n\n'
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => RoutinesProvider()),
            ChangeNotifierProvider(
              create: (_) => NotificationsProvider()
                ..initialize()
                ..initializeFCM(),
            ),
            ChangeNotifierProvider(create: (_) => FiltersProvider()),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Routine Ranger',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            navigatorKey: appNavigatorKey,
            onGenerateRoute: onGenerateRoute,
            home: const AuthHomePage(),
          ),
        );
      },
    );
  }
}
