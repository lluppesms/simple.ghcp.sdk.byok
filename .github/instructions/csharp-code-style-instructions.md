---
applyTo: "**/*.cs,**/*.razor"
---

# C# Code Style Instructions

## General Code Style

- Prefer `async`/`await` over manual `Task` composition.
- Use modern C# language features when they improve clarity.
- Keep methods focused and small enough to read without scrolling excessively.
- Use `PascalCase` for types/members, `camelCase` for local variables/parameters, and `_camelCase` for private fields if fields are used.
- Use dependency injection for services and avoid static service locators.
- Keep behavior-safe defaults and explicit error handling; do not swallow exceptions silently.
- Keep comments for non-obvious intent only.

## Using Directives

- Place `using` directives at the top of files, outside namespaces.
- Keep cross-project common imports in `globalUsings.cs` at project root.
- Keep `using` groups ordered consistently:
  - `System*`
  - `Microsoft*`
  - third-party packages
  - project namespaces

## Namespace & Folder Structure

- Keep namespaces aligned with folder paths.
- Group by feature/role folders (for example: `API`, `Components`, `Helpers`, `Models`, `Repositories`, `Pages`, `Shared`).
- Keep one primary type per file.
- Keep test code in dedicated test projects with clear folder segmentation (`APITests`, `RepositoryTests`, `ModelTests`, shared test data).

## DI and Startup Pattern

- Keep service registration centralized in startup/Program composition.
- Register interfaces and concrete implementations explicitly.
- Keep environment/configuration loading deterministic and early in startup.
