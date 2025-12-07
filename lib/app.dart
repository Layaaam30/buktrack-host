import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/auth_provider.dart';

// Admin Screens
import 'features/admin/dashboard/dashboard_screen.dart';
import 'features/admin/bus_management/bus_management_screen.dart';
import 'features/admin/account_management/account_management_screen.dart';
import 'features/admin/route_management/route_management_screen.dart';
import 'features/admin/activity_logs/activity_logs_screen.dart';
import 'features/admin/waypoint_management/waypoint_management_screen.dart';

// SuperAdmin Screens
import 'features/superadmin/company_management/company_management_screen.dart';
import 'features/superadmin/admin_management/admin_management_screen.dart';
import 'features/superadmin/dashboard/superadmin_dashboard_screen.dart';

// App Shells
import 'shared/widgets/layouts/app_shell.dart';
import 'shared/widgets/layouts/superadmin_app_shell.dart';

import 'providers/theme_provider.dart';

class BukTrackApp extends StatelessWidget {
  const BukTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'BUKTRACK',
          debugShowCheckedModeBanner: false,

          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,

          home: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (!authProvider.isAuthenticated ||
                  !authProvider.isInitialized) {
                return const LoginScreen();
              }

              if (authProvider.isSuperAdmin) {
                return SuperAdminShell(
                  routes: {
                    '/dashboard': const SuperAdminDashboardScreen(),
                    '/companies': const CompanyManagementScreen(),
                    '/admins': const AdminManagementScreen(),
                    '/activity-logs': const Placeholder(
                      child: Center(child: Text('SuperAdmin Activity Logs')),
                    ),
                    '/settings': const Placeholder(
                      child: Center(child: Text('SuperAdmin Settings')),
                    ),
                  },
                );
              } else {
                return AppShell(
                  routes: {
                    '/dashboard': const DashboardScreen(),
                    '/account-management': const AccountManagementScreen(),
                    '/bus-management': const BusManagementScreen(),
                    '/route-management': const RouteManagementScreen(),
                    '/waypoint-management': const WaypointManagementScreen(),
                    '/activity-logs': const ActivityLogsScreen(),
                  },
                );
              }
            },
          ),

          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
              child: child!,
            );
          },
        );
      },
    );
  }
}
