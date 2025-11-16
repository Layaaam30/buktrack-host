import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'providers/theme_provider.dart';
import 'providers/navigation_provider.dart';
import 'features/auth/auth_provider.dart';
import 'features/bus_management/bus_provider.dart';
import 'features/account_management/account_provider.dart';
import 'features/route_management/route_provider.dart';
import 'features/dashboard/dashboard_analytics_provider.dart';
import 'features/activity_logs/activity_log_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => DashboardAnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => BusProvider()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => RouteProvider()),
        ChangeNotifierProvider(create: (_) => ActivityLogProvider())
      ],
      child: const BukTrackApp(),
    ),
  );
}
