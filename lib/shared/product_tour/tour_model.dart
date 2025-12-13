import 'package:flutter/material.dart';

class TourStep {
  GlobalKey targetKey; // Made mutable so it can be assigned later
  final String title;
  final String description;
  final IconData icon;
  final TourStepPosition position;

  TourStep({
    required this.targetKey,
    required this.title,
    required this.description,
    required this.icon,
    this.position = TourStepPosition.bottom,
  });
}

enum TourStepPosition { top, bottom, left, right, center }

class TourConfig {
  static List<TourStep> get adminTourSteps => [
    TourStep(
      targetKey: GlobalKey(), // Placeholder, will be reassigned
      title: 'Welcome to BukTrack! 👋',
      description:
          'Let\'s take a quick tour to help you get started. This will only take a minute.',
      icon: Icons.waving_hand,
      position: TourStepPosition.center,
    ),
    TourStep(
      targetKey: GlobalKey(), // Will be assigned to dashboard link
      title: 'Dashboard',
      description:
          'Your command center. View real-time bus locations, active routes, and system analytics at a glance.',
      icon: Icons.dashboard,
      position: TourStepPosition.right,
    ),
    TourStep(
      targetKey: GlobalKey(), // Will be assigned to account link
      title: 'Account Management',
      description:
          'Manage all users here. Add drivers, register passengers, and control access permissions.',
      icon: Icons.people,
      position: TourStepPosition.right,
    ),
    TourStep(
      targetKey: GlobalKey(), // Will be assigned to bus link
      title: 'Bus Management',
      description:
          'Your fleet headquarters. Add buses, track maintenance schedules, and monitor vehicle status.',
      icon: Icons.directions_bus,
      position: TourStepPosition.right,
    ),
    TourStep(
      targetKey: GlobalKey(), // Will be assigned to route link
      title: 'Route Management',
      description:
          'Design and manage bus routes. Set schedules, define stops, and assign buses to routes.',
      icon: Icons.route,
      position: TourStepPosition.right,
    ),
    TourStep(
      targetKey: GlobalKey(), // Will be assigned to waypoint link
      title: 'Waypoint Management',
      description:
          'Set up checkpoints along routes. Create waypoints for accurate tracking and estimated arrival times.',
      icon: Icons.location_on,
      position: TourStepPosition.right,
    ),
    TourStep(
      targetKey: GlobalKey(), // Will be assigned to activity link
      title: 'Activity Logs',
      description:
          'Track all system activities. See who did what and when for complete audit trails.',
      icon: Icons.history,
      position: TourStepPosition.right,
    ),
    TourStep(
      targetKey: GlobalKey(), // Will be assigned to dark mode toggle
      title: 'Theme Toggle',
      description:
          'Switch between light and dark mode. Choose what\'s comfortable for your eyes.',
      icon: Icons.dark_mode,
      position: TourStepPosition.top,
    ),
    TourStep(
      targetKey: GlobalKey(), // Will be assigned to user profile
      title: 'Your Profile',
      description:
          'Access your account settings, view profile information, or logout from here.',
      icon: Icons.account_circle,
      position: TourStepPosition.top,
    ),
    TourStep(
      targetKey: GlobalKey(), // Placeholder for center step
      title: 'You\'re All Set! 🎉',
      description:
          'You\'re ready to manage your bus system. Start by adding buses and creating routes. Need help? Check the documentation or contact support.',
      icon: Icons.check_circle,
      position: TourStepPosition.center,
    ),
  ];

  static List<TourStep> get superAdminTourSteps => [
    TourStep(
      targetKey: GlobalKey(), // Placeholder
      title: 'Welcome, SuperAdmin! 👨‍💼',
      description:
          'You have full system access. Let\'s explore your powerful administrative tools.',
      icon: Icons.admin_panel_settings,
      position: TourStepPosition.center,
    ),
    TourStep(
      targetKey: GlobalKey(), // Will be assigned to dashboard
      title: 'SuperAdmin Dashboard',
      description:
          'Monitor the entire system. View all companies, system health, and global statistics.',
      icon: Icons.dashboard,
      position: TourStepPosition.right,
    ),
    TourStep(
      targetKey: GlobalKey(), // Will be assigned to companies
      title: 'Company Management',
      description:
          'Oversee all bus companies. Create, edit, or deactivate company accounts and monitor their activities.',
      icon: Icons.business,
      position: TourStepPosition.right,
    ),
    TourStep(
      targetKey: GlobalKey(), // Will be assigned to admins
      title: 'Admin Management',
      description:
          'Control admin access across all companies. Assign roles, manage permissions, and monitor admin activities.',
      icon: Icons.supervised_user_circle,
      position: TourStepPosition.right,
    ),
    TourStep(
      targetKey: GlobalKey(), // Will be assigned to dark mode
      title: 'Theme Toggle',
      description:
          'Switch between light and dark themes for comfortable viewing.',
      icon: Icons.dark_mode,
      position: TourStepPosition.top,
    ),
    TourStep(
      targetKey: GlobalKey(), // Placeholder
      title: 'You\'re Ready! 🚀',
      description:
          'Start managing the entire BukTrack system. All companies and admins are under your control.',
      icon: Icons.check_circle,
      position: TourStepPosition.center,
    ),
  ];
}
