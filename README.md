# Flutter Architecture Showcase

A production-oriented Flutter project demonstrating scalable application architecture, offline-first data management, maintainable code, and software engineering best practices.

The goal is to demonstrate not only how to build a Flutter application, but also how to make architectural decisions, manage application state, handle unreliable networks, and write testable, maintainable code.

> **Project status:** 🚧 In development

## 🎯 Project Goals

- Apply feature-first Clean Architecture to a real application.
- Follow SOLID principles and maintain clear separation of concerns.
- Apply Command Query Responsibility Segregation (CQRS).
- Implement predictable state management using BLoC/Cubit.
- Build an offline-first application with local persistence.
- Implement synchronization between local storage and a mock remote data source.
- Handle network failures, retries, and synchronization states.
- Write unit, widget, and integration tests.
- Automate code quality checks using GitHub Actions.

## 🛠️ Technology Stack

| Technology | Purpose | Status |
| --- | --- | --- |
| Flutter | Cross-platform application development | Implemented |
| Dart | Programming language | Implemented |
| BLoC / Cubit | Presentation-layer state management | Implemented |
| Clean Architecture | Separation of business logic and infrastructure | Implemented |
| CQRS | Separation of commands and queries | Implemented |
| Drift / SQLite | Local persistence | Implemented |
| Dio | HTTP client and network configuration | Configured |
| go_router | Declarative navigation | Planned |
| get_it + injectable | Dependency injection | Implemented |
| flutter_test | Automated testing | Implemented |
| mocktail | Mocking dependencies in tests | Implemented |
| GitHub Actions | Continuous integration | Implemented |
| connectivity_plus | Network connectivity awareness | Planned |

*The status column reflects the current implementation, not merely the intended technology choices.*

## 🏗️ Architecture

The application uses **feature-first Clean Architecture with CQRS**.

Each feature owns its presentation, domain, application, and data layers. Within the application layer, CQRS separates operations that modify application state from operations that retrieve information.

### Current high-level structure

```text
lib/
├── app/
├── core/
│   ├── database/
│   ├── network/
│   └── sync/
├── features/
│   └── products/
│       ├── data/
│       │   ├── datasources/
│       │   ├── models/
│       │   └── repositories/
│       ├── domain/
│       │   ├── entities/
│       │   ├── repositories/
│       ├── application/
│       │   ├── commands/
│       │   └── queries/
│       └── presentation/
│           ├── cubit/
│           ├── screens/
│           └── widgets/
└── main.dart
```

The structure may evolve as implementation requirements become clearer. Commands, queries, and handlers are introduced where they provide meaningful separation rather than adding unnecessary abstractions.

### Architectural Principles

- **Feature ownership:** Related presentation, business logic, and data-access code is organized within the same feature.
- **Layered responsibilities:** Presentation coordinates UI behavior, domain defines business contracts, application handles commands and queries, and data handles persistence and external services.
- **CQRS:** Commands represent state-changing operations; queries retrieve data without changing application state.
- **Dependency inversion:** Domain contracts do not depend directly on infrastructure implementations.
- **Repository pattern:** Data access is abstracted behind repository contracts.
- **Single responsibility:** Application operations have focused responsibilities.
- **Dependency injection:** Dependencies are provided rather than constructed throughout the application.

## 📦 Application Features

The project uses a Product Management application to demonstrate the architecture.

### Implemented Features

- [x] Product listing and details
- [x] Create, update, and delete products
- [x] Local database persistence using Drift
- [x] Feature-first Clean Architecture
- [x] CQRS command and query separation
- [x] Dependency injection
- [x] Product repository and data-source implementation
- [x] Offline synchronization infrastructure
- [x] Synchronization queue with operation coalescing
- [x] Local-first product persistence
- [x] Mock remote product data source
- [x] Product synchronization handler
- [x] Retry handling and synchronization coordination
- [x] Product and synchronization presentation states
- [x] Unit and widget tests for implemented components
- [x] Automated CI checks

### Upcoming Features

- [ ] Declarative navigation using go_router
- [ ] Product search and filtering
- [ ] Persistent sync run history and reporting
- [ ] Category-level synchronization results
- [ ] Accurate partial synchronization failure reporting
- [ ] Integration tests for critical application flows
- [ ] Network connectivity awareness
- [ ] Additional application features

Features will be marked complete only after implementation and verification.

## 🔄 Offline-First Strategy

The application is designed to remain useful when network connectivity is unavailable.

Local persistence supports offline access, while synchronization infrastructure tracks operations that need to be propagated to the remote data source.

The initial remote implementation uses a mock data source. This allows synchronization behavior to be developed and tested without depending on a production backend.

The intended data flow is:

1. The UI dispatches an action to the feature's presentation layer.
2. BLoC/Cubit invokes the appropriate command or query.
3. Application handlers execute the requested operation.
4. Domain repository contracts define the required data operations.
5. Data-layer implementations persist changes locally.
6. Changes requiring remote synchronization are tracked in the synchronization queue.
7. The synchronization coordinator manages pulling and pushing operations.
8. Failed operations remain eligible for retry according to the retry policy.
9. The UI communicates relevant loading, error, and synchronization states.

The synchronization infrastructure is being developed incrementally, including operation tracking, retry handling, and category-level reporting.

## 🧪 Code Quality and Testing

The project uses automated verification to maintain code quality:

- Static analysis with `flutter analyze`
- Consistent Dart formatting
- Unit tests for application and domain logic
- Repository tests for data access and synchronization
- Widget tests for presentation behavior
- Integration tests planned for critical application flows
- GitHub Actions for automated verification

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.47.7 on the stable channel
- Dart SDK 3.13.5
- Git
- Android Studio or another supported development environment

The project targets Flutter 3.47.7 and Dart 3.13.5. Dependency versions and SDK constraints are maintained in `pubspec.yaml`.

## 📚 Engineering Decisions

This repository documents significant technical decisions, including:

- Why feature-first Clean Architecture was selected
- How CQRS separates commands from queries
- How feature boundaries and layer responsibilities are defined
- When to introduce abstractions and when to avoid them
- BLoC/Cubit trade-offs
- Local database and repository design
- Offline synchronization and failure recovery
- Testing strategy and dependency management

The objective is to demonstrate the reasoning behind the implementation, not merely the use of popular packages.

## 👨‍💻 About This Project

This repository is an ongoing Flutter engineering showcase focused on architecture, maintainability, reliability, and practical software engineering principles.

As development progresses, this README will be updated with implementation details, architectural diagrams, testing information, and verified examples.