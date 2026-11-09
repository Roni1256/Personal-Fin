import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/finance_provider.dart';
import '../../../core/services/api_service.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _onVerify() async {
    final code = _controllers.map((controller) => controller.text).join();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full 6-digit code')),
      );
      return;
    }

    final phone = '+91${widget.phoneNumber.trim()}';
    setState(() => _loading = true);

    try {
      final result = await ref.read(apiServiceProvider).verifyOtp(phone: phone, code: code);
      final accessToken = result['accessToken'] as String?;
      final refreshToken = result['refreshToken'] as String?;
      final user = result['user'] as Map<String, dynamic>? ?? {};
      final userId = user['id'] as String? ?? 'local-user';
      final userName = user['name'] as String? ?? 'User';
      final userPhone = user['phone'] as String? ?? phone;

      if (accessToken == null || refreshToken == null) {
        throw Exception('Authentication did not return tokens.');
      }

      await ref.read(authProvider.notifier).saveSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: userId,
        userName: userName,
        phone: userPhone,
      );

      final profileData = await ref.read(apiServiceProvider).getProfile(accessToken: accessToken);
      ref.read(profileProvider.notifier).applyProfile(profileData);

      if (!mounted) return;
      context.go('/onboarding');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Verify Phone',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit OTP code to +91 ${widget.phoneNumber.isNotEmpty ? widget.phoneNumber : "98765 43210"}',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48,
                    height: 56,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (val.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _onVerify,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify & Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('OTP re-sent successfully')),
                    );
                  },
                  child: const Text('Resend OTP in 28s'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
