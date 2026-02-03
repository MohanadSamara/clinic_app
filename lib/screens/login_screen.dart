// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../translations.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import 'role_based_home.dart';
import 'role_selection_screen.dart';
import 'doctor/doctor_verification_status_screen.dart';
import 'driver/driver_verification_status_screen.dart';
import 'email_verification_screen.dart';
import '../../translations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // Top area
              Center(
                child: Column(
                  children: [
                    Text(
                      context.tr('signIn'),
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('welcomeBackToVet2U'),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Form card
              Card(
                color: colorScheme.surface,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Form Fields
                      TextField(
                        controller: _email,
                        decoration: InputDecoration(
                          labelText: context.tr('emailAddress'),
                          hintText: context.tr('enterYourEmail'),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _password,
                        decoration: InputDecoration(
                          labelText: context.tr('password'),
                          hintText: context.tr('enterYourPassword'),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        obscureText: !_isPasswordVisible,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 24),

                      // Primary action button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: auth.isLoading || _loading
                            ? Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: colorScheme.onPrimary,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              )
                            : ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  textStyle: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                child: Text(context.tr('signIn')),
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const SizedBox(height: 32),

              // Divider with "Or continue with"
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: colorScheme.outline.withOpacity(0.3),
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      context.tr('orContinueWith'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: colorScheme.outline.withOpacity(0.3),
                      thickness: 1,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Social Sign In Buttons
              _buildSocialSignInButtons(),

              const SizedBox(height: 32),

              // Sign Up Link - secondary action
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.tr('dontHaveAccount'),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      context.tr('signUp'),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Basic validation
    if (_email.text.trim().isEmpty) {
      _showError(context.tr('pleaseEnterYourEmail'));
      return;
    }
    if (_password.text.trim().isEmpty) {
      _showError(context.tr('pleaseEnterYourPassword'));
      return;
    }

    setState(() => _loading = true);
    try {
      await auth.login(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );
      if (mounted) {
        // Check email verification first
        if (auth.user?.verificationStatus == 'unverified') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => EmailVerificationScreen(email: auth.user!.email),
            ),
          );
        } else {
          // For all verified users, go directly to home
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RoleBasedHome()),
          );
        }
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _googleSignIn() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    setState(() => _loading = true);
    try {
      await auth.signInWithGoogle();
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (auth.needsRoleSelection) {
            final pending = auth.pendingSocialUser!;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => RoleSelectionScreen(
                  name: pending['name'] ?? '',
                  email: pending['email'] ?? '',
                  provider: pending['provider'] ?? '',
                  providerId: pending['providerId'] ?? '',
                ),
              ),
            );
          } else {
            // For all verified users, go directly to home
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RoleBasedHome()),
            );
          }
        });
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildSocialSignInButtons() {
    final auth = Provider.of<AuthProvider>(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Google Sign In Button
        _buildSocialButton(
          icon: Icons.g_mobiledata,
          label: 'Google',
          onPressed: _googleSignIn,
          isLoading: auth.isLoading,
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isLoading,
  }) {
    return SizedBox(
      width: 150,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: Icon(icon, size: 24, color: Colors.black87),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }
}
