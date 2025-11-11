import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/bus_management/screens/bus_management_screen.dart';
import 'features/account_management/screens/account_management_screen.dart';
import 'features/route_management/screens/route_management_screen.dart';
import 'shared/widgets/layouts/app_shell.dart';
import 'providers/theme_provider.dart';

class BukTrackApp extends StatelessWidget {
  const BukTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'BukTrack Admin',
          debugShowCheckedModeBanner: false,

          // Theme
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,

          // Home
          home: AppShell(
            routes: {
              '/dashboard': const DashboardScreen(),
              '/account-management': const AccountManagementScreen(),
              '/bus-management': const BusManagementScreen(),
              '/route-management': const RouteManagementScreen(),
              // TODO: Add more routes as screens are created
              // '/activity-logs': const ActivityLogsScreen(),
              // '/settings': const SettingsScreen(),
            },
          ),

          // Separate route for login (outside of AppShell)
          routes: {'/login': (context) => const LoginScreen()},

          // Builder for responsive handling
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaleFactor: 1.0, // Prevent text scaling
              ),
              child: child!,
            );
          },
        );
      },
    );
  }
}
