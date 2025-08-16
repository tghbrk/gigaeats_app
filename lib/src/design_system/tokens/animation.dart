import 'package:flutter/material.dart';

/// GigaEats Design System Animation Tokens
/// 
/// Provides consistent animation durations, curves, and transitions
/// for creating smooth and cohesive user experiences.
class GEAnimation {
  // Duration tokens (in milliseconds)
  static const Duration instant = Duration(milliseconds: 0);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration slower = Duration(milliseconds: 600);
  static const Duration slowest = Duration(milliseconds: 1000);
  
  // Semantic duration mappings
  static const Duration buttonPress = fast;
  static const Duration hover = fast;
  static const Duration focus = fast;
  static const Duration pageTransition = normal;
  static const Duration modalTransition = normal;
  static const Duration drawerTransition = normal;
  static const Duration snackbarTransition = normal;
  static const Duration tooltipTransition = fast;
  static const Duration loadingSpinner = slower;
  static const Duration shimmerEffect = slowest;
  
  // Animation curves
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve linear = Curves.linear;
  static const Curve bounceIn = Curves.bounceIn;
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve elasticIn = Curves.elasticIn;
  static const Curve elasticOut = Curves.elasticOut;
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;
  static const Curve slowOutFastIn = Curves.fastOutSlowIn; // Note: Using fastOutSlowIn as slowOutFastIn doesn't exist
  
  // Custom curves for GigaEats
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);
  static const Curve emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);
  static const Curve standard = Cubic(0.2, 0.0, 0.0, 1.0);
  static const Curve standardAccelerate = Cubic(0.3, 0.0, 1.0, 1.0);
  static const Curve standardDecelerate = Cubic(0.0, 0.0, 0.0, 1.0);
  
  // Semantic curve mappings
  static const Curve buttonCurve = emphasizedDecelerate;
  static const Curve pageCurve = standard;
  static const Curve modalCurve = emphasizedDecelerate;
  static const Curve drawerCurve = standard;
  static const Curve snackbarCurve = standard;
  static const Curve tooltipCurve = fastOutSlowIn;
  
  // Transition builders
  static Widget slideTransition({
    required Animation<double> animation,
    required Widget child,
    Offset begin = const Offset(1.0, 0.0),
    Offset end = Offset.zero,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: end,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: pageCurve,
      )),
      child: child,
    );
  }
  
  static Widget fadeTransition({
    required Animation<double> animation,
    required Widget child,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: begin,
        end: end,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: standard,
      )),
      child: child,
    );
  }
  
  static Widget scaleTransition({
    required Animation<double> animation,
    required Widget child,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: begin,
        end: end,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: emphasizedDecelerate,
      )),
      child: child,
    );
  }
  
  static Widget slideAndFadeTransition({
    required Animation<double> animation,
    required Widget child,
    Offset slideBegin = const Offset(0.0, 0.3),
    Offset slideEnd = Offset.zero,
    double fadeBegin = 0.0,
    double fadeEnd = 1.0,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: slideBegin,
        end: slideEnd,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: emphasizedDecelerate,
      )),
      child: FadeTransition(
        opacity: Tween<double>(
          begin: fadeBegin,
          end: fadeEnd,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: standard,
        )),
        child: child,
      ),
    );
  }
}

/// Page transition configurations
class GEPageTransitions {
  static const PageTransitionsTheme theme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: GEPageTransitionBuilder(),
      TargetPlatform.iOS: GEPageTransitionBuilder(),
      TargetPlatform.macOS: GEPageTransitionBuilder(),
      TargetPlatform.windows: GEPageTransitionBuilder(),
      TargetPlatform.linux: GEPageTransitionBuilder(),
    },
  );
}

/// Custom page transition builder for GigaEats
class GEPageTransitionBuilder extends PageTransitionsBuilder {
  const GEPageTransitionBuilder();
  
  @override
  Widget buildTransitions<T extends Object?>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return GEAnimation.slideAndFadeTransition(
      animation: animation,
      child: child,
    );
  }
}

/// Animation helper for creating consistent animated widgets
class GEAnimatedContainer extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BoxDecoration? decoration;
  
  const GEAnimatedContainer({
    super.key,
    required this.child,
    this.duration = GEAnimation.normal,
    this.curve = GEAnimation.standard,
    this.color,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.decoration,
  });
  
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      curve: curve,
      color: color,
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      decoration: decoration,
      child: child,
    );
  }
}
