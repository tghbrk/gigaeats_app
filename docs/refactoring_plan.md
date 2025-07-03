# Implementation Plan: Feature-First Architecture Refactoring

**Document Version:** 1.0
**Date:** 2025-06-26

## 1. Introduction & Goal

This document outlines the step-by-step plan to refactor our Flutter project's structure. The primary goal is to transition from a "role-as-a-feature" model to a true **feature-first architecture**.

This change will improve scalability, reduce code duplication, and create a clearer separation of concerns, making the codebase easier to maintain and scale.

The core principle is to organize the code around the application's main functionalities (e.g., `orders`, `menu`, `payments`) and handle user role variations (`customer`, `driver`, `vendor`, etc.) within the presentation layer of each feature.

## 2. Proposed Project Structure

The target structure will be as follows:

```
lib/
└── src/
    ├── core/
    │   ├── api/
    │   ├── routing/
    │   ├── theme/
    │   ├── utils/
    │   └── widgets/
    │
    ├── features/
    │   ├── auth/
    │   ├── user_management/
    │   │   ├── data/
    │   │   ├── domain/       // User models, Role enum
    │   │   └── presentation/ // Profile pages, user-specific widgets
    │   │
    │   ├── orders/
    │   │   ├── data/
    │   │   ├── domain/
    │   │   └── presentation/
    │   │       ├── cubit/
    │   │       ├── screens/
    │   │       │   ├── admin/
    │   │       │   ├── customer/
    │   │       │   └── driver/
    │   │       └── widgets/
    │   │
    │   └── ... // Other core features
    │
    └── main.dart
```

## 3. Migration Phases

The migration will be executed in a series of focused phases to minimize disruption and allow for continuous testing.

### Phase 1: Preparation & Scaffolding

*   **Task 1.1: Team Briefing:** Hold a meeting to walk the development team through this plan. Ensure everyone understands the goals and the new structure.
*   **Task 1.2: Create New Directories:**
    *   Create `lib/src`.
    *   Create `lib/src/core` with `widgets` and `utils` subdirectories.
    *   Move `lib/features` to `lib/src/features`.
    *   Create `lib/src/features/user_management` with `data`, `domain`, and `presentation` subdirectories.

### Phase 2: Centralize Shared & User-Related Code

*   **Task 2.1: Relocate Generic Widgets:**
    *   Move `search_bar_widget.dart` to `lib/src/core/widgets/`.
    *   Update all import paths.
*   **Task 2.2: Consolidate User-Management Code:**
    *   Move `customer_card.dart` and `customer_selector.dart` to `lib/src/features/user_management/presentation/widgets/`.
    *   Move `vendor_utils.dart` to `lib/src/features/user_management/application/`.
    *   Update all import paths.
*   **Task 2.3: Verify:** Run the full test suite to confirm that no regressions were introduced by the file moves and import changes.

### Phase 3: Pilot Refactoring - The `orders` Feature

*   **Task 3.1: Restructure Screens:**
    *   In `lib/src/features/orders/presentation/screens/`, create `customer/` and `vendor/` subdirectories.
    *   Move the relevant screen files into these new directories as previously detailed.
*   **Task 3.2: Update Routing:**
    *   Modify the application's router to reflect the new paths for the order screens.
*   **Task 3.3: Test:** Perform a thorough manual test of the entire order flow for both `customer` and `vendor` roles.

### Phase 4: Full-Scale Refactoring - Core Features

**Status:** ✅ Phase 3 Complete - Orders feature successfully refactored
**Current Phase:** Phase 4 Implementation

#### 4.1 Detailed Task Breakdown

**Subtask 4.1: Menu Feature Refactoring**
- Create role-specific screen directories in `lib/src/features/menu/presentation/screens/`
- Migrate menu-related screens from role-based directories
- Update routing configuration for new menu screen paths
- Test menu functionality on Android emulator (emulator-5554)

**Subtask 4.2: Payments Feature Refactoring**
- Create role-specific screen directories in `lib/src/features/payments/presentation/screens/`
- Migrate payment-related screens from role-based directories
- Update Stripe integration paths and dependencies
- Test payment flows on Android emulator

**Subtask 4.3: Marketplace Wallet Feature Refactoring**
- Create role-specific screen directories in `lib/src/features/marketplace_wallet/presentation/screens/`
- Migrate wallet-related screens from role-based directories
- Update wallet service dependencies and routing
- Test wallet functionality on Android emulator

**Subtask 4.4: User Domain Migration**
- Move all user-related data models (`Customer`, `Driver`, `Vendor`, etc.) to `lib/src/features/user_management/domain/`
- Update all repositories and services to import models from new location
- Update all import paths across the codebase
- Verify no broken imports remain

