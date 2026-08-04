---
applyTo: "src/**/*.csproj,src/**/*.sln,src/**/Program.cs,src/**/*.cs,src/**/*.razor"
---

# .NET Project Structure Instructions

Use these rules when creating new .NET applications or adding projects to an existing solution.

## Solution and Project Layout

- Keep all application code under `src/`.
- Use one top-level folder per product/app area (`src/web`, `src/function`, `src/console`, `src/mcp`, etc.).
- Inside each app area, split into focused projects:
  - runtime app project (`Website`, `Function`, etc.)
  - shared/data library project (`Data`, `Entities`, `DataLayer`, etc.)
  - test project (`Tests`)
- Keep one `.sln` per app area so each deployable can be built/tested independently.

## Folder Design Inside App Projects

- Use consistent functional folders:
  - `API` for controllers/endpoints
  - `Models` for contracts/entities
  - `Repositories` for data access abstractions/implementations
  - `Helpers` for cross-cutting utilities
  - `Pages`/`Components`/`Shared` for UI projects
  - `Properties` for launch settings
- Keep static assets and runtime data in `wwwroot` or project-local data folders.
- Keep configuration files (`appsettings*.json`, `applicationSettings.json`) with the app project.

## csproj Conventions

- Target a single explicit framework per project unless multi-targeting is required.
- Set `ImplicitUsings` and `Nullable` intentionally per project type.
- Keep package references grouped and minimal.
- Use `ProjectReference` for internal dependencies instead of duplicating models/contracts.
- Include runtime files explicitly when they must be copied to output.

## Test Project Conventions

- Keep tests in sibling `Tests` project under the same app area.
- Mirror runtime structure by test type folders (`APITests`, `RepositoryTests`, `ModelTests`).
- Include shared test data/builders in `SampleData` (or equivalent) to avoid duplication.
- Configure code coverage settings in-project so local and CI runs behave consistently.

## Startup and Composition

- Keep `Program.cs` as the composition root:
  - configuration loading
  - service registration
  - auth/authorization setup
  - middleware pipeline
  - endpoint mapping
- Keep startup orchestration readable; move detailed logic into helpers/services.

## Naming and Consistency

- Keep project names, assembly names, and folder names aligned.
- Use stable suffixes (`.Web`, `.Data`, `.Tests`, `.Function`, etc.) to clarify project purpose.
- Prefer explicit names over abbreviations for folders and projects.
