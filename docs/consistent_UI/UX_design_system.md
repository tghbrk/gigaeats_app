# UX Design System Implementation Plan

I’m reviewing the current theme, navigation, and role-based UI. I see a central theme defined, GoRouter + Riverpod for navigation, and explicit RBAC enforcement. I also see multiple implementations of shared widgets like `CustomButton`/`CustomTextField` across different locations indicating duplication. I’ll propose a concrete, incremental plan with code-level changes to standardize Material 3 design, navigation, and reusable components while preserving role permissions.

Key references in your codebase:
- Theme setup in `AppTheme` with Material 3 enabled:
lib/main.dart
// Theme Configuration
theme: AppTheme.lightTheme,
darkTheme: AppTheme.darkTheme,
themeMode: ThemeMode.system,
```
lib/src/core/theme/app_theme.dart
static ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  ...
);
```
- RBAC + route permissions and patterns:
lib/src/core/services/access_control_service.dart
static const Map<String, Set<String>> _routePermissions = {
  '/customer/dashboard': {'place_order'},
  ... '/admin/drivers': {'manage_drivers'},
};
```
lib/src/core/services/access_control_service.dart
static RouteAccessResult checkRouteAccess(String route, UserRole? userRole) { ... }
```
- Centralized router with redirect logic:
lib/src/core/router/app_router.dart
final routerProvider = Provider<GoRouter>((ref) { ... });
```
lib/src/core/router/app_router.dart
// User is authenticated, check role-based access control...
```
- Existing role-specific dashboard using M3 `NavigationBar`:
lib/src/features/user_management/presentation/screens/sales_agent/sales_agent_dashboard.dart
bottomNavigationBar: NavigationBar(...)
```
- Duplicated shared widgets:
- `lib/src/features/shared/widgets/custom_button.dart` and `lib/src/shared/widgets/custom_button.dart`
- `lib/src/shared/widgets/custom_text_field.dart` and a second copy under `presentation`

### 1) Design System Standardization (Material 3)
Create a first-class design system module and move all theming + reusable widgets there.

- New directory structure:
  - `lib/src/design_system/`
    - `tokens/` color_scheme.dart, spacing.dart, radius.dart, elevation.dart, durations.dart, breakpoints.dart
    - `theme/` app_theme.dart (replace current), input_theme.dart, component_themes.dart, role_theme_extension.dart
    - `widgets/` ge_button.dart, ge_text_field.dart, ge_card.dart, ge_app_bar.dart, ge_chip.dart, ge_list_item.dart, ge_empty_state.dart, ge_error_state.dart, ge_loading_indicator.dart, ge_stat_tile.dart
    - `layout/` role_scaffold.dart, responsive_scaffold.dart
    - `navigation/` role_navigation.dart, role_navigation_items.dart

- Adopt Material 3 seed-based color generation:
```dart
// lib/src/design_system/tokens/color_scheme.dart
class GEPalette {
  static const seed = Color(0xFF1B5E20); // Giga Green
  static const success = Color(0xFF1DB954);
  static const warning = Color(0xFFFFA000);
  static const danger  = Color(0xFFD32F2F);
}

ColorScheme buildLightScheme({Color seed = GEPalette.seed}) =>
  ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);

ColorScheme buildDarkScheme({Color seed = GEPalette.seed}) =>
  ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);
```

- Update `AppTheme` to consume tokens rather than hardcoded colors, unify MD3 components, and centralize InputDecorationTheme, NavigationBarTheme, FilledButtonTheme, etc. Replace the current `AppTheme` with a slimmer one that uses `ColorScheme.fromSeed` and component themes.

- Role accent via `ThemeExtension`:
```dart
// lib/src/design_system/theme/role_theme_extension.dart
@immutable
class RoleTheme extends ThemeExtension<RoleTheme> {
  final Color customer;
  final Color vendor;
  final Color driver;
  final Color salesAgent;
  final Color admin;

  const RoleTheme({
    required this.customer,
    required this.vendor,
    required this.driver,
    required this.salesAgent,
    required this.admin,
  });

  @override
  RoleTheme copyWith({...}) => RoleTheme(
    customer: customer, vendor: vendor, driver: driver,
    salesAgent: salesAgent, admin: admin,
  );

  @override
  RoleTheme lerp(ThemeExtension<RoleTheme>? other, double t) => this;

