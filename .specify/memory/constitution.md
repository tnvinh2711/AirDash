<!--
Sync Impact Report:
- Version change: 1.1.0 → 1.2.0 (Architecture expansion - Riverpod Architecture)
- Modified principles:
  - "Feature-First Architecture" → "Riverpod Architecture (Pragmatic, Feature-First)"
- Added sections:
  - Layering Strategy (Pragmatic)
  - Key Architectural Rules
- Removed sections: None
- Templates requiring updates:
  - ✅ plan-template.md - no changes required (uses generic structure options)
  - ✅ spec-template.md - no changes required (technology-agnostic)
  - ✅ tasks-template.md - no changes required (uses path conventions section)
- Follow-up TODOs: None
-->

# FLUX Constitution

## Core Principles

### I. Privacy First
No data is stored on intermediate servers; all transfers are peer-to-peer. The application MUST operate without requiring external cloud services or data intermediaries. User files and metadata remain exclusively on user devices during transfer operations.

### II. Offline First
Fully functional without an Internet connection (LAN/Hotspot only). The application MUST provide complete functionality using local network discovery and direct device-to-device communication. Internet connectivity is optional and not required for core operations.

### III. Universal Access (NON-NEGOTIABLE)
Seamless experience across Mobile (Android, iOS) and Desktop (Windows, macOS, Linux) from a single Flutter codebase. UI MUST adapt responsively to different screen sizes and input methods. Navigation patterns MUST be platform-appropriate (NavigationBar for mobile, NavigationRail for desktop).

### IV. High Performance
60fps+ UI rendering and maximized data transfer speeds using raw sockets/HTTP. The application MUST maintain smooth animations and responsive interactions across all supported platforms. File transfer speeds MUST be optimized for the underlying network capabilities.

### V. Test-First Development
90% test coverage MUST be achieved and maintained. Unit tests are required for all Domain logic, Repositories, and Riverpod Notifiers. Widget tests are required for critical UI components. All tests MUST pass before code integration.

## Technology Stack (MANDATORY)

All generated code MUST utilize the following libraries and tools. Unauthorized substitutions are prohibited.

### Core Framework & Language
- **SDK Management**: FVM (Flutter Version Management) is required
- **Framework**: Flutter (Latest Stable Channel via FVM)
- **Language**: Dart 3.0+ (Full Sound Null Safety)

### State Management & Architecture
- **State Management**: `flutter_riverpod` with `riverpod_generator` (Annotation-based)
- **Immutability**: `freezed` & `freezed_annotation` for all data classes and state objects
- **Service Locator**: Riverpod Providers (no GetIt unless strictly necessary)

### Data & Storage
- **Local Database**: `drift` (SQLite abstraction) for history and persistent settings
- **Preferences**: `shared_preferences` or drift key-value store

### UI & Theming
- **Design System**: Material 3 (`useMaterial3: true`)
- **Theming Engine**: `flex_color_scheme` for robust dynamic coloring and theme modes
- **Responsive Utils**: Standard Flutter `LayoutBuilder` and `Constraints`

### Navigation & Networking
- **Router**: `go_router` for handling deep links and complex navigation stacks
- **Discovery**: `bonsoir` for device discovery
- **Transfer**: `shelf` (HTTP Server receiver) and `chopper` (HTTP Client sender)

## Architecture and Project Structure

The project follows the **Riverpod Architecture** (Pragmatic, Feature-First). We prioritize simplicity and development speed over strict academic layering, while maintaining testability.

### Layering Strategy (Pragmatic)

- **Presentation Layer**: Widgets and UI logic
- **Application Layer (Logic)**: Riverpod Notifiers (`AsyncNotifier`) containing business logic and state management. This is the primary target for Unit Tests.
- **Data Layer**: Repositories (Data access) and Data Sources (API/DB clients). No abstract interfaces required for Repositories unless necessary for multiple implementations.

### Folder Structure

```
lib/
├── src/
│   ├── core/               # Shared logic, common widgets, extensions
│   └── features/
│       └── feature_name/
│           ├── data/           # Repositories, DTOs, Data Sources (Drift/Dio)
│           ├── application/    # Service classes, Logic Providers (The "Brain")
│           ├── presentation/   # Widgets, Screens, UI Controllers
│           └── domain/         # (Optional) Simple Data Models / Entities (Freezed classes)
├── app.dart                # Root widget
└── main.dart               # Entry point
```

### Key Architectural Rules

- **No "Use Cases" or "Interactors"**: Business logic MUST reside in the Application Layer (Notifier/Service)
- **Direct Repository Usage**: The Application layer MUST call Repositories directly
- **Testing Strategy**:
  - Unit Test the "Application Layer" (Notifiers) and "Data Layer" (Repositories)
  - Integration Test critical flows
  - Widget Test complex UI components

## UI/UX and Responsive Design Guidelines

The application MUST strictly adhere to **Responsive Design** principles to support Android, iOS, Windows, macOS, and Linux from a single codebase.

### Adaptive Navigation
- **Mobile/Narrow Screens (< 600dp)**: Use `NavigationBar` (Bottom Tab)
- **Desktop/Wide Screens (≥ 600dp)**: Use `NavigationRail` (Left-side vertical navigation)
- The transition between these modes MUST be fluid upon window resizing

### Desktop Specifics
- **Window Management**: App MUST handle window resizing gracefully with minimum window size constraints
- **Input Handling**: Support hover states (`MouseRegion`) for interactive elements
- **Keyboard Shortcuts**: Implement shortcuts for common actions (Ctrl+V to paste, Esc to cancel)
- **Dialogs**: Use wide, modal dialogs appropriate for desktop contexts

### Material 3 Implementation
- **Cards**: Use Elevated Cards or Filled Cards with proper surface tint
- **Color Scheme**: MUST support System Light/Dark mode switching automatically on all platforms

## Governance

This constitution supersedes all other development practices and guidelines. All code contributions MUST comply with the specified technology stack and architectural principles.

### Amendment Process
- Constitution changes require documentation of rationale and impact assessment
- Version increments follow semantic versioning (MAJOR.MINOR.PATCH)
- All team members must be notified of constitutional amendments

### Compliance Requirements
- All PRs/reviews MUST verify compliance with technology stack requirements
- Code complexity MUST be justified against simplicity principles
- AI Agent MUST follow specified rules and constraints
- Build integrity MUST be maintained across all supported platforms

### Quality Gates
- Zero lints: `flutter analyze` MUST pass without warnings
- Code formatting: `dart format` MUST be applied to all code
- Test coverage: Minimum 90% line coverage required
- Platform compatibility: MUST build successfully on at least one mobile AND one desktop platform

**Version**: 1.2.0 | **Ratified**: 2025-12-05 | **Last Amended**: 2025-12-05
