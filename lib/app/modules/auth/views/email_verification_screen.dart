import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medify/core/theme/app_theme.dart';
import 'package:medify/app/routes/app_routes.dart';
import '../controllers/auth_controller.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final AuthController _authController = Get.find<AuthController>();
  bool _isSendingVerification = false;
  bool _isCheckingVerification = false;

  Future<void> _checkVerification() async {
    setState(() {
      _isCheckingVerification = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      
      if (user != null && user.emailVerified) {
        Get.offAllNamed(AppRoutes.permissionRequest);
      } else {
        Get.snackbar('Not Verified', 'Please verify your email to continue.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to check verification status.');
    } finally {
      setState(() {
        _isCheckingVerification = false;
      });
    }
  }

  Future<void> _resendVerification() async {
    setState(() {
      _isSendingVerification = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
      Get.snackbar('Success', 'Verification email sent.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to send verification email. Please try again later.');
    } finally {
      setState(() {
        _isSendingVerification = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'your email';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.mark_email_read_outlined,
                size: 80,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: AppTheme.spacingXL),
              Text(
                'Verify Your Email',
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                'We\'ve sent a verification link to $email. Please check your inbox and verify your account.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXXL),
              
              ElevatedButton(
                onPressed: _isCheckingVerification ? null : _checkVerification,
                child: _isCheckingVerification
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('I\'ve Verified My Email'),
              ),
              const SizedBox(height: AppTheme.spacingM),
              
              OutlinedButton(
                onPressed: _isSendingVerification ? null : _resendVerification,
                child: _isSendingVerification
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        ),
                      )
                    : const Text('Resend Email'),
              ),
              const SizedBox(height: AppTheme.spacingL),
              
              TextButton(
                onPressed: () async {
                  await _authController.logout();
                  Get.offAllNamed(AppRoutes.login);
                },
                child: const Text('Change Email / Log Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
