# 🏛️ Architecture & Guidelines

This folder contains documents that describe the application's architecture, coding standards, and major architectural decisions.

## Documents in this category:

### Development Guidelines
- **`flutter_backend_guidelines.md`** - The primary set of development standards and best practices for the project
- **`FEATURE_BASED_ARCHITECTURE_GUIDE.md`** - Explains the new, modular feature-based project structure

### Architecture Evolution
- **`FLUTTER_REORGANIZATION_COMPLETE.md`** - Summary of the successful codebase refactoring to a feature-based architecture
- **`PROJECT_SUMMARY_AND_NEXT_STEPS.md`** - Summary of architectural improvements and future development direction
- **`flutter_cleanup_plan.md`** - Plan detailing the architectural decision to remove all Firebase dependencies for a pure Supabase setup

### Migration Guides
- **`SUPABASE_AUTH_MIGRATION_GUIDE.md`** - Guide for the critical architectural migration from Firebase Auth to Supabase Auth

## Purpose

These documents provide:
- Coding standards and best practices to maintain code quality
- Architectural decisions and their rationale
- Guidelines for consistent development across the team
- Migration strategies for major architectural changes

## Key Architectural Decisions

1. **Feature-Based Architecture**: Modular structure organizing code by features rather than technical layers
2. **Pure Supabase Backend**: Migration from Firebase+Supabase hybrid to pure Supabase architecture
3. **Flutter Development Standards**: Comprehensive guidelines for Flutter/Dart development

## Usage

Developers should familiarize themselves with the guidelines before contributing to the codebase. The migration guides are essential for understanding the evolution from the original architecture to the current implementation.
