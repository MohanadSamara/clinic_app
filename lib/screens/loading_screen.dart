// lib/screens/loading_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import '../../translations.dart';
import 'role_based_home.dart';
import '../../constants/appwrite_config.dart';

class LoadingScreen extends StatefulWidget {
  final Client client;

  const LoadingScreen({super.key, required this.client});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  bool _isPinging = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    // Fade animation
    _fadeController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    // Scale animation for icons
    _scaleController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Start animations
    _fadeController.forward();
    _scaleController.forward();

    // Auto-ping Appwrite when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pingAppwrite();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  /// OFFICIAL APPWRITE SDK WAY FOR FLUTTER
  /// ======================================
  ///
  /// WHY MANUAL HTTP CALLS ARE WRONG:
  /// 1. You need to manually construct endpoints and handle headers
  /// 2. You might call wrong endpoints (/health vs /health/project)
  /// 3. Manual HTTP can cause CORS issues in web builds
  /// 4. SDK handles authentication context automatically
  ///
  /// WHY 401/404 ERRORS OCCUR:
  /// 401 (Unauthorized):
  ///   - Wrong endpoint for the context
  ///   - Missing/incorrect authentication header
  ///   - Project ID not properly configured
  ///   - Using /health (public) with project header confuses server
  /// 404 (Not Found):
  ///   - Endpoint doesn't exist
  ///   - Wrong SDK version
  ///   - Region-specific endpoint issues
  ///
  Future<void> _pingAppwrite() async {
    if (_isPinging) return;

    setState(() {
      _isPinging = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Ping Appwrite using client.ping()
      await widget.client.ping().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
            'Connection timed out. Please check your internet connection.',
          );
        },
      );

      // If we get here, Appwrite is reachable and client is configured correctly
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appwrite ping successful!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RoleBasedHome()),
        );
      }
    } on AppwriteException catch (e) {
      _handleError('Appwrite Error: ${e.message} (Code: ${e.code})');
    } on TimeoutException catch (e) {
      _handleError(e.message ?? 'Connection timed out');
    } catch (e) {
      _handleError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isPinging = false);
      }
    }
  }

  void _handleError(String message) {
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ping failed: $message'),
          backgroundColor: Colors.red,
          action: SnackBarAction(label: 'Retry', onPressed: _pingAppwrite),
        ),
      );
    }
  }

  void _retryConnection() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });
    _pingAppwrite();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pet-themed icons with scale animation
              ScaleTransition(
                scale: _scaleAnimation,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pets,
                      size: 60,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.local_hospital,
                      size: 60,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.favorite,
                      size: 60,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // App title
              Text(
                context.tr('vet2U'),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Subtitle
              Text(
                context.tr('yourPetsHealthCompanion'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 48),
              // Loading indicator
              if (_isPinging)
                Column(
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('loading'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connecting to Appwrite...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                )
              else if (_hasError)
                Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Connection Error',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _errorMessage,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _retryConnection,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry Connection'),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('loading'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              // Send Ping button
              ElevatedButton(
                onPressed: _isPinging ? null : _pingAppwrite,
                child: _isPinging
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send Ping'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