  Color forRole(UserRole role) {
    switch (role) {
      case UserRole.customer: return customer;
      case UserRole.vendor: return vendor;
      case UserRole.driver: return driver;
      case UserRole.salesAgent: return salesAgent;
      case UserRole.admin: return admin;
    }
  }
}
```

- Provide a single source-of-truth `InputDecorationTheme`, `ButtonTheme`s, `CardTheme`, `SnackBarTheme`, `DialogTheme`, `NavigationBarTheme`, `ListTileTheme`, `ChipTheme`, `DividerTheme`. Ensure consistent radii (12), spacing (4/8/12/16/24/32), and typography scale derived from `TextTheme`.

- Integration in `MaterialApp` is already wired to `AppTheme`. Replace the current `AppTheme` with the new DS-backed `AppTheme` without changing the `main.dart` integration.

### 2) Navigation Patterns
Standardize navigation across roles with a single scaffold pattern and unified routing shells while preserving RBAC.

- Keep RBAC checks as-is via `AccessControlService` and `AuthGuard`.
- Introduce a `RoleScaffold` used by all role dashboards:
```dart
// lib/src/design_system/layout/role_scaffold.dart
class RoleScaffold extends ConsumerStatefulWidget {
  final List<Widget> tabs;
  final List<NavigationDestination> destinations;
  final PreferredSizeWidget? appBar;
  const RoleScaffold({super.key, required this.tabs, required this.destinations, this.appBar});

  @override
  ConsumerState<RoleScaffold> createState() => _RoleScaffoldState();
}

class _RoleScaffoldState extends ConsumerState<RoleScaffold> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.appBar,
      body: IndexedStack(index: index, children: widget.tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: widget.destinations,
      ),
    );
  }
}
```

- Normalize role nav items pulled from a single config:
```dart
// lib/src/design_system/navigation/role_navigation_items.dart
class RoleNav {
  static List<NavigationDestination> forRole(UserRole role) => switch (role) {
    UserRole.customer => const [
      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
      NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
      NavigationDestination(icon: Icon(Icons.wallet_outlined), selectedIcon: Icon(Icons.wallet), label: 'Wallet'),
      NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
    ],
    UserRole.vendor => const [ ... ],
    UserRole.driver => const [ ... ],
    UserRole.salesAgent => const [ ... ],
    UserRole.admin => const [ ... ],
  };
}
```

- Use GoRouter `ShellRoute` per role to ensure consistent structure and to swap `tabs` based on role, keeping RBAC redirect logic intact in the existing router:
```dart
// lib/src/core/router/app_router.dart (add shells, preserve existing AuthGuard + redirects)
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _AuthStateNotifier(ref),
    redirect: (context, state) => _handleRedirect(context, state, ref),
    routes: [
      // ... auth and shared routes
      ShellRoute(
        builder: (context, state, child) {
          final auth = ref.read(authStateProvider);
          final role = auth.user?.role ?? UserRole.customer;
          final destinations = RoleNav.forRole(role);
          final tabs = RoleScreens.forRole(role); // central map of tab screens
          return RoleScaffold(tabs: tabs, destinations: destinations);
        },
        routes: [
          // role tab leaf routes (orders, profile, etc.) with consistent path patterns
        ],
      ),
      // other non-tab routes (details, modals)
    ],
    errorBuilder: _buildErrorPage,
  );
});
```

- Implement `NavigationService.getNavigationItems(UserRole)` to return `destinations` from `RoleNav` for legacy compatibility.

- Preserve all existing route strings and role-based patterns in `AccessControlService` to avoid breaking RBAC.

### 3) Component Reusability
Consolidate duplicate custom widgets and create DS components with role-aware accents.

- Replace duplicates:
  - Consolidate `CustomButton` into `GEButton` under `design_system/widgets/ge_button.dart`, remove both `lib/src/features/shared/widgets/custom_button.dart` and `lib/src/shared/widgets/custom_button.dart`, and refactor callers.
  - Consolidate `CustomTextField` into `GETextField` using `InputDecorationTheme`. Remove secondary copies.

- Example `GEButton`:
```dart
// lib/src/design_system/widgets/ge_button.dart
enum GEButtonVariant { primary, secondary, tonal, outline, text, danger, success }

class GEButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final GEButtonVariant variant;
  final bool loading;
  final IconData? icon;
  final bool fullWidth;

  const GEButton({super.key, required this.label, this.onPressed, this.variant = GEButtonVariant.primary, this.loading = false, this.icon, this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : _content(theme);
    final button = switch (variant) {
      GEButtonVariant.primary => FilledButton(onPressed: loading ? null : onPressed, child: child),
      GEButtonVariant.secondary => FilledButton.tonal(onPressed: loading ? null : onPressed, child: child),
      GEButtonVariant.tonal => FilledButton.tonal(onPressed: loading ? null : onPressed, child: child),
      GEButtonVariant.outline => OutlinedButton(onPressed: loading ? null : onPressed, child: child),
      GEButtonVariant.text => TextButton(onPressed: loading ? null : onPressed, child: child),
      GEButtonVariant.danger => FilledButton(onPressed: loading ? null : onPressed, style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error), child: child),
      GEButtonVariant.success => FilledButton(onPressed: loading ? null : onPressed, style: FilledButton.styleFrom(backgroundColor: Colors.green), child: child),
    };
    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _content(ThemeData theme) => Row(mainAxisSize: MainAxisSize.min, children: [
    if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
    Text(label),
  ]);
}
```

- Example `GETextField` with consistent MD3 styling:
```dart
// lib/src/design_system/widgets/ge_text_field.dart
class GETextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final Widget? prefix;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final bool obscureText;
  const GETextField({super.key, this.controller, this.label, this.hint, this.prefix, this.suffix, this.keyboardType, this.obscureText = false});
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(labelText: label, hintText: hint, prefixIcon: prefix, suffixIcon: suffix),
    );
  }
}
```

- Shared visual components:
  - `GECard`, `GEListItem`, `GEStatTile`, `GEChip`, `GEEmptyState`, `GEErrorState`, `GELoadingOverlay`, `GEFormSection`, `GEFilterBar`, `RoleBadge`.
  - Replace ad-hoc cards and status chips in customer and driver widgets with DS equivalents.

### 4) Visual Identity
Unify typography, spacing, radii, and iconography; keep role accents.

- Color:
  - Base color scheme via `ColorScheme.fromSeed`.
  - Add `RoleTheme` extension colors per role accent (e.g., Customer teal, Vendor purple, Driver blue, Sales Agent amber, Admin red). Use accents for highlights only, not as primary UI background.
- Typography:
  - Pick a single font stack (e.g., Material defaults or `GoogleFonts.interTextTheme`). Ensure `TextTheme` variants align to MD3 naming (`titleLarge`, `bodyMedium`, etc.).
- Spacing:
  - Tokens: 4, 8, 12, 16, 24, 32.
  - Standard paddings for screens (16), cards (16), sections (24).
- Shape:
  - Radius tokens: 8 (controls), 12 (cards), 20 (sheets/dialogs).
- Iconography:
  - Material Symbols throughout; avoid mixing styles.
- Apply these in `AppTheme` component themes and DS widgets.

### 5) User Experience Flow
Harmonize states and interactions:

- Loading:
  - Use `GELoadingOverlay` or inline `GELoadingIndicator` consistently.
  - Skeletons where relevant (lists, dashboards).
- Error handling:
  - `GEErrorState` with retry callback; consistent messages and icon.
  - Errors surfaced via `SnackBar` using `SnackBarTheme` or `Banner` for persistent notices.
- Empty states:
  - `GEEmptyState` with icon, message, and primary CTA.
- Feedback:
  - Success `SnackBar`/`Banner` or lightweight confirmation sheets.
  - Consistent `Dialog` patterns via `GEConfirmDialog`.
- Forms:
  - Uniform validation messages; show on blur and submit; submit buttons disabled until valid.
  - Common `GEFormSection` + `GETextField`/`GESelect` ensures consistent margins and caption text.

### Refactoring plan (incremental, low risk)
- Phase A (foundation)
  - Add `lib/src/design_system` with tokens, `RoleTheme`, component themes, and DS widgets.
  - Swap `AppTheme` internals to new DS-backed theme while preserving `MaterialApp.router` usage in `main.dart`.
  - Implement `NavigationService.getNavigationItems(UserRole)` to return role nav items from `RoleNav`.
- Phase B (navigation)
  - Introduce `RoleScaffold` and start moving `SalesAgentDashboard` and `DriverDashboard` to use it. Replace ad-hoc `NavigationBar` setups.
  - Optionally wrap role areas in `ShellRoute`s for structural consistency without changing existing route strings.
- Phase C (components)
  - Replace duplicate `CustomButton` implementations with `GEButton` app-wide.
  - Replace `CustomTextField` copies with `GETextField` and rely on `InputDecorationTheme`.
  - Introduce `GEEmptyState`, `GEErrorState` in high-traffic screens (orders, wallet, dashboards).
- Phase D (role accents)
  - Apply role accent via `RoleTheme.forRole(role)` for top-level highlights (e.g., selected nav item color, role badge).
  - Keep base `ColorScheme` unchanged to avoid jarring visual changes; accents provide differentiation without fragmentation.
- Phase E (cleanup + lint)
  - Add a lint rule/docs: prefer DS widgets over raw `ElevatedButton`, `TextFormField`, etc.
  - Update docs: `docs/05-web-platform-documentation/README.md` and add `docs/design-system/DESIGN_SYSTEM_README.md`.
  - Update tests to render DS widgets and keep `MaterialApp` consistent.

### Specific edits to make
- Replace current `AppTheme` with DS-backed builder using `ColorScheme.fromSeed`, `InputDecorationTheme`, `NavigationBarTheme`, and include `RoleTheme` in `extensions`.
- Create `RoleScaffold` and refactor `SalesAgentDashboard` to use it (drop local `IndexedStack`/`NavigationBar` duplication).
- Implement `NavigationService.getNavigationItems(UserRole)` to return `RoleNav.forRole(role)`.
- Remove duplicate `CustomButton` and `CustomTextField`, migrate callers to `GEButton` and `GETextField`.
- Add shared empty/error/loading widgets and replace scattered implementations in customer/driver screens.
- Keep `AccessControlService` and route patterns untouched to preserve all role-based access behavior.

### Example: integrate Role accent safely
Use accent for role-specific surfaces (chips, active nav, badges) while keeping primary consistent:
```dart
// In RoleScaffold build method
final role = ref.watch(authStateProvider).user?.role ?? UserRole.customer;
final roleColor = Theme.of(context).extension<RoleTheme>()!.forRole(role);

