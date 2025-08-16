import 'package:flutter/material.dart';

/// GigaEats Design System Border Radius Tokens
/// 
/// Provides consistent border radius values for creating
/// cohesive rounded corners across all UI components.
class GEBorderRadius {
  // Base radius values (following 4px grid)
  static const double none = 0.0;
  static const double xs = 2.0;
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double xxl = 20.0;
  static const double xxxl = 24.0;
  static const double full = 9999.0; // For circular elements
  
  // BorderRadius objects for common use cases
  static const BorderRadius noneRadius = BorderRadius.zero;
  
  static const BorderRadius xsRadius = BorderRadius.all(
    Radius.circular(xs),
  );
  
  static const BorderRadius smRadius = BorderRadius.all(
    Radius.circular(sm),
  );
  
  static const BorderRadius mdRadius = BorderRadius.all(
    Radius.circular(md),
  );
  
  static const BorderRadius lgRadius = BorderRadius.all(
    Radius.circular(lg),
  );
  
  static const BorderRadius xlRadius = BorderRadius.all(
    Radius.circular(xl),
  );
  
  static const BorderRadius xxlRadius = BorderRadius.all(
    Radius.circular(xxl),
  );
  
  static const BorderRadius xxxlRadius = BorderRadius.all(
    Radius.circular(xxxl),
  );
  
  // Directional border radius
  static const BorderRadius topSmRadius = BorderRadius.only(
    topLeft: Radius.circular(sm),
    topRight: Radius.circular(sm),
  );
  
  static const BorderRadius topMdRadius = BorderRadius.only(
    topLeft: Radius.circular(md),
    topRight: Radius.circular(md),
  );
  
  static const BorderRadius topLgRadius = BorderRadius.only(
    topLeft: Radius.circular(lg),
    topRight: Radius.circular(lg),
  );
  
  static const BorderRadius topXlRadius = BorderRadius.only(
    topLeft: Radius.circular(xl),
    topRight: Radius.circular(xl),
  );
  
  static const BorderRadius bottomSmRadius = BorderRadius.only(
    bottomLeft: Radius.circular(sm),
    bottomRight: Radius.circular(sm),
  );
  
  static const BorderRadius bottomMdRadius = BorderRadius.only(
    bottomLeft: Radius.circular(md),
    bottomRight: Radius.circular(md),
  );
  
  static const BorderRadius bottomLgRadius = BorderRadius.only(
    bottomLeft: Radius.circular(lg),
    bottomRight: Radius.circular(lg),
  );
  
  static const BorderRadius bottomXlRadius = BorderRadius.only(
    bottomLeft: Radius.circular(xl),
    bottomRight: Radius.circular(xl),
  );
  
  static const BorderRadius leftSmRadius = BorderRadius.only(
    topLeft: Radius.circular(sm),
    bottomLeft: Radius.circular(sm),
  );
  
  static const BorderRadius leftMdRadius = BorderRadius.only(
    topLeft: Radius.circular(md),
    bottomLeft: Radius.circular(md),
  );
  
  static const BorderRadius leftLgRadius = BorderRadius.only(
    topLeft: Radius.circular(lg),
    bottomLeft: Radius.circular(lg),
  );
  
  static const BorderRadius rightSmRadius = BorderRadius.only(
    topRight: Radius.circular(sm),
    bottomRight: Radius.circular(sm),
  );
  
  static const BorderRadius rightMdRadius = BorderRadius.only(
    topRight: Radius.circular(md),
    bottomRight: Radius.circular(md),
  );
  
  static const BorderRadius rightLgRadius = BorderRadius.only(
    topRight: Radius.circular(lg),
    bottomRight: Radius.circular(lg),
  );
  
  // Semantic border radius mappings
  static const BorderRadius button = lgRadius;
  static const BorderRadius card = lgRadius;
  static const BorderRadius input = mdRadius;
  static const BorderRadius dialog = xlRadius;
  static const BorderRadius bottomSheet = topXlRadius;
  static const BorderRadius chip = xxxlRadius;
  static const BorderRadius avatar = BorderRadius.all(Radius.circular(full));
  
  // Helper methods
  static BorderRadius circular(double radius) {
    return BorderRadius.circular(radius);
  }
  
  static BorderRadius only({
    double topLeft = 0.0,
    double topRight = 0.0,
    double bottomLeft = 0.0,
    double bottomRight = 0.0,
  }) {
    return BorderRadius.only(
      topLeft: Radius.circular(topLeft),
      topRight: Radius.circular(topRight),
      bottomLeft: Radius.circular(bottomLeft),
      bottomRight: Radius.circular(bottomRight),
    );
  }
  
  static BorderRadius top(double radius) {
    return BorderRadius.only(
      topLeft: Radius.circular(radius),
      topRight: Radius.circular(radius),
    );
  }
  
  static BorderRadius bottom(double radius) {
    return BorderRadius.only(
      bottomLeft: Radius.circular(radius),
      bottomRight: Radius.circular(radius),
    );
  }
  
  static BorderRadius left(double radius) {
    return BorderRadius.only(
      topLeft: Radius.circular(radius),
      bottomLeft: Radius.circular(radius),
    );
  }
  
  static BorderRadius right(double radius) {
    return BorderRadius.only(
      topRight: Radius.circular(radius),
      bottomRight: Radius.circular(radius),
    );
  }
}

/// Border helper for creating consistent borders
class GEBorder {
  // Border widths
  static const double thin = 1.0;
  static const double medium = 1.5;
  static const double thick = 2.0;
  
  // Helper methods for creating borders
  static Border all({
    Color? color,
    double width = thin,
  }) {
    return Border.all(
      color: color ?? const Color(0xFFE0E0E0),
      width: width,
    );
  }
  
  static Border only({
    Color? color,
    double width = thin,
    bool top = false,
    bool right = false,
    bool bottom = false,
    bool left = false,
  }) {
    final borderSide = BorderSide(
      color: color ?? const Color(0xFFE0E0E0),
      width: width,
    );
    
    return Border(
      top: top ? borderSide : BorderSide.none,
      right: right ? borderSide : BorderSide.none,
      bottom: bottom ? borderSide : BorderSide.none,
      left: left ? borderSide : BorderSide.none,
    );
  }
}
