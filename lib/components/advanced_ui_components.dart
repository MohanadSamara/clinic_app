// lib/components/advanced_ui_components.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../theme/app_theme.dart';

/// Advanced skeleton loader for professional loading states
class SkeletonLoader extends StatefulWidget {
  final double height;
  final double width;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration animationDuration;

  const SkeletonLoader({
    super.key,
    required this.height,
    required this.width,
    this.borderRadius = 8.0,
    this.baseColor,
    this.highlightColor,
    this.animationDuration = const Duration(milliseconds: 1200),
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.baseColor ?? Colors.grey[300]!;
    final highlightColor = widget.highlightColor ?? Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor,
                baseColor,
                highlightColor,
                baseColor,
                baseColor,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value - 0.1,
                _animation.value,
                _animation.value + 0.1,
                _animation.value + 0.3,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Professional skeleton screen for cards
class SkeletonCard extends StatelessWidget {
  final int itemCount;

  const SkeletonCard({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const SkeletonLoader(
                      height: 60,
                      width: 60,
                      borderRadius: 12,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLoader(
                            height: 16,
                            width: 120,
                            borderRadius: 4,
                          ),
                          const SizedBox(height: 8),
                          SkeletonLoader(
                            height: 12,
                            width: 80,
                            borderRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const SkeletonLoader(
                  height: 60,
                  width: double.infinity,
                  borderRadius: 8,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Advanced glassmorphic card with professional styling
class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final List<BoxShadow>? shadows;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.shadows,
    this.padding,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        boxShadow:
            shadows ??
            [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 0,
                offset: const Offset(0, 1),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color:
                backgroundColor ?? theme.colorScheme.surface.withOpacity(0.8),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: padding ?? const EdgeInsets.all(20),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Professional empty state with illustrations
class ProfessionalEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;
  final Widget? action;
  final String? illustrationPath;

  const ProfessionalEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconColor,
    this.action,
    this.illustrationPath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actualIconColor = this.iconColor ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: actualIconColor.withOpacity(0.1),
            ),
            child: Icon(icon, size: 48, color: actualIconColor),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: 32), action!],
        ],
      ),
    );
  }
}

/// Advanced circular progress indicator with percentage
class AdvancedCircularProgress extends StatefulWidget {
  final double progress;
  final String? label;
  final Color? backgroundColor;
  final Color? progressColor;
  final double strokeWidth;
  final double size;

  const AdvancedCircularProgress({
    super.key,
    required this.progress,
    this.label,
    this.backgroundColor,
    this.progressColor,
    this.strokeWidth = 8.0,
    this.size = 100.0,
  });

  @override
  State<AdvancedCircularProgress> createState() =>
      _AdvancedCircularProgressState();
}

class _AdvancedCircularProgressState extends State<AdvancedCircularProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: widget.progress).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _CircularProgressPainter(
              progress: _animation.value,
              backgroundColor:
                  widget.backgroundColor ??
                  theme.colorScheme.primary.withOpacity(0.1),
              progressColor: widget.progressColor ?? theme.colorScheme.primary,
              strokeWidth: widget.strokeWidth,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.label ?? '${(_animation.value * 100).toInt()}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: widget.progressColor ?? theme.colorScheme.primary,
                    ),
                  ),
                  if (widget.label != null)
                    Text(
                      'Progress',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = progress * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Professional metric card with advanced styling
class AdvancedMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final double? progress;
  final VoidCallback? onTap;
  final Widget? trailing;

  const AdvancedMetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.progress,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassmorphicCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.2), width: 1),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress!,
                      backgroundColor: color.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(progress! * 100).toInt()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Professional form input with real-time validation
class ProfessionalFormField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool autoValidate;
  final Function(String)? onChanged;
  final bool enabled;

  const ProfessionalFormField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.autoValidate = true,
    this.onChanged,
    this.enabled = true,
  });

  @override
  State<ProfessionalFormField> createState() => _ProfessionalFormFieldState();
}

class _ProfessionalFormFieldState extends State<ProfessionalFormField> {
  late FocusNode _focusNode;
  bool _hasFocus = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    if (widget.validator != null) {
      return widget.validator!(value);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isError = _errorText != null && _errorText!.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        validator: widget.autoValidate ? _validate : null,
        keyboardType: widget.keyboardType,
        obscureText: widget.obscureText,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        enabled: widget.enabled,
        onChanged: (value) {
          if (widget.onChanged != null) {
            widget.onChanged!(value);
          }
          if (widget.autoValidate) {
            setState(() {
              _errorText = _validate(value);
            });
          }
        },
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.suffixIcon,
          filled: true,
          fillColor: widget.enabled
              ? theme.colorScheme.surface
              : theme.colorScheme.onSurface.withOpacity(0.04),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isError
                  ? theme.colorScheme.error
                  : _hasFocus
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withOpacity(0.3),
              width: isError
                  ? 2
                  : _hasFocus
                  ? 2
                  : 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isError
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
          ),
          labelStyle: TextStyle(
            color: _hasFocus
                ? (isError
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary)
                : theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
      ),
    );
  }
}

