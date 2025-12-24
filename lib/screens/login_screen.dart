// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../translations.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import 'role_based_home.dart';
import 'role_selection_screen.dart';
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
                        ),
                        obscureText: true,
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

              const SizedBox(height: 24),

              // Social buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _googleSignIn,
                      icon: Icon(Icons.g_mobiledata, color: colorScheme.error),
                      label: Text(
                        context.tr('google'),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: colorScheme.outline.withOpacity(0.15),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: colorScheme.surface,
                        foregroundColor: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _facebookSignIn,
                      icon: Icon(Icons.facebook, color: colorScheme.secondary),
                      label: Text(
                        context.tr('facebook'),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: colorScheme.outline.withOpacity(0.15),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: colorScheme.surface,
                        foregroundColor: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),

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
    if (_password.text.isEmpty) {
      _showError(context.tr('pleaseEnterYourPassword'));
      return;
    }

    setState(() => _loading = true);
    try {
      await auth.login(email: _email.text.trim(), password: _password.text);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleBasedHome()),
        );
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
                  name: pending['name'],
                  email: pending['email'],
                  provider: pending['provider'],
                  providerId: pending['providerId'],
                ),
              ),
            );
          } else {
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

  Future<void> _facebookSignIn() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    setState(() => _loading = true);
    try {
      await auth.signInWithFacebook();
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (auth.needsRoleSelection) {
            final pending = auth.pendingSocialUser!;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => RoleSelectionScreen(
                  name: pending['name'],
                  email: pending['email'],
                  provider: pending['provider'],
                  providerId: pending['providerId'],
                ),
              ),
            );
          } else {
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
}
