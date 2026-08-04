# Copilot Instructions

The github repo is lluppesms/dadabase.demo and the primary branch that I work off of is main.

## ⚠️ Git Branch Policy — AGENTS MUST FOLLOW THIS

Do not commit or push changes unless directly instructed by the user.  If instructed to commit, then follow these guidelines.

**NEVER commit directly to `main` or `master`.** This is a strict rule for all agents and automated tools.

Before making any commits or file changes:
1. **Check the current branch**: `git branch --show-current`
2. **If on `main` or `master`, create and switch to a feature branch first**:
   ```
   git checkout -b feature/short-description-of-task
   ```
3. **All work must be committed to the feature branch**, not to `main`/`master`.
4. When finished, open a Pull Request targeting `main` — do not merge directly.

Branch naming convention: `feature/short-description`, `fix/short-description`, or `chore/short-description`.

The human owner will review and merge PRs into `main`. Agents do not have permission to merge.

## File Organization
- Keep related files together
- Use meaningful file names
- Follow consistent folder structure
- Group components by feature when possible

## Project Structure
- Any actual source code should be located in the src folder. Organize each project into its own folder within src.
- Any infrastructure code should be located in the infra folder, and put each type of IaC code into it's own folder, such as Bicep in the infra/bicep folder and Terraform in the infra/tf folder.
- Any code for the GitHub Actions workflows should be located in the .github/workflows folder.
- Any code for Azure DevOps pipelines should be located in the .azdo/pipelines folder (legacy repos may also use .azuredevops/pipelines).
- Keep documentation and images in a Docs folder.

## Blazor & CSS

When making changes to Blazor components or CSS, refer to [instructions/blazor-css-instructions.md](instructions/blazor-css-instructions.md) for detailed guidelines on component structure, scoped CSS, theming, and CSS best practices.

## C# Code Style

When writing or modifying C# code, refer to [instructions/csharp-code-style-instructions.md](instructions/csharp-code-style-instructions.md) for naming conventions, `using` directive organization, namespace structure, and folder layout.

## .NET Project Structure

When creating or modifying .NET projects and solutions, refer to [instructions/dotnet-project-structure-instructions.md](instructions/dotnet-project-structure-instructions.md) for project layout, naming, and composition guidance.

## Bicep Infrastructure

When writing or modifying Bicep IaC files, refer to [instructions/bicep-instructions.md](instructions/bicep-instructions.md) for module structure, naming, parameter design, and composition patterns.

## GitHub Actions & Azure DevOps Pipelines

When creating or modifying GitHub Actions workflows, refer to [instructions/github-actions-instructions.md](instructions/github-actions-instructions.md) for reusable workflow structure, contracts, and deployment patterns.

## Azure DevOps YAML Pipelines

When creating or modifying Azure DevOps YAML files under `.azdo/pipelines/`, refer to [instructions/azure-devops-pipeline-instructions.md](instructions/azure-devops-pipeline-instructions.md) for stage/job/step/vars template layering and environment promotion patterns.

## SQL Database and DACPAC

When creating or modifying SQL database source, schema objects, DACPAC build/deploy workflows, or SQL patch scripts, refer to [instructions/sql-database-dacpac-instructions.md](instructions/sql-database-dacpac-instructions.md).

## Testing

When writing tests, refer to [instructions/testing-instructions.md](instructions/testing-instructions.md) for test framework, project location, and scope guidelines.

## General Best Practices

For error handling, performance, security, accessibility, and documentation standards, refer to [instructions/general-best-practices-instructions.md](instructions/general-best-practices-instructions.md).

---

Apply these conventions when generating new code, infrastructure, or workflow files to ensure consistency with the existing project style.
