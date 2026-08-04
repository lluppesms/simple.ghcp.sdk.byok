---
applyTo: ".azdo/pipelines/**/*.yml,.azdo/pipelines/**/*.yaml"
---

# Azure DevOps YAML Pipeline Instructions

Use these rules when creating or changing Azure DevOps pipelines.

## Canonical Folder Structure

- Keep all Azure DevOps pipeline assets under `.azdo/pipelines/`.
- Use this hierarchy:
  - root pipeline entrypoints (`1-*.yml`, `2.1-*.yml`, etc.)
  - `stages/` for multi-stage orchestration templates
  - `jobs/` for reusable job templates
  - `steps/` for reusable step/task templates
  - `vars/` for variable templates
  - `scripts/` for utility scripts invoked by templates

## Entrypoint Pipeline Pattern

- Entrypoints should:
  - define operator-facing `parameters`
  - load variable groups/templates
  - select one stage template for single-environment runs
  - select the same stage template with multi-environment arrays for promotion runs
- Keep triggers explicit (`trigger: none`) unless intentionally enabling CI.

## Inputs, Variables, and Secrets

- Accept operator controls through top-level `parameters`.
- Keep secret/project values in variable groups.
- Keep shared non-secret defaults in `vars/var-common.yml` (or equivalent).
- Use environment-specific var templates (`vars/var-dev.yml`, `vars/var-qa.yml`, `vars/var-prod.yml`) for overrides.
- Avoid duplicated literal paths and names across templates.

## Template Layering Rules

- `stages/*` templates orchestrate dependency flow and cross-environment promotion.
- `jobs/*` templates encapsulate one deployable responsibility:
  - infra deploy
  - app build
  - app deploy
  - DACPAC build
  - DACPAC deploy
  - SQL script execution
  - scanning/tests
- `steps/*` templates encapsulate repeatable task sequences and auth-specific variants.

## Template Reuse and Composition

- Build templates with single responsibility and stable parameter contracts.
- Pass outputs/variables between layers instead of recomputing values in each template.
- Reuse the same stage template for single-environment and promotion runs by changing the environments array.

## Variable Strategy

- Use variable groups for environment/project secrets and mutable operational values.
- Use `vars/var-common.yml` (or equivalent) for shared non-secret defaults.
- Use `vars/var-<env>.yml` for environment-specific non-secret overrides.
- Keep path/project metadata as reusable variables, not duplicated inline strings.

## Environment and Promotion Model

- Use explicit environment names (for example `DEV`, `QA`, `PROD`) and environment deployments/jobs.
- Support both:
  - single environment execution
  - ordered multi-environment promotion in one run
- Gate downstream promotion stages with explicit dependency conditions.

## Service Connection Selection

- Resolve environment-specific service connections at template compile time using conditional template blocks.
- Do not rely on runtime-computed service connection names for tasks that require precompiled references.

## Bicep + Parameter File Pattern

- Use one shared `.bicepparam` file with token replacement.
- Inject environment and deployment-type tokens during pipeline execution.
- Parse deployment outputs when requested and expose them as pipeline variables for downstream jobs.

## SQL + DACPAC Delivery Pattern

- Build DACPAC on Windows agent pools when required by toolchain.
- Publish DACPAC as pipeline artifact, then deploy in a separate job/stage.
- Keep SQL script execution and DB copy operations in dedicated step templates.
- Support both service principal and SQL authentication paths with identity-based auth as default.

## Naming and Readability

- Use descriptive ordered names for root pipelines to indicate intended execution path.
- Use short, clear display names and parameter names.
- Keep diagnostics informative but bounded; avoid dumping sensitive values.
- Fail fast on missing required inputs/files.
