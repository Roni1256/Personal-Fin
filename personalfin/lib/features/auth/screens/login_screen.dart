import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/finance_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/fin_orb.dart';
import '../widgets/google_sign_in_button_stub.dart'
  if (dart.library.js_interop) '../widgets/google_sign_in_button_web.dart' as google_button;

const _googleWebClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static Future<void>? _googleSignInInitialization;

  final _phoneController = TextEditingController();
  bool _consentChecked = true;
  bool _loading = false;
  bool _googleReady = false;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleEvents;

  @override
  void dispose() {
    _phoneController.dispose();
    _googleEvents?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    if (_googleWebClientId.isEmpty) return;
    try {
      final googleSignIn = GoogleSignIn.instance;
      _googleSignInInitialization ??= googleSignIn.initialize(
            clientId: kIsWeb ? _googleWebClientId : null,
            serverClientId: _googleWebClientId,
          );
      await _googleSignInInitialization;
      if (kIsWeb) {
        _googleEvents = googleSignIn.authenticationEvents.listen(
          _handleGoogleAuthenticationEvent,
          onError: _handleGoogleAuthenticationError,
        );
      }
      if (mounted) setState(() => _googleReady = true);
    } catch (error) {
      _showSignInError('Google sign-in could not be initialized: $error');
    }
  }

  void _handleGoogleAuthenticationEvent(GoogleSignInAuthenticationEvent event) {
    if (event is GoogleSignInAuthenticationEventSignIn) {
      unawaited(_completeGoogleSignIn(() async => event.user.authentication.idToken));
    }
  }

  void _handleGoogleAuthenticationError(Object error) {
    _showSignInError('Google sign-in failed: $error');
  }

  Future<void> _onGoogleSignInPressed() async {
    await _completeGoogleSignIn(() async {
      final account = await GoogleSignIn.instance.authenticate();
      return account.authentication.idToken;
    });
  }

  Future<void> _completeGoogleSignIn(Future<String?> Function() getIdToken) async {
    if (_loading || !_googleReady || !_consentChecked) return;
    setState(() => _loading = true);
    try {
      final idToken = await getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Google did not return an ID token. Check the OAuth client configuration.');
      }

      final result = await ref.read(apiServiceProvider).signInWithGoogle(idToken: idToken);
      final accessToken = result['accessToken'] as String?;
      final refreshToken = result['refreshToken'] as String?;
      final user = result['user'] as Map<String, dynamic>? ?? {};
      if (accessToken == null || refreshToken == null) {
        throw StateError('The backend did not return a PersonalFin session.');
      }

      await ref.read(authProvider.notifier).saveSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: user['id'] as String? ?? '',
        userName: user['name'] as String? ?? 'User',
        phone: user['phone'] as String? ?? '',
      );

      final profile = await ref.read(apiServiceProvider).getProfile(accessToken: accessToken);
      ref.read(profileProvider.notifier).applyProfile(profile);
      if (mounted) context.go('/onboarding');
    } catch (error) {
      _showSignInError('Could not sign in with Google: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSignInError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onGetOtp() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit mobile number')),
      );
      return;
    }

    final phone = '+91$rawPhone';
    setState(() => _loading = true);

    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.requestOtp(phone: phone);
      final devCode = result['devCode'] as String?;
      if (!mounted) return;
      if (devCode != null && devCode.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dev OTP: $devCode')),
        );
      }
      if (!mounted) return;
      context.push('/otp', extra: rawPhone);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send OTP: $error')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const Center(
                child: FinOrb(size: 72),
              ),
              const SizedBox(height: 28),
              const Text(
                'Welcome to\nPersonalFin ✦',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your phone number to get your AI monthly financial plan.',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 36),
              const Text(
                'Mobile Number',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  prefixText: '+91  ',
                  prefixStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  hintText: '98765 43210',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _consentChecked,
                      activeColor: AppColors.violet600,
                      onChanged: (v) => setState(() => _consentChecked = v ?? false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'I consent to DPDP Act 2023 compliant data storage and agree to Terms & Privacy Policy.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _consentChecked && !_loading ? _onGetOtp : null,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Get OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _googleWebClientId.isEmpty
                    ? OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                        label: const Text('Google sign-in needs GOOGLE_CLIENT_ID'),
                      )
                    : !_googleReady
                        ? OutlinedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                            label: const Text('Connecting to Google...'),
                          )
                    : google_button.buildGoogleSignInButton(
                        onPressed: _onGoogleSignInPressed,
                        enabled: _googleReady && !_loading && _consentChecked,
                      ),
              ),
              const SizedBox(height: 36),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Skip login for preview mode →'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
