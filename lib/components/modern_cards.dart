import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../translations.dart';

/// Modern card components for the Vet2U app redesign
/// Implements the new design system with improved visual hierarchy

class ModernStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const ModernStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
        side: BorderSide(color: color.withOpacity(0.2), width: 1),
      ),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? color.withOpacity(0.9)
                      : color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold, color: color),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ModernActionCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool showArrow;

  const ModernActionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.showArrow = true,
  });

  @override
  State<ModernActionCard> createState() => _ModernActionCardState();
}

class _ModernActionCardState extends State<ModernActionCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _entryController;
  late Animation<double> _entryAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _entryController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _entryAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_entryAnimation, _scaleAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _entryAnimation.value)),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _entryAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.color.withOpacity(0.05),
                      Theme.of(context).colorScheme.surface,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
                  boxShadow: AppTheme.shadowMd,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    onTapDown: _handleTapDown,
                    onTapUp: _handleTapUp,
                    onTapCancel: _handleTapCancel,
                    borderRadius: BorderRadius.circular(
                      AppTheme.borderRadiusLg,
                    ),
                    splashColor: widget.color.withOpacity(0.1),
                    highlightColor: widget.color.withOpacity(0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  widget.color.withOpacity(
                                    0.1 + (_entryAnimation.value * 0.1),
                                  ),
                                  widget.color.withOpacity(
                                    0.05 + (_entryAnimation.value * 0.05),
                                  ),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppTheme.borderRadiusMd,
                              ),
                              boxShadow: _entryAnimation.value > 0.7
                                  ? AppTheme.shadowSm
                                  : null,
                            ),
                            child: Icon(
                              widget.icon,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? widget.color.withOpacity(0.9)
                                  : widget.color,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                ),
                                if (widget.subtitle != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.subtitle!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.6),
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (widget.showArrow) ...[
                            AnimatedOpacity(
                              opacity: _entryAnimation.value,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.arrow_forward_ios,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.8)
                                    : Colors.black87,
                                size: 16,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ModernGridCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  const ModernGridCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadiusLg,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 32,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? color.withOpacity(0.9)
                          : color,
                    ),
                  ),
                  if (badge != null) ...[
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadiusSm,
                          ),
                        ),
                        child: Text(
                          badge!,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ModernEmergencyCard extends StatelessWidget {
  final VoidCallback onTap;

  const ModernEmergencyCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    final onErrorColor = Theme.of(context).colorScheme.onError;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 6,
      shadowColor: errorColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
      ),
      color: isDark ? surfaceColor : errorColor.withOpacity(0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
                  border: Border.all(
                    color: errorColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(Icons.emergency, color: errorColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: errorColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '24/7 veterinary assistance',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: errorColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.phone, color: onErrorColor, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ModernProgressCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double progress;
  final Color color;
  final IconData icon;
  final bool showPercentage;

  const ModernProgressCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.color,
    required this.icon,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.05),
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      AppTheme.borderRadiusSm,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? color.withOpacity(0.9)
                        : color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (showPercentage)
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, animatedProgress, child) {
                return Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: animatedProgress,
                        backgroundColor: color.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 6,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
