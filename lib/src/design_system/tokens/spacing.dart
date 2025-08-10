/// GigaEats Design System Spacing Tokens
/// 
/// Provides consistent spacing values based on 4px grid system
/// following Material Design 3 spacing guidelines.
class GESpacing {
  // Base unit (4px)
  static const double unit = 4.0;
  
  // Spacing scale
  static const double xs = unit; // 4px
  static const double sm = unit * 2; // 8px
  static const double md = unit * 3; // 12px
  static const double lg = unit * 4; // 16px
  static const double xl = unit * 6; // 24px
  static const double xxl = unit * 8; // 32px
  static const double xxxl = unit * 12; // 48px
  
  // Semantic spacing
  static const double none = 0.0;
  static const double tiny = xs; // 4px
  static const double small = sm; // 8px
  static const double medium = md; // 12px
  static const double large = lg; // 16px
  static const double extraLarge = xl; // 24px
  static const double huge = xxl; // 32px
  static const double massive = xxxl; // 48px
  
  // Component-specific spacing
  static const double buttonPadding = lg; // 16px
  static const double cardPadding = lg; // 16px
  static const double screenPadding = lg; // 16px
  static const double sectionSpacing = xl; // 24px
  static const double listItemSpacing = sm; // 8px
  static const double iconSpacing = sm; // 8px
  
  // Layout spacing
  static const double containerMargin = lg; // 16px
  static const double containerPadding = lg; // 16px
  static const double sectionMargin = xl; // 24px
  static const double sectionPadding = xl; // 24px
  
  // Form spacing
  static const double formFieldSpacing = lg; // 16px
  static const double formSectionSpacing = xl; // 24px
  static const double formButtonSpacing = xl; // 24px
  
  // Navigation spacing
  static const double navItemSpacing = sm; // 8px
  static const double navSectionSpacing = lg; // 16px
  static const double tabSpacing = md; // 12px
  
  // Grid spacing
  static const double gridGutter = lg; // 16px
  static const double gridMargin = lg; // 16px
}