return Theme(
  data: Theme.of(context).copyWith(
    navigationBarTheme: Theme.of(context).navigationBarTheme.copyWith(
      indicatorColor: roleColor.withOpacity(0.24),
      surfaceTintColor: roleColor,
    ),
    chipTheme: Theme.of(context).chipTheme.copyWith(
      selectedColor: roleColor.withOpacity(0.15),
      labelStyle: Theme.of(context).textTheme.labelLarge,
    ),
  ),
  child: Scaffold(...),
);
```

### Risks and mitigations
- Visual regressions: ship behind a feature flag per role; rollout role by role.
- Route behavior: keep `AccessControlService` maps and `redirect` logic intact.
- Widget churn: migrate the most used screens first; keep compatibility layer exporting `CustomButton` to `GEButton` temporarily.

### Quick wins to start now
- Implement DS tokens and swap `AppTheme` to `ColorScheme.fromSeed`.
- Add `RoleTheme` extension and wire it into theme extensions.
- Consolidate buttons and text fields with DS versions.
- Convert `SalesAgentDashboard` to `RoleScaffold` to showcase the pattern.

Summary
- Centralized MD3 design system with tokens and `ThemeExtension` for role accents.
- Standardized navigation via `RoleScaffold` (and optional `ShellRoute`) while preserving RBAC in `AccessControlService` and router redirects.
- Consolidated reusable components (`GEButton`, `GETextField`, cards, empty/error/loading states) and removal of duplicates.
- Unified visual identity: seed-based `ColorScheme`, consistent typography, spacing, radii, iconography; role accents applied consistently.
- Incremental refactor plan minimizing risk and preserving all existing functionality and permissions.

Status update:
- I analyzed theming in `AppTheme`, the router with RBAC, and role dashboards; identified duplicated shared widgets.
- I proposed a concrete DS module, navigation scaffolding, role accent strategy, component consolidation, and a step-by-step refactor plan with example code.

- Unifies theme via `ColorScheme.fromSeed` and adds `RoleTheme` extension in `AppTheme`.
- Introduces `RoleScaffold` and `RoleNav` for consistent nav across roles; integrates with existing `GoRouter` + RBAC.
- Consolidates buttons and text fields into DS widgets; adds standardized empty/error/loading components.