**Subtask 4.5: Role-Based Feature Consolidation**
- Migrate remaining UI components from `customers/`, `drivers/`, `vendors/`, `sales_agent/`, `admin/` directories
- Consolidate shared widgets into appropriate feature directories
- Update all import paths and dependencies
- Remove empty role-based directories

#### 4.2 Feature Prioritization (Dependency Order)

1. **High Priority - Core Business Logic:**
   - Menu (foundational for orders)
   - Payments (critical for transactions)
   - User Management Domain Migration (affects all features)

2. **Medium Priority - User Experience:**
   - Marketplace Wallet (customer-facing)
   - Notifications (cross-cutting concern)

3. **Low Priority - Administrative:**
   - Admin features (internal tools)
   - Commission tracking (reporting)

#### 4.3 Migration Strategy

**Step 1: Pre-Migration Analysis**
- Analyze current role-based directories for screen distribution
- Identify shared components that need consolidation
- Map import dependencies between features

**Step 2: Feature-by-Feature Migration**
- Create role-specific subdirectories in target features
- Move screens maintaining original functionality
- Update routing configuration incrementally
- Test each feature after migration

**Step 3: Domain Model Consolidation**
- Move user models to centralized location
- Update import paths using IDE refactoring tools
- Verify all references are updated correctly

**Step 4: Import Path Cleanup**
- Run comprehensive import path audit
- Fix any remaining broken imports
- Optimize import statements for consistency

#### 4.4 Import Path Management Plan

**Automated Approach:**
- Use IDE refactoring tools for file moves when possible
- Leverage "Find and Replace" for bulk import updates
- Use Flutter analyzer to identify broken imports

**Manual Verification:**
- Review critical import paths manually
- Test import resolution after each subtask
- Maintain import path consistency standards

**Import Path Patterns:**
```dart
// Old pattern (to be replaced)
import '../../../customers/presentation/screens/customer_dashboard.dart';

// New pattern (target)
import '../../features/orders/presentation/screens/customer/customer_orders_screen.dart';
```

#### 4.5 Testing Checkpoints

**After Each Subtask:**
- Run `flutter analyze` to check for errors
- Test on Android emulator (emulator-5554)
- Verify core functionality preserved
- Check for import-related issues

**Major Testing Points:**
1. After Menu feature refactoring
2. After Payments feature refactoring
3. After User Domain migration
4. After Role-based consolidation
5. Final comprehensive testing

#### 4.6 Risk Mitigation

**Potential Issues & Solutions:**

**Risk: Broken Import Paths**
- Mitigation: Use IDE refactoring tools, incremental testing
- Fallback: Manual import path audit and correction

**Risk: Routing Configuration Errors**
- Mitigation: Update routing incrementally, test after each change
- Fallback: Maintain routing backup, rollback if needed

**Risk: Lost Functionality During Migration**
- Mitigation: Preserve original file structure until migration complete
- Fallback: Git version control for easy rollback

**Risk: Complex Dependency Chains**
- Mitigation: Map dependencies before migration, update systematically
- Fallback: Gradual migration with dependency tracking

#### 4.7 Success Criteria

**Quantitative Metrics:**
- Reduce Flutter analyzer errors by 80%
- Maintain 100% functionality preservation
- Achieve <5 broken import paths
- Complete migration within 5 subtasks

**Qualitative Metrics:**
- Clean feature-first directory structure
- Consistent import path patterns
- Improved code organization and maintainability
- Successful Android emulator testing for all features

**Completion Criteria:**
- All core features follow feature-first pattern
- All user domain models centralized
- All role-based directories consolidated
- All import paths updated and functional
- Full regression testing passed

### Phase 5: Cleanup & Finalization

*   **Task 5.1: Delete Old Directories:** Once all code has been migrated, delete the now-empty role-based feature folders (`customers`, `drivers`, etc.).
*   **Task 5.2: Final Regression Test:** Conduct a full end-to-end regression test of the application across all user roles to ensure stability.
*   **Task 5.3: Documentation Update:** Update any other relevant project documentation to reflect the new structure.

## 4. Risks & Mitigation

*   **Risk:** Broken imports and navigation.
    *   **Mitigation:** Use the IDE's refactoring tools to move files, as this often updates imports automatically. Perform thorough testing after each phase.
*   **Risk:** Team confusion about the new structure.
    *   **Mitigation:** The initial team briefing (Task 1.1) is crucial. Keep this document accessible to everyone.
