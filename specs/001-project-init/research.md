# Research: Project Initialization with FVM and Folder Structure

**Feature**: 001-project-init
**Date**: 2025-12-05

## Research Tasks

### 1. FVM Stable Channel Configuration

**Decision**: Use `fvm use stable` to configure Flutter version

**Rationale**:
- FVM's `stable` channel reference automatically tracks Flutter's stable releases
- Team members get consistent versions via `.fvm/fvm_config.json` committed to repo
- Avoids manual version bumps while maintaining reproducibility

**Alternatives Considered**:
- Pinned version (e.g., `3.24.0`): Rejected per clarification - user prefers auto-updates
- Beta/dev channels: Rejected - stability required for production app

**Implementation**:
```bash
fvm install stable
fvm use stable
```

---

### 2. Very Good Analysis Setup

**Decision**: Use `very_good_analysis` package for linting rules

**Rationale**:
- Industry-standard strict linting for Flutter/Dart projects
- Maintained by Very Good Ventures (trusted Flutter consultancy)
- Includes 100+ lint rules covering style, correctness, and best practices
- Aligns with constitution's "Zero lints" quality gate

**Alternatives Considered**:
- `lints` package: Less strict, fewer rules
- `flutter_lints`: Default Flutter lints, not strict enough
- Custom `analysis_options.yaml`: Maintenance burden, inconsistent

**Implementation**:
```yaml
# analysis_options.yaml
include: package:very_good_analysis/analysis_options.yaml
```

---

### 3. Riverpod Generator Dependencies

**Decision**: Include full Riverpod code generation stack

**Rationale**:
- `riverpod_annotation` + `riverpod_generator` enables annotation-based providers
- Reduces boilerplate and enforces consistency
- Required by constitution's "Annotation-based" Riverpod mandate

**Dependencies**:
```yaml
dependencies:
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0

dev_dependencies:
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.0
```

---

### 4. Freezed Setup for Immutable Classes

**Decision**: Include freezed with JSON serialization support

**Rationale**:
- Constitution mandates freezed for all data classes and state objects
- Generates `copyWith`, `==`, `hashCode`, `toString` automatically
- `freezed_annotation` is runtime, `freezed` is dev-only (code gen)

**Dependencies**:
```yaml
dependencies:
  freezed_annotation: ^2.4.0

dev_dependencies:
  freezed: ^2.5.0
  build_runner: ^2.4.0  # shared with riverpod_generator
```

---

### 5. Platform-Specific Initialization

**Decision**: Enable all desktop platforms during `flutter create`

**Rationale**:
- Constitution requires Universal Access across all 5 platforms
- Easier to enable at creation than retrofit later
- Platform directories (`macos/`, `windows/`, `linux/`) needed for builds

**Implementation**:
```bash
flutter create --platforms=android,ios,macos,windows,linux flux
```

Or if project exists:
```bash
flutter create --platforms=macos,windows,linux .
```

---

### 6. Folder Structure Initialization

**Decision**: Create empty placeholder structure with `.gitkeep` files

**Rationale**:
- Git doesn't track empty directories
- `.gitkeep` is convention for preserving directory structure
- Allows immediate feature development in correct locations

**Structure**:
```
lib/src/core/.gitkeep
lib/src/features/.gitkeep
```

---

## Summary

All technical decisions resolved. No NEEDS CLARIFICATION items remain.

| Area | Decision | Ready |
|------|----------|-------|
| FVM Configuration | `stable` channel | ✅ |
| Linting | `very_good_analysis` | ✅ |
| State Management | Riverpod + Generator | ✅ |
| Immutability | Freezed + Annotation | ✅ |
| Platform Support | All 5 enabled | ✅ |
| Folder Structure | `.gitkeep` placeholders | ✅ |

