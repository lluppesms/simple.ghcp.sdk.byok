# GitHub Actions Instructions

---
applyTo: ".github/workflows/**/*.yml,.github/workflows/**/*.yaml"
---

When creating or changing GitHub Actions workflows, follow this structure-first approach.

## Workflow Architecture

- Keep operator-facing workflows as orchestration entrypoints.
- Keep reusable logic in `template-*.yml` workflows using `workflow_call`.
- Compose workflows by chaining template jobs through `needs`.
- Start complex workflows with a config-loading job that emits path/project outputs for downstream jobs.

## Naming and Organization

- Place all workflows in `.github/workflows/`.
- Use descriptive filenames:
  - Entrypoints: ordered and scenario-focused
  - Reusable templates: `template-<capability>-<action>.yml`
- Keep job IDs concise and action-oriented (`load-config`, `build`, `deploy`, `run-sql`, `smoke-test`).

## Reusable Workflow Contracts

- Define typed `inputs` for all runtime options.
- Define `outputs` only when a downstream job needs the value.
- Keep interfaces stable and additive; avoid breaking input/output renames without migration.
- Use consistent artifact names across build/deploy templates.

## Inputs, Variables, and Secrets

- Accept runtime behavior through typed workflow inputs.
- Resolve generated names once and pass as env/outputs to downstream steps.
- Keep non-sensitive configuration in repository/environment variables.
- Keep secrets in GitHub Secrets only.
- Never print secret values in logs.

## Security Requirements

- Use least-privilege `permissions`.
- Use OIDC login (`id-token: write`) for cloud deployments.
- Keep secrets in repository/environment secrets only.
- Do not log secret values or serialize full secret objects.

## Build and Deploy Patterns

- Use dedicated build templates per deployable type (web app, function app, container image, DACPAC).
- Publish artifacts in build templates and consume them in deploy templates.
- Keep deployment targets environment-scoped (`environment: <envCode>`).
- Resolve generated names once (resource group, app name, server name) and reuse across steps.

## SQL + DACPAC Pattern

- Build DACPAC in a dedicated template.
- Download DACPAC artifact in deploy template and publish via SQL deployment action/tooling.
- Keep optional data/bootstrap scripts in separate SQL execution template.
- Support both federated identity auth and SQL auth where needed, with identity-based auth as the default.

## Operational Quality

- Include cleanup steps with `if: always()` only for logout/cache/account cleanup.
- Keep diagnostics useful but bounded; print resolved inputs/paths without excessive noise.
- Use comments only for non-obvious constraints and migration notes.
- Fail fast for missing required files/inputs.
