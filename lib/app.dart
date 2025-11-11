import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/bus_management/bus_management_screen.dart';
import 'features/account_management/account_management_screen.dart';
import 'features/route_management/route_management_screen.dart';
import 'shared/widgets/layouts/app_shell.dart';
import 'providers/theme_provider.dart';
import 'features/auth/auth_provider.dart';

class BukTrackApp extends StatelessWidget {
  const BukTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'BukTrack Admin',
          debugShowCheckedModeBanner: false,

          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,

          home: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              // Show login screen if not authenticated or still initializing
              // This prevents black screen on startup
              if (!authProvider.isAuthenticated ||
                  !authProvider.isInitialized) {
                return const LoginScreen();
              }

              // Show dashboard if authenticated
              return AppShell(
                routes: {
                  '/dashboard': const DashboardScreen(),
                  '/account-management': const AccountManagementScreen(),
                  '/bus-management': const BusManagementScreen(),
                  '/route-management': const RouteManagementScreen(),
                  // TODO: Add more routes as screens are created
                  // '/activity-logs': const ActivityLogsScreen(),
                  // '/settings': const SettingsScreen(),
                },
              );
            },
          ),

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
