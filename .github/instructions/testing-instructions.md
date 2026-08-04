---
applyTo: "src/web/Tests/**,src/function/Tests/**,playwright/**,playwright.config*.ts"
---

# Testing Instructions

Use these instructions when adding, updating, or reviewing automated tests in this repository.

## Testing stack and locations

- Use **xUnit v3** for .NET automated tests in this repository.
- Web application tests live in `src/web/Tests/`.
- Function application tests live in `src/function/Tests/`.
- Browser and API workflow tests live under `playwright/`.
- Keep tests close to the application they validate instead of creating a single shared test project.

## Unit testing guidance

Add or update unit and integration-style .NET tests when you change:

- controller or API endpoint behavior
- repository or data-access behavior
- model mapping or serialization behavior
- configuration-dependent logic
- error handling, null handling, or edge-case branching

Unit tests in this repository typically follow these patterns:

- reuse the existing base test helpers such as `BaseTest` and `BaseWebTest` when they fit
- prefer focused tests grouped by concern, such as `APITests`, `RepositoryTests`, and `ModelTests`
- use `Fact` for single scenarios and theory-style coverage when repeated inputs make the test clearer
- mock or substitute external dependencies where practical
- prefer deterministic local test data over live external services
- preserve the repo pattern of using copied sample data and in-memory or JSON-backed test flows when that avoids unnecessary infrastructure coupling

Cover both happy paths and failure paths. If logic branches on missing configuration, invalid input, empty datasets, or repository failures, add tests for those outcomes instead of only testing the success case.

## Playwright testing guidance

Use Playwright when the change affects user-visible behavior, navigation, rendering, browser interaction, or end-to-end application flow.

This repository already uses several Playwright scenario types:

- `playwright/smoke-tests/` for fast confidence checks on core pages and endpoints
- `playwright/basic-tests/` for simple end-to-end UI validation
- `playwright/ui-tests/` for broader user-flow coverage
- `playwright/api-tests/` for API-oriented Playwright checks
- `playwright/page-objects/` for reusable browser interaction helpers

When adding Playwright coverage:

- add a **smoke test** for simple route, page, or readiness verification
- add or update a **page-object-backed UI test** when the flow has multiple reusable interactions
- add **API-focused Playwright coverage** only when browser-driven API verification is a better fit than a .NET test
- prefer resilient selectors such as `data-testid`, accessible roles, labels, and stable text over brittle CSS selectors
- assert user-observable outcomes such as visible headings, navigation success, results lists, and state changes

## Recommended Playwright scenarios

Good candidates for Playwright coverage in this repo include:

- homepage availability and basic rendering
- navigation between primary pages
- search workflows and result rendering
- category filtering or selection behavior
- theme or UI preference interactions
- API smoke checks exposed through the running app experience

Avoid turning Playwright into a substitute for all .NET tests. Business rules, repository behavior, and pure data transformations should usually be covered in the .NET test projects first.

## Running tests

Common local commands:

```powershell
dotnet test .\src\web\Tests\DadABase.Tests.csproj
dotnet test .\src\function\Tests\DadABase.Function.Tests.csproj
npx playwright test
```

Use the repo's existing Playwright configuration files rather than inventing new ones unless there is a clear need:

- `playwright.config.ts`
- `playwright.config.local.ts`
- `playwright.config.workspace.ts`
- `playwright.config.cicd.ts`
- `playwright.config.test-service.ts`

## Guidance for agents

When an agent is asked to test the running app, explore the UI, capture selectors, or generate Playwright coverage for the anonymous web experience, prefer the repository-specific skill:

- `dadabase-playwright-testing`

That skill is the purpose-built app-testing guide for this repository and should be treated as the first-choice workflow for browser-based app testing by agents. Use the general Playwright or web app testing tools only when the repository-specific skill does not cover the requested scenario.

## Default expectations

- Extend existing test structure before creating new patterns
- Keep test names descriptive and behavior-focused
- Do not introduce live-environment dependencies when local data or mocks are sufficient
- Update affected .NET tests and Playwright tests together when a change spans both backend behavior and UI behavior
