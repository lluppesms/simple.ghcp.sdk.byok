---
applyTo: "infra/**/*.bicep,infra/**/*.bicepparam"
---

# Bicep Authoring Instructions

Use these rules when creating or changing Azure IaC in Bicep.

## File and Folder Structure

- Place orchestration files in `infra/Bicep/` (for example: `main.bicep`, `resourcenames.bicep`, `main.bicepparam`).
- Place reusable resources under `infra/Bicep/modules/<capability>/`.
- Keep one primary resource concern per module file (for example: web app, SQL server, key vault, storage account).
- Keep naming/abbreviation data in dedicated data files (for example `infra/Bicep/data/*.json`) and load it from Bicep instead of hardcoding suffixes repeatedly.

## Composition and Template Patterns

- Use a single top-level entry file that orchestrates modules and controls deployment type switches.
- Use module conditions (`if (...)`) to gate optional stacks (web, function, container, database, etc.).
- Centralize calculated names in a dedicated naming module and pass outputs into downstream modules.
- Prefer passing structured objects (`commonTags`, `customAppSettings`) into modules rather than many repeated scalar params.
- Use `union(...)` for merge scenarios (for example base settings + custom settings, common tags + module tags).

## Parameters, Variables, and Outputs

- Use `param` for external inputs, `var` for derived values, and `output` for values consumed by pipelines or downstream templates.
- Prefer explicit `@description` on externally important parameters.
- Use `@secure()` for secrets.
- Use `@allowed([...])` for constrained inputs (SKU tiers, deployment modes, runtime options).
- Normalize and sanitize naming inputs once, then reuse those sanitized values consistently.

## Naming and Conventions

- Use camelCase for params/vars/outputs and PascalCase for user-facing tag values.
- Use suffix-based naming conventions for Azure resources and enforce provider limits (for example 24-char storage account and key vault limits).
- Keep module names stable and human-readable (`webSite`, `sql-server`, `containerRegistry`, etc.) so deployment histories are understandable.

## App Configuration via IaC

- Pass app settings through explicit `customAppSettings` objects.
- For app-service style configuration keys representing nested config, use double underscore separators (`Section__Subsection__Key`).
- Keep environment-specific token placeholders in `.bicepparam` files and let CI/CD replace tokens.

## Security and Observability

- Apply shared tags to every resource.
- Set secure transport/network defaults where supported (TLS minimums, HTTPS only, explicit public access posture).
- Wire diagnostics to a central Log Analytics workspace or equivalent telemetry sink.
- Use managed identities and role assignments instead of embedded credentials.

## Reuse Checklist

- New resource type: create `infra/Bicep/modules/<area>/<resource>.bicep`.
- Expose only required outputs.
- Update top-level `main.bicep` to call the module.
- Update `.bicepparam` with tokenized values for pipeline-driven deployment.
