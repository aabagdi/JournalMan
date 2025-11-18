# Project Context: JournalMan

## Project Overview

- **Version**: ContextKit 0.1.0
- **Setup Date**: 2025-10-01
- **Components**: 1 component (iOS app)
- **Workspace**: None (standalone project)
- **Primary Tech Stack**: Swift, SwiftUI, Composable Architecture
- **Development Guidelines**: Swift.md, SwiftUI.md

## Component Architecture

**Project Structure**:

```
📁 JournalMan
└── 📱 JournalMan (iOS App) - Voice journaling with ML emotion/topic classification - Swift/SwiftUI/TCA - ./JournalMan/
```

**Component Summary**:
- **1 Swift component** - iOS app using SwiftUI and Composable Architecture
- **Dependencies**: 16 Swift Package Manager dependencies (Point-Free ecosystem + ML models)

---

## Component Details

### JournalMan - iOS App

**Location**: `./JournalMan/`
**Purpose**: Voice-based journaling application with ML-powered emotion and topic classification, calendar-based entry viewing
**Tech Stack**: Swift, SwiftUI, Composable Architecture, Core ML, Speech Recognition, SQLite

**File Structure**:
```
JournalMan/
├── Assets.xcassets/          # App icons and color assets (ManPurple theme)
├── *.swift                    # Source files (features, models, clients)
├── EmotionClassifier.mlmodel  # Core ML emotion classification model
└── TopicClassifier.mlmodel    # Core ML topic classification model
```

**Key Features**:
- Audio recording with speech transcription (SpeechRecognizerClient)
- ML-based emotion classification (EmotionClassifierClient)
- ML-based topic classification (TopicClassifierClient)
- Calendar-based journal entry viewing (CalendarViewFeature)
- SQLite database for persistent storage (SQLiteData)
- Composable Architecture for state management

**Dependencies** (from Package.resolved):
- **ComposableArchitecture** (1.22.3) - State management and app architecture
- **SQLiteData** (1.0.0) - Database persistence layer
- **GRDB.swift** (7.7.1) - SQLite toolkit (SQLiteData dependency)
- **swift-composable-architecture** ecosystem:
  - swift-dependencies (1.10.0) - Dependency injection
  - swift-case-paths (1.7.2) - Key path utilities
  - swift-identified-collections (1.1.1) - Collection management
  - swift-navigation (2.5.1) - Navigation state management
  - swift-perception (2.0.8) - Observable state
  - swift-sharing (2.7.4) - Shared state
  - swift-custom-dump (1.3.3) - Debug descriptions
  - swift-clocks (1.0.6) - Time control
  - combine-schedulers (1.0.3) - Scheduler control
  - swift-concurrency-extras (1.3.2) - Concurrency utilities
  - xctest-dynamic-overlay (1.6.1) - Testing support
  - swift-snapshot-testing (1.18.7) - Snapshot tests
- **swift-syntax** (602.0.0) - Swift parsing (TCA macros)

**Development Commands**:
```bash
# Note: xcodebuild requires full Xcode installation (not available with Command Line Tools only)
# Build commands require Xcode.app to be installed and selected via xcode-select

# Open project in Xcode
open JournalMan.xcodeproj

# Alternative: Build using swift (for package-based builds if applicable)
# Note: This is an Xcode project, not a Swift Package, so xcodebuild is required
```

**Code Style** (detected):
- Indentation: 2 spaces (detected from source files)
- No existing formatter configuration found
- Swift standard naming conventions used
- Composable Architecture patterns followed (Store, State, Action, Reducer)

**Framework Usage**:
- SwiftUI for UI layer
- Composable Architecture for state management
- Core ML for machine learning models
- Speech framework for transcription
- AVFoundation for audio recording (inferred from AudioRecorderClient)
- SQLiteData for database persistence

---

## Development Environment

**Requirements**:
- Xcode 26.0+ (Swift 6.0+)
- macOS for iOS development
- iOS Simulator or physical device for testing
- Microphone access for audio recording
- Speech Recognition permissions

**Build Tools**:
- Xcode build system (requires full Xcode installation)
- Swift Package Manager (integrated with Xcode)
- Command Line Tools alone are insufficient (xcodebuild unavailable)

**Formatters** (configured):
- `.swift-format` - Swift formatter configuration (installed during setup)
- `.swiftformat` - SwiftFormat configuration (installed during setup)
- Auto-formatting enabled via PostToolUse hook

## Development Guidelines

**Applied Guidelines**: Swift.md, SwiftUI.md
- Guidelines automatically loaded by all planning commands (`/ctxk:plan:*`)
- Implementation commands apply guideline standards during development
- Quality agents validate against guideline requirements

**Guidelines Integration**:
- All planning phases reference active guidelines for architecture decisions
- Implementation phases apply guideline patterns and API preferences
- Migration only updates guidelines that exist in project

**Project-Specific Standards**:
- Composable Architecture patterns for features
- Dependency injection using @Dependency macro
- Client-based abstraction for side effects
- Feature-based file organization

## Constitutional Principles

**Core Principles**:
- ✅ Accessibility-first design (UI supports all assistive technologies)
- ✅ Privacy by design (minimal data collection, explicit consent)
- ✅ Localizability from day one (externalized strings, cultural adaptation)
- ✅ Code maintainability (readable, testable, documented code)
- ✅ Platform-appropriate UX (native conventions, platform guidelines)

**Workspace Inheritance**: None - using global defaults

**Privacy Considerations** (app-specific):
- Voice recordings stored locally only
- Speech transcription via Apple's on-device APIs
- ML classification runs on-device (Core ML models)
- No cloud sync or external data transmission
- Microphone and speech recognition permissions required

## ContextKit Workflow

**Systematic Feature Development**:
- `/ctxk:plan:1-spec` - Create business requirements specification (prompts interactively)
- `/ctxk:plan:2-research-tech` - Define technical research, architecture and implementation approach
- `/ctxk:plan:3-steps` - Break down into executable implementation tasks

**Development Execution**:
- `/ctxk:impl:start-working` - Continue development within feature branch (requires completed planning phases)
- `/ctxk:impl:commit-changes` - Auto-format code and commit with intelligent messages

**Quality Assurance**: Automated agents validate code quality during development
**Project Management**: Open project in Xcode for development and testing

## Development Automation

**Quality Agents Available**:
- `build-project` - Execute builds with constitutional compliance validation (requires Xcode)
- `check-accessibility` - VoiceOver, contrast, keyboard navigation validation
- `check-localization` - String Catalog and cultural adaptation validation
- `check-error-handling` - ErrorKit patterns and typed throws validation
- `check-modern-code` - API modernization (Date.now, Duration, async/await)
- `check-code-debt` - Technical debt cleanup and AI artifact removal

**Known Limitations**:
- xcodebuild commands unavailable (requires full Xcode installation, not just Command Line Tools)
- CI/CD pipelines need Xcode.app installed on build machines
- Use Xcode GUI for building, testing, and running until xcodebuild is available

## Configuration Hierarchy

**Inheritance**: None → **This Project**

**This Project Inherits From**:
- **Workspace**: None (standalone project)
- **Project**: Component-specific configurations documented above

**Override Precedence**: Project settings are authoritative (no workspace to inherit from)

---
*Generated by ContextKit with comprehensive component analysis. Manual edits preserved during updates.*