import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'screens/login_screen.dart';
import 'screens/user/user_dashboard_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'utils/colors.dart';

class MealGiftEntryScreen extends StatefulWidget {
  const MealGiftEntryScreen({
    super.key,
    this.showAdmin,
  });

  /// When true, opens the Admin Panel directly.
  /// When false, opens the User Panel directly.
  /// When null, auto-detects based on auth/app state.
  final bool? showAdmin;

  @override
  State<MealGiftEntryScreen> createState() => _MealGiftEntryScreenState();
}

class _MealGiftEntryScreenState extends State<MealGiftEntryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final appState = Provider.of<AppState>(context, listen: false);
      if (widget.showAdmin == true) {
        appState.loginAsAdmin();
      } else if (widget.showAdmin == false) {
        appState.logoutAdmin();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    if (!appState.isInitialized) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      );
    }

    // Force user panel if specifically requested
    if (widget.showAdmin == false) {
      return const UserDashboardScreen();
    }

    // Force admin panel if requested or if logged in as admin
    if (widget.showAdmin == true || appState.isAdmin) {
      return const AdminDashboardScreen();
    }

    if (appState.currentUser != null) {
      return const UserDashboardScreen();
    }

    return const LoginScreen();
  }
}
