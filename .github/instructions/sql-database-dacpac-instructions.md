---
applyTo: "src/sql.database/**/*.sql,src/sql.database/**/*.sqlproj,.github/workflows/**/*dacpac*.yml,.github/workflows/**/*sql*.yml"
---

# SQL Database + DACPAC Instructions

Use these rules when creating or modifying SQL database source projects and their deployment pipelines.

## Database Source Layout

- Keep SQL database source in a dedicated project folder (for example `src/sql.database/`).
- Use a SQL SDK project file (`*.sqlproj`) as the deployment source of truth.
- Organize scripts by object type under a schema-rooted folder structure:
  - `Schemas/`
  - `<SchemaName>/Tables/`
  - `<SchemaName>/Stored Procedures/`
  - `<SchemaName>/Views/`
- Keep schema creation explicit in `Schemas/<SchemaName>.sql`.

## Object Authoring Rules

- Use one SQL object per file.
- Name files after object names (`<ObjectName>.sql`).
- Always schema-qualify object names (`[Schema].[Object]`).
- Keep constraints explicit and named (`PK_*`, `FK_*`, `DF_*`, `CK_*`).
- Keep table defaults/check constraints near table definition for readability.

## Pre/Post Deployment Scripts

- Use `Pre.Deployment.sql` for controlled migration cleanup/compatibility operations.
- Use `Post.Deployment.sql` for deployment messaging and post-deploy orchestration hooks.
- Keep data bootstrap and patch execution scripts separate from schema objects.

## Patch/Data Scripts

- Store manual/operational scripts in a dedicated `Patch/` folder.
- Use deterministic, sortable names for temporal patches (for example `Patch-YYYYMMDD.sql`).
- Keep default seed scripts explicit (`InsertDefaultData.sql`) and runnable independently.
- Do not mix core schema object creation into patch files.

## sqlproj Management

- Disable implicit item inclusion when you need explicit object control.
- Register all deployable objects with explicit `<Build Include="...">` entries.
- Register pre/post deployment scripts with `<PreDeploy>` and `<PostDeploy>`.
- Keep folder entries synchronized with physical structure.

## CI/CD Delivery Pattern

- Build DACPAC in a dedicated build workflow/template.
- Publish DACPAC artifact and deploy it in a dedicated deploy workflow/template.
- Run optional SQL patch/default-data scripts as a separate workflow/template step after DACPAC deploy.
- Support both federated identity auth and SQL auth; default to identity-based auth.

## Safety and Repeatability

- Make scripts idempotent where practical for rerun safety.
- Keep destructive operations gated, explicit, and justified.
- Print concise progress markers in scripts for pipeline troubleshooting.
