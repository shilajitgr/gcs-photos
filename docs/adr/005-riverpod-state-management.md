# ADR-005: Riverpod for Flutter State Management

**Status:** Accepted
**Date:** 2026-04-09

## Decision
Use Riverpod as the state management solution for the Flutter client.

## Context
The app requires reactive state for: gallery grid, upload progress, sync status, offline/online transitions, and Drift database streams.

### Alternatives Considered
| Option | Verdict |
|--------|---------|
| Bloc/Cubit | Event-driven, highly structured, but more boilerplate |
| Provider | Official Flutter recommendation but less powerful |
| GetX | Minimal boilerplate but controversial, less testable |

## Consequences
- Type-safe and compile-time checked — catches state errors at build time
- Native integration with Drift's reactive streams (watch queries → UI updates)
- Testable — providers can be overridden in tests with mocktail
- No `BuildContext` dependency for accessing state — works in background isolates
- Code generation via `riverpod_generator` reduces boilerplate
