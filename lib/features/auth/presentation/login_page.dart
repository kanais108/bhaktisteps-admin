import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/auth_storage.dart';
import '../data/auth_repository.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final otpController = TextEditingController();

  bool otpRequested = false;
  bool loading = false;
  String? error;

  late final AuthRepository authRepository;

  @override
  void initState() {
    super.initState();
    final authStorage = AuthStorage();
    authRepository = AuthRepository(
      apiClient: ApiClient(authStorage: authStorage),
      authStorage: authStorage,
    );
  }

  Future<void> requestOtp() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      await authRepository.requestOtp(emailController.text);
      setState(() {
        otpRequested = true;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to request OTP';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> verifyOtp() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      await authRepository.verifyOtp(
        email: emailController.text,
        otp: otpController.text,
      );
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      setState(() {
        error = 'Invalid OTP or login failed';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Bhakti Steps Admin',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in with email OTP',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              if (otpRequested) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: otpController,
                  decoration: const InputDecoration(
                    labelText: 'OTP',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              if (error != null) ...[
                const SizedBox(height: 16),
                Text(error!, style: const TextStyle(color: AppColors.danger)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading
                      ? null
                      : otpRequested
                      ? verifyOtp
                      : requestOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: Text(
                    loading
                        ? 'Please wait...'
                        : otpRequested
                        ? 'Verify OTP'
                        : 'Request OTP',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
