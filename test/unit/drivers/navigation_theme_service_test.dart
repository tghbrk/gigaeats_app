import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gigaeats_app/src/features/drivers/presentation/theming/navigation_theme_service.dart';

void main() {
  group('NavigationThemeService Tests', () {
    late ThemeData baseTheme;
    late ColorScheme colorScheme;
    late TextTheme textTheme;

    setUp(() {
      colorScheme = const ColorScheme.light();
      textTheme = Typography.englishLike2018;
      baseTheme = ThemeData(
        colorScheme: colorScheme,
        textTheme: textTheme,
      );
    });

    group('Navigation Colors', () {
      test('should create navigation color scheme with correct colors', () {
        // Act
        final navColors = NavigationThemeService.getNavigationColors(colorScheme);

        // Assert
        expect(navColors.navigationPrimary, equals(colorScheme.primary));
        expect(navColors.navigationOnPrimary, equals(colorScheme.onPrimary));
        expect(navColors.navigationPrimaryContainer, equals(colorScheme.primaryContainer));
        expect(navColors.navigationOnPrimaryContainer, equals(colorScheme.onPrimaryContainer));
        
        // Status colors
        expect(navColors.successColor, isA<Color>());
        expect(navColors.warningColor, isA<Color>());
        expect(navColors.errorColor, equals(colorScheme.error));
        expect(navColors.infoColor, isA<Color>());
        
        // Traffic colors
        expect(navColors.trafficLight, isA<Color>());
        expect(navColors.trafficModerate, isA<Color>());
        expect(navColors.trafficHeavy, isA<Color>());
        expect(navColors.trafficSevere, isA<Color>());
        
        // Battery colors
        expect(navColors.batteryGood, isA<Color>());
        expect(navColors.batteryLow, isA<Color>());
        expect(navColors.batteryCritical, isA<Color>());
        expect(navColors.batteryCharging, isA<Color>());
        
        // Map colors
        expect(navColors.routeColor, isA<Color>());
        expect(navColors.routeAlternativeColor, isA<Color>());
        expect(navColors.currentLocationColor, equals(colorScheme.primary));
        expect(navColors.destinationColor, isA<Color>());
        expect(navColors.waypointColor, isA<Color>());
        
        // Surface colors
        expect(navColors.navigationSurface, equals(colorScheme.surface));
        expect(navColors.navigationSurfaceContainer, equals(colorScheme.surfaceContainer));
        expect(navColors.navigationSurfaceContainerHigh, equals(colorScheme.surfaceContainerHigh));
        expect(navColors.navigationSurfaceContainerHighest, equals(colorScheme.surfaceContainerHighest));
      });
    });

    group('Navigation Text Theme', () {
      test('should create navigation text theme with correct styles', () {
        // Act
        final navTextTheme = NavigationThemeService.getNavigationTextTheme(textTheme);

        // Assert
        expect(navTextTheme.instructionTitle, isA<TextStyle>());
        expect(navTextTheme.instructionSubtitle, isA<TextStyle>());
        expect(navTextTheme.instructionDistance, isA<TextStyle>());
        expect(navTextTheme.statsValue, isA<TextStyle>());
        expect(navTextTheme.statsLabel, isA<TextStyle>());
        expect(navTextTheme.statsUnit, isA<TextStyle>());
        expect(navTextTheme.statusTitle, isA<TextStyle>());
        expect(navTextTheme.statusMessage, isA<TextStyle>());
        expect(navTextTheme.buttonPrimary, isA<TextStyle>());
        expect(navTextTheme.buttonSecondary, isA<TextStyle>());
        
        // Check font weights
        expect(navTextTheme.instructionTitle?.fontWeight, equals(FontWeight.bold));
        expect(navTextTheme.instructionSubtitle?.fontWeight, equals(FontWeight.w500));
        expect(navTextTheme.instructionDistance?.fontWeight, equals(FontWeight.bold));
        expect(navTextTheme.statsValue?.fontWeight, equals(FontWeight.bold));
        expect(navTextTheme.statusTitle?.fontWeight, equals(FontWeight.bold));
        expect(navTextTheme.buttonPrimary?.fontWeight, equals(FontWeight.w600));
        expect(navTextTheme.buttonSecondary?.fontWeight, equals(FontWeight.w500));
      });
    });

    group('Loading State Theme', () {
      test('should create loading state theme with correct colors', () {
        // Act
        final loadingTheme = NavigationThemeService.getLoadingStateTheme(colorScheme);

        // Assert
        expect(loadingTheme.shimmerBaseColor, equals(colorScheme.surfaceContainer));
        expect(loadingTheme.shimmerHighlightColor, equals(colorScheme.surfaceContainerHighest));
        expect(loadingTheme.progressIndicatorColor, equals(colorScheme.primary));
        expect(loadingTheme.loadingOverlayColor, isA<Color>());
        expect(loadingTheme.loadingTextColor, equals(colorScheme.onSurface));
      });
    });

    group('Elevation Theme', () {
      test('should create elevation theme with correct values', () {
        // Act
        final elevationTheme = NavigationThemeService.getElevationTheme(colorScheme);

        // Assert
        expect(elevationTheme.cardElevation, equals(4.0));
        expect(elevationTheme.overlayElevation, equals(8.0));
        expect(elevationTheme.dialogElevation, equals(12.0));
        expect(elevationTheme.bottomSheetElevation, equals(16.0));
        expect(elevationTheme.shadowColor, isA<Color>());
      });
    });

    group('Animation Durations', () {
      test('should create animation durations with correct values', () {
        // Act
        final animationDurations = NavigationThemeService.getAnimationDurations();

        // Assert
        expect(animationDurations.fast, equals(const Duration(milliseconds: 150)));
        expect(animationDurations.medium, equals(const Duration(milliseconds: 300)));
        expect(animationDurations.slow, equals(const Duration(milliseconds: 500)));
        expect(animationDurations.instructionTransition, equals(const Duration(milliseconds: 400)));
        expect(animationDurations.cameraTransition, equals(const Duration(milliseconds: 600)));
        expect(animationDurations.loadingFade, equals(const Duration(milliseconds: 200)));
      });
    });

    group('Border Radius Theme', () {
      test('should create border radius theme with correct values', () {
        // Act
        final borderRadiusTheme = NavigationThemeService.getBorderRadiusTheme();

        // Assert
        expect(borderRadiusTheme.small, equals(8.0));
        expect(borderRadiusTheme.medium, equals(12.0));
        expect(borderRadiusTheme.large, equals(16.0));
        expect(borderRadiusTheme.extraLarge, equals(20.0));
        expect(borderRadiusTheme.circular, equals(28.0));
      });
    });

    group('Spacing Theme', () {
      test('should create spacing theme with correct values', () {
        // Act
        final spacingTheme = NavigationThemeService.getSpacingTheme();

        // Assert
        expect(spacingTheme.xs, equals(4.0));
        expect(spacingTheme.sm, equals(8.0));
        expect(spacingTheme.md, equals(12.0));
        expect(spacingTheme.lg, equals(16.0));
        expect(spacingTheme.xl, equals(20.0));
        expect(spacingTheme.xxl, equals(24.0));
        expect(spacingTheme.xxxl, equals(32.0));
      });
    });

    group('Complete Navigation Theme', () {
      test('should create complete navigation theme data', () {
        // Act
        final navigationTheme = NavigationThemeService.createNavigationTheme(baseTheme);

        // Assert
        expect(navigationTheme.colors, isA<NavigationColorScheme>());
        expect(navigationTheme.textTheme, isA<NavigationTextTheme>());
        expect(navigationTheme.loadingTheme, isA<LoadingStateTheme>());
        expect(navigationTheme.elevationTheme, isA<ElevationTheme>());
        expect(navigationTheme.animationDurations, isA<AnimationDurations>());
        expect(navigationTheme.borderRadius, isA<BorderRadiusTheme>());
        expect(navigationTheme.spacing, isA<SpacingTheme>());
      });
    });

    group('Navigation Theme Widget', () {
      testWidgets('should provide navigation theme data to child widgets', (WidgetTester tester) async {
        // Arrange
        final navigationTheme = NavigationThemeService.createNavigationTheme(baseTheme);
        NavigationThemeData? capturedTheme;

        // Act
        await tester.pumpWidget(
          MaterialApp(
            theme: baseTheme,
            home: NavigationTheme(
              data: navigationTheme,
              child: Builder(
                builder: (context) {
                  capturedTheme = NavigationTheme.of(context);
                  return const Scaffold(
                    body: Text('Test'),
                  );
                },
              ),
            ),
          ),
        );

        // Assert
        expect(capturedTheme, isNotNull);
        expect(capturedTheme, equals(navigationTheme));
      });

      testWidgets('should return null when no navigation theme is provided', (WidgetTester tester) async {
        // Arrange
        NavigationThemeData? capturedTheme;

        // Act
        await tester.pumpWidget(
          MaterialApp(
            theme: baseTheme,
            home: Builder(
              builder: (context) {
                capturedTheme = NavigationTheme.of(context);
                return const Scaffold(
                  body: Text('Test'),
                );
              },
            ),
          ),
        );

        // Assert
        expect(capturedTheme, isNull);
      });
    });

    group('Theme Application', () {
      testWidgets('should apply navigation theme to widget tree', (WidgetTester tester) async {
        // Arrange
        NavigationThemeData? capturedTheme;

        // Act
        await tester.pumpWidget(
          MaterialApp(
            theme: baseTheme,
            home: Builder(
              builder: (context) {
                return NavigationThemeService.applyNavigationTheme(
                  context: context,
                  child: Builder(
                    builder: (innerContext) {
                      capturedTheme = NavigationTheme.of(innerContext);
                      return const Scaffold(
                        body: Text('Test'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        );

        // Assert
        expect(capturedTheme, isNotNull);
        expect(capturedTheme?.colors, isA<NavigationColorScheme>());
        expect(capturedTheme?.textTheme, isA<NavigationTextTheme>());
      });
    });

    group('Color Scheme Properties', () {
      test('should have distinct colors for different traffic conditions', () {
        // Act
        final navColors = NavigationThemeService.getNavigationColors(colorScheme);

        // Assert
        expect(navColors.trafficLight, isNot(equals(navColors.trafficModerate)));
        expect(navColors.trafficModerate, isNot(equals(navColors.trafficHeavy)));
        expect(navColors.trafficHeavy, isNot(equals(navColors.trafficSevere)));
      });

      test('should have distinct colors for different battery states', () {
        // Act
        final navColors = NavigationThemeService.getNavigationColors(colorScheme);

        // Assert
        expect(navColors.batteryGood, isNot(equals(navColors.batteryLow)));
        expect(navColors.batteryLow, isNot(equals(navColors.batteryCritical)));
        expect(navColors.batteryCritical, isNot(equals(navColors.batteryCharging)));
      });

      test('should have distinct colors for different map elements', () {
        // Act
        final navColors = NavigationThemeService.getNavigationColors(colorScheme);

        // Assert
        expect(navColors.routeColor, isNot(equals(navColors.routeAlternativeColor)));
        expect(navColors.currentLocationColor, isNot(equals(navColors.destinationColor)));
        expect(navColors.destinationColor, isNot(equals(navColors.waypointColor)));
      });
    });
  });
}
