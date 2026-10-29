# Flutter Architecture Showcase

A production-oriented Flutter project demonstrating scalable application architecture, offline-first data management, maintainable code, and software engineering best practices.

The goal is to demonstrate not only how to build a Flutter application, but also how to make architectural decisions, manage application state, handle unreliable networks, and write testable, maintainable code.

> **Project status:** 🚧 In development

## 🎯 Project Goals

- Apply feature-first Clean Architecture to a real application.
- Follow SOLID principles and maintain clear separation of concerns.
- Apply Command Query Responsibility Segregation (CQRS) to separate state-changing operations from data retrieval.
- Implement predictable state management using BLoC/Cubit.
- Build an offline-first application with local persistence.
- Implement and test synchronization between local storage and a mock REST API.
- Handle network failures, retries, and synchronization states.
- Write unit, widget, and integration tests.
- Automate code quality checks using GitHub Actions.

## 🛠️ Technology Stack

| Technology | Purpose |
| --- | --- |
| Flutter | Cross-platform application development |
| Dart | Programming language |
| BLoC / Cubit | Presentation-layer state management |
| Clean Architecture | Separation of business logic and infrastructure |
| CQRS | Separation of commands and queries |
| Drift / SQLite | Local persistence |
| Dio | HTTP client for mock REST API integration |
| go_router | Declarative navigation |
| get_it + injectable | Dependency injection |
| connectivity_plus | Network connectivity awareness |
| flutter_test | Automated testing |
| mocktail | Mocking dependencies in tests |
| GitHub Actions | Continuous integration |

*The stack represents the planned implementation. Dependencies and their usage will be documented as they are introduced.*

## 🏗️ Architecture

The application will use **feature-first Clean Architecture with CQRS**.

Each feature owns its presentation, domain, and data layers. Within the domain layer, CQRS separates operations that modify application state from operations that retrieve information.

Planned high-level structure:

```text
lib/
├── app/
├── core/
├── features/
│   └── products/
│       ├── data/
│       │   ├── datasources/
│       │   ├── models/
│       │   └── repositories/
│       ├── domain/
│       │   ├── entities/
│       │   ├── repositories/
│       │   ├── commands/
│       │   ├── queries/
│       │   └── handlers/
│       └── presentation/
│           ├── bloc/
│           ├── screens/
│           └── widgets/
└── main.dart
```

The final structure may evolve as implementation requirements become clearer. Commands, queries, and handlers will be introduced where they provide meaningful separation rather than adding unnecessary abstractions.

### Architectural Principles

- **Feature ownership:** Related presentation, business logic, and data-access code is organized within the same feature.
- **Layered responsibilities:** Presentation coordinates UI behavior, domain defines business rules and CQRS operations, and data handles persistence and external services.
- **CQRS:** Commands represent state-changing operations; queries retrieve data without changing application state.
- **Dependency inversion:** Domain contracts do not depend directly on infrastructure implementations.
- **Repository pattern:** Data access is abstracted behind domain-level repository contracts.
- **Single responsibility:** Commands, queries, and their handlers have focused responsibilities.
- **Dependency injection:** Dependencies are provided rather than constructed throughout the application.
- **Controlled dependencies:** Presentation and data layers depend inward on domain contracts; the domain remains independent of outer layers.

## 📦 Application Features

The project will use a Product Management application to demonstrate the architecture.

### Planned Features

- [ ] Product listing and details
- [ ] Create, update, and delete products
- [ ] Search and filtering
- [ ] Local database persistence
- [ ] Mock REST API integration using Dio
- [ ] Local-first data access and persistence
- [ ] Synchronization between local storage and the mock API
- [ ] Loading, error, and synchronization states
- [ ] Dependency injection
- [ ] Unit and widget tests
- [ ] Integration tests
- [ ] Automated CI checks

Features will be marked complete as they are implemented and verified.

## 🔄 Offline-First Strategy

The application is designed to remain useful when network connectivity is unavailable.

Remote API integration will initially use a mock REST API. Local persistence will support offline access, while synchronization behavior—including retries, duplicate-request prevention, and conflict handling—will be implemented and tested incrementally. A real backend may be introduced later without changing the domain contracts.

The intended data flow is:

1. The UI dispatches an action to the feature's presentation layer.
2. BLoC/Cubit invokes the appropriate command or query handler.
3. Query handlers retrieve data through domain repository contracts.
4. Command handlers execute state-changing operations through domain repository contracts.
5. Data-layer implementations persist changes locally.
6. Changes requiring remote synchronization are tracked.
7. A synchronization process attempts to send pending changes to the mock API.
8. Failed operations remain eligible for retry.
9. The UI communicates relevant loading, error, and synchronization states to the user.

Connectivity detection will help inform synchronization decisions, but actual API requests will handle network failures independently.

Conflict resolution, retry policies, and duplicate-request prevention will be designed and documented during implementation.

## 🧪 Code Quality and Testing

The project aims to maintain quality through:

- Static analysis with `flutter analyze`
- Consistent Dart formatting
- Unit tests for command handlers, query handlers, and domain logic
- Repository tests for data access and synchronization
- Widget tests for presentation behavior
- Integration tests for critical application flows
- GitHub Actions for automated verification

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.47.7 on the stable channel
- Dart SDK 3.13.5
- Git
- Android Studio or another supported development environment

The project targets Flutter 3.47.7 and Dart 3.13.5. Dependency versions and SDK constraints will be maintained in `pubspec.yaml`.

## 📚 Engineering Decisions

This repository will document significant technical decisions, including:

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

As development progresses, this README will be updated with implementation details, diagrams, test coverage, and verified examples.
