# Research: README Update for Flux (AirDash)

**Date**: 2025-12-08  
**Phase**: 0 - Outline & Research

## Research Tasks

### 1. README Best Practices for Flutter Projects

**Decision**: Follow GitHub's recommended README structure with Flutter-specific additions

**Rationale**: 
- GitHub's README guide establishes conventions users expect
- Flutter projects need specific sections for FVM, platform setup, and build instructions
- Open source projects benefit from badges, screenshots, and clear contribution paths

**Alternatives Considered**:
- Minimal README (title + description only) - rejected as insufficient for onboarding
- Wiki-based documentation - rejected as README should be self-contained for discoverability

### 2. Project Naming (Flux vs AirDash)

**Decision**: Use "Flux" as the official project name, with "AirDash" as a descriptive tagline

**Rationale**:
- pubspec.yaml uses `name: flux`
- "AirDash" describes the functionality (file transfer like AirDrop)
- Combined: "Flux - AirDash for Every Platform"

**Alternatives Considered**:
- AirDash only - rejected as pubspec already defines "flux"
- Flux only - less descriptive of functionality

### 3. README Section Order

**Decision**: Follow this structure (based on industry standards):

1. **Title + Tagline** - One-line description
2. **Badges** - Build status, Flutter version, license
3. **Overview** - What the app does (2-3 sentences)
4. **Features** - Bullet list of capabilities
5. **Supported Platforms** - Platform icons/badges
6. **Prerequisites** - What you need before starting
7. **Getting Started** - Installation steps
8. **Running the App** - How to launch
9. **Running Tests** - Test commands
10. **Project Structure** - Directory overview
11. **Technology Stack** - Key libraries
12. **Contributing** - How to contribute
13. **License** - License type with link

**Rationale**: 
- Most important info (what is it, how to use it) at top
- Technical details for contributors at bottom
- Matches reader expectations from popular Flutter projects

### 4. Platform-Specific Instructions

**Decision**: Use collapsible sections (`<details>`) for platform-specific setup

**Rationale**:
- Keeps README scannable without overwhelming with platform noise
- Users can expand only their relevant platform
- Reduces perceived complexity

**Alternatives Considered**:
- Separate SETUP.md per platform - rejected as fragments documentation
- All platforms inline - rejected as too long

### 5. Code Block Syntax

**Decision**: Use fenced code blocks with language hints

**Rationale**:
- GitHub renders syntax highlighting
- Copy button appears on code blocks
- Clear distinction between commands and output

**Example format**:
```bash
# Clone repository
git clone https://github.com/tnvinh2711/AirDash.git
cd AirDash

# Install dependencies
fvm install
fvm flutter pub get

# Run the app
fvm flutter run
```

## Resolved Clarifications

| Item | Resolution |
|------|------------|
| Project name | "Flux" with "AirDash" tagline |
| Section order | 13 sections as defined above |
| Platform instructions | Collapsible `<details>` sections |
| Flutter version | Reference FVM, specify SDK ^3.8.0 |
| License | MIT (per existing LICENSE file) |

## Key Findings for Implementation

1. **Keep it scannable**: Use headers, bullets, and code blocks liberally
2. **Lead with value**: Features and overview before setup complexity
3. **Test the 15-minute promise**: Setup instructions must be copy-paste ready
4. **Link don't duplicate**: Reference LICENSE, CONTRIBUTING.md rather than inline
5. **Include visuals**: Consider adding app screenshots (future enhancement)

