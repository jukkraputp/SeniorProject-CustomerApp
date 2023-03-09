import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:customer/providers/app_provider.dart';
import 'package:customer/screens/splash.dart';
import 'package:customer/util/const.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

const bool USE_EMULATOR = false;
const bool clearPrefs = false;
Map<String, dynamic> bgMessageData = {};

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  RemoteNotification? noti = message.notification;
  Map<String, dynamic> data = message.data;
  print('data: $data');
  print("Handling a background message: ${message.messageId}");
  bgMessageData = data;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance
      .activate(androidProvider: AndroidProvider.playIntegrity);
  if (USE_EMULATOR) {
    await _connectToFirebaseEmulator();
  }
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if (clearPrefs) prefs.clear();

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  print('User granted permission: ${settings.authorizationStatus}');

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  final GoogleMapsFlutterPlatform mapsImplementation =
      GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    mapsImplementation.useAndroidViewSurface = true;
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: const CustomerApp(),
    ),
  );
}

Future _connectToFirebaseEmulator() async {
  final localHostString = Platform.isAndroid ? '10.0.2.2' : 'localhost';

  await FirebaseAuth.instance.useAuthEmulator(localHostString, 9099);
}

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    return Consumer<AppProvider>(builder:
        (BuildContext context, AppProvider appProvider, Widget? child) {
      return MaterialApp(
        key: appProvider.key,
        debugShowCheckedModeBanner: false,
        navigatorKey: appProvider.navigatorKey,
        title: Constants.appName,
        theme: appProvider.theme,
        // darkTheme: Constants.darkTheme,
        home: SplashScreen(
          debug: true,
          bgMessageData: bgMessageData,
        ),
      );
    });
  }
}
