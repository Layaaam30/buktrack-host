import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'providers/theme_provider.dart';
import 'providers/navigation_provider.dart';
import 'features/auth/auth_provider.dart';
import 'features/bus_management/bus_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        // Auth Provider - Add this first as other providers may depend on it
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // Theme Provider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // Navigation Provider
        ChangeNotifierProvider(create: (_) => NavigationProvider()),

        // Bus Provider
        ChangeNotifierProvider(create: (_) => BusProvider()),

        // TODO: Add other providers as needed
        // ChangeNotifierProvider(create: (_) => RouteProvider()),
        // ChangeNotifierProvider(create: (_) => AccountProvider()),
      ],
      child: const BukTrackApp(),
    ),
  );
}