/// Professional chart widget for medical data visualization
class ProfessionalChart extends StatelessWidget {
  final List<ChartData> data;
  final String title;
  final Color? color;
  final ChartType type;
  final double? height;

  const ProfessionalChart({
    super.key,
    required this.data,
    required this.title,
    this.color,
    this.type = ChartType.line,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chartColor = color ?? theme.colorScheme.primary;

    return Container(
      height: height ?? 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CustomPaint(
              painter: _ChartPainter(data: data, color: chartColor, type: type),
            ),
          ),
        ],
      ),
    );
  }
}

enum ChartType { line, bar }

class ChartData {
  final String label;
  final double value;
  final Color? color;

  const ChartData({required this.label, required this.value, this.color});
}

class _ChartPainter extends CustomPainter {
  final List<ChartData> data;
  final Color color;
  final ChartType type;

  _ChartPainter({required this.data, required this.color, required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final padding = 20.0;
    final chartWidth = size.width - 2 * padding;
    final chartHeight = size.height - 2 * padding;

    final maxValue = data.map((e) => e.value).reduce(math.max);
    final minValue = data.map((e) => e.value).reduce(math.min);
    final valueRange = maxValue - minValue == 0 ? 1 : maxValue - minValue;

    if (type == ChartType.line) {
      final points = <Offset>[];

      for (int i = 0; i < data.length; i++) {
        final x = padding + (i * chartWidth) / (data.length - 1);
        final normalizedValue = (data[i].value - minValue) / valueRange;
        final y = size.height - padding - (normalizedValue * chartHeight);
        points.add(Offset(x, y));
      }

      if (points.length > 1) {
        // Draw line
        for (int i = 0; i < points.length - 1; i++) {
          canvas.drawLine(points[i], points[i + 1], paint);
        }

        // Draw points
        for (final point in points) {
          canvas.drawCircle(point, 4, pointPaint);
        }

        // Fill under line
        final path = Path();
        path.moveTo(points.first.dx, points.first.dy);
        for (int i = 1; i < points.length; i++) {
          path.lineTo(points[i].dx, points[i].dy);
        }
        path.lineTo(points.last.dx, size.height - padding);
        path.lineTo(points.first.dx, size.height - padding);
        path.close();
        canvas.drawPath(path, fillPaint);
      }
    } else {
      // Bar chart
      final barWidth = chartWidth / data.length * 0.6;

      for (int i = 0; i < data.length; i++) {
        final x =
            padding +
            (i * chartWidth) / data.length +
            (chartWidth / data.length - barWidth) / 2;
        final normalizedValue = (data[i].value - minValue) / valueRange;
        final barHeight = normalizedValue * chartHeight;
        final y = size.height - padding - barHeight;

        final barPaint = Paint()
          ..color = data[i].color ?? color
          ..style = PaintingStyle.fill;

        final rect = Rect.fromLTWH(x, y, barWidth, barHeight);
        canvas.drawRect(rect, barPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Professional floating action button with enhanced styling
class ProfessionalFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final String? label;
  final IconData icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;

  const ProfessionalFAB({
    super.key,
    required this.onPressed,
    this.label,
    required this.icon,
    this.backgroundColor,
    this.iconColor,
    this.size = 56.0,
  });

  @override
  State<ProfessionalFAB> createState() => _ProfessionalFABState();
}

class _ProfessionalFABState extends State<ProfessionalFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: math.pi / 12,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              height: widget.size,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.backgroundColor ?? theme.colorScheme.primary,
                    (widget.backgroundColor ?? theme.colorScheme.primary)
                        .withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(widget.size / 2),
                boxShadow: [
                  BoxShadow(
                    color: (widget.backgroundColor ?? theme.colorScheme.primary)
                        .withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: Icon(
                        widget.icon,
                        color: widget.iconColor ?? Colors.white,
                        size: widget.size * 0.4,
                      ),
                    ),
                    if (widget.label != null) ...[
                      const SizedBox(width: 8),
                      AnimatedBuilder(
                        animation: _rotationAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: 1.0 - _rotationAnimation.value,
                            child: Text(
                              widget.label!,
                              style: TextStyle(
                                color: widget.iconColor ?? Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: widget.size * 0.3,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Professional bottom sheet with advanced styling
class ProfessionalBottomSheet extends StatefulWidget {
  final Widget child;
  final String title;
  final VoidCallback? onClose;
  final Color? backgroundColor;
  final bool showHandle;

  const ProfessionalBottomSheet({
    super.key,
    required this.child,
    required this.title,
    this.onClose,
    this.backgroundColor,
    this.showHandle = true,
  });

  @override
  State<ProfessionalBottomSheet> createState() =>
      _ProfessionalBottomSheetState();
}

class _ProfessionalBottomSheetState extends State<ProfessionalBottomSheet>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    _controller.reverse().then((_) {
      if (widget.onClose != null) {
        widget.onClose!();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _animation.value) * 100),
          child: Opacity(
            opacity: _animation.value,
            child: Container(
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.showHandle) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _close,
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  widget.child,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
