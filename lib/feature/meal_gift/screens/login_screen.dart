import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/auth_service.dart';
import '../utils/colors.dart';
import 'admin/admin_dashboard_screen.dart';
import 'user/user_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  bool _isGoogleLoading = false;

  void _handleGoogleLogin() async {
    setState(() => _isGoogleLoading = true);
    try {
      final credential = await _authService.signInWithGoogle();
      final user = credential?.user;
      if (user != null && mounted) {
        final name = user.displayName?.isNotEmpty == true ? user.displayName! : 'User';
        final appState = Provider.of<AppState>(context, listen: false);
        await appState.loginWithName(name, email: user.email, photoUrl: user.photoURL, uid: user.uid);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UserDashboardScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign In Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showAdminLoginDialog(BuildContext context) {
    final adminCodeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Admin Login', style: TextStyle(fontSize: 20.sp)),
          content: TextField(
            controller: adminCodeController,
            decoration: const InputDecoration(
              hintText: 'Enter Admin Code',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppColors.textDark, fontSize: 14.sp)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              ),
              onPressed: () {
                if (adminCodeController.text == '2233') {
                  Navigator.pop(context);
                  Provider.of<AppState>(context, listen: false).loginAsAdmin();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid Admin Code')),
                  );
                }
              },
              child: Text('Login', style: TextStyle(color: Colors.white, fontSize: 14.sp)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('See your contribution', style: TextStyle(color: Colors.black, fontSize: 20.sp)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.admin_panel_settings, color: AppColors.primaryGreen, size: 24.sp),
            tooltip: 'Admin Login',
            onPressed: () => _showAdminLoginDialog(context),
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: SizedBox(
            height: 54.h,
            child: ElevatedButton(
              onPressed: _isGoogleLoading ? null : _handleGoogleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: _isGoogleLoading
                  ? SizedBox(
                      height: 22.h,
                      width: 22.h,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/images/google-circle.svg',
                          width: 24.w,
                          height: 24.w,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Login with Google',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
