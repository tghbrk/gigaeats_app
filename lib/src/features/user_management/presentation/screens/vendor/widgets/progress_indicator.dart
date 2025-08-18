import 'package:flutter/material.dart';
import '../../../../../../design_system/tokens/ge_vendor_colors.dart';

/// Enhanced Progress Indicator for Dashboard Cards
/// 
/// A customizable progress bar component that displays progress
/// with smooth animations and custom styling.
class EnhancedProgressIndicator extends StatefulWidget {
  final double value; // 0.0 to 1.0
  final Color color;
  final Color? backgroundColor;
  final double height;
  final BorderRadius? borderRadius;
  final Duration animationDuration;
  final Curve animationCurve;

  const EnhancedProgressIndicator({
    super.key,
    required this.value,
    this.color = GEVendorColors.primaryGreen,
    this.backgroundColor,
    this.height = 4,
    this.borderRadius,
    this.animationDuration = const Duration(milliseconds: 600),
    this.animationCurve = Curves.easeInOut,
  });

  @override
  State<EnhancedProgressIndicator> createState() => _EnhancedProgressIndicatorState();
}

class _EnhancedProgressIndicatorState extends State<EnhancedProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.value.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    ));
    
    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EnhancedProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.value.clamp(0.0, 1.0),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: widget.animationCurve,
      ));
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ?? GEVendorColors.borderLight;
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(widget.height / 2);

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _animation.value,
            child: Container(
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: borderRadius,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Circular Progress Indicator for Dashboard
class EnhancedCircularProgressIndicator extends StatefulWidget {
  final double value; // 0.0 to 1.0
  final Color color;
  final Color? backgroundColor;
  final double size;
  final double strokeWidth;
  final Duration animationDuration;
  final Curve animationCurve;
  final Widget? child;

  const EnhancedCircularProgressIndicator({
    super.key,
    required this.value,
    this.color = GEVendorColors.primaryGreen,
    this.backgroundColor,
    this.size = 40,
    this.strokeWidth = 4,
    this.animationDuration = const Duration(milliseconds: 800),
    this.animationCurve = Curves.easeInOut,
    this.child,
  });

  @override
  State<EnhancedCircularProgressIndicator> createState() => _EnhancedCircularProgressIndicatorState();
}

class _EnhancedCircularProgressIndicatorState extends State<EnhancedCircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.value.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EnhancedCircularProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.value.clamp(0.0, 1.0),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: widget.animationCurve,
      ));
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ?? GEVendorColors.borderLight;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: widget.strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(backgroundColor),
          ),
          // Progress circle
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CircularProgressIndicator(
                value: _animation.value,
                strokeWidth: widget.strokeWidth,
                valueColor: AlwaysStoppedAnimation<Color>(widget.color),
              );
            },
          ),
          // Child widget (e.g., percentage text)
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

/// Multi-segment Progress Indicator
class MultiSegmentProgressIndicator extends StatefulWidget {
  final List<ProgressSegment> segments;
  final double height;
  final BorderRadius? borderRadius;
  final Duration animationDuration;

  const MultiSegmentProgressIndicator({
    super.key,
    required this.segments,
    this.height = 4,
    this.borderRadius,
    this.animationDuration = const Duration(milliseconds: 800),
  });

  @override
  State<MultiSegmentProgressIndicator> createState() => _MultiSegmentProgressIndicatorState();
}

class _MultiSegmentProgressIndicatorState extends State<MultiSegmentProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
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
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(widget.height / 2);
    final totalValue = widget.segments.fold<double>(0, (sum, segment) => sum + segment.value);

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: GEVendorColors.borderLight,
        borderRadius: borderRadius,
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Row(
            children: widget.segments.map((segment) {
              final segmentWidth = totalValue > 0 ? segment.value / totalValue : 0.0;
              return Expanded(
                flex: (segmentWidth * 100 * _animation.value).round(),
                child: Container(
                  decoration: BoxDecoration(
                    color: segment.color,
                    borderRadius: borderRadius,
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

/// Progress Segment for multi-segment progress indicator
class ProgressSegment {
  final double value;
  final Color color;
  final String? label;

  const ProgressSegment({
    required this.value,
    required this.color,
    this.label,
  });
}

/// Gradient Progress Indicator
class GradientProgressIndicator extends StatefulWidget {
  final double value;
  final Gradient gradient;
  final Color? backgroundColor;
  final double height;
  final BorderRadius? borderRadius;
  final Duration animationDuration;

  const GradientProgressIndicator({
    super.key,
    required this.value,
    required this.gradient,
    this.backgroundColor,
    this.height = 4,
    this.borderRadius,
    this.animationDuration = const Duration(milliseconds: 600),
  });

  @override
  State<GradientProgressIndicator> createState() => _GradientProgressIndicatorState();
}

class _GradientProgressIndicatorState extends State<GradientProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.value.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ?? GEVendorColors.borderLight;
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(widget.height / 2);

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _animation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: widget.gradient,
                borderRadius: borderRadius,
              ),
            ),
          );
        },
      ),
    );
  }
}
