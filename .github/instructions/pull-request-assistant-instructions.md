---
applyTo: "**"
---

\n\nPull Request Assistant Guidelines

\n\nWhen creating pull request descriptions or reviewing PRs:

\n\nPR Description Template

# What changed

\n\nClear summary of modifications and affected components
\n\nLink to related issues or tickets

## Why

\n\nBusiness context and requirements
\n\nTechnical reasoning for approach taken

## Testing

\n\n[ ] Unit tests pass and cover new functionality
\n\n[ ] Manual testing completed for user-facing changes
\n\n[ ] Performance/security considerations addressed

## Breaking Changes

\n\nList any API changes or behavioral modifications
\n\nInclude migration instructions if needed

\n\nReview Focus Areas

\n\n**Security**: Check for hardcoded secrets, input validation, auth issues
\n\n**Performance**: Look for database query problems, inefficient loops
\n\n**Testing**: Ensure adequate test coverage for new functionality
\n\n**Documentation**: Verify code comments and README updates

\n\nReview Style

\n\nBe specific and constructive in feedback
\n\nAcknowledge good patterns and solutions
\n\nAsk clarifying questions when code intent is unclear
\n\nFocus on maintainability and readability improvements
\n\nAlways prioritize changes that improve security, performance, or user experience.
\n\nProvide migration guides for significant changes
\n\nUpdate version compatibility information

\n\nDeployment Requirements

\n\n[ ] Database migrations and rollback plans
\n\n[ ] Environment variable updates required
\n\n[ ] Feature flag configurations needed
\n\n[ ] Third-party service integrations updated
\n\n[ ] Documentation updates completed

\n\nCode Review Guidelines

\n\nSecurity Review

\n\nScan for input validation vulnerabilities
\n\nCheck authentication and authorization implementation
\n\nVerify secure data handling and storage practices
\n\nFlag hardcoded secrets or configuration issues
\n\nReview error handling to prevent information leakage

\n\nPerformance Analysis

\n\nEvaluate algorithmic complexity and efficiency
\n\nReview database query optimization opportunities
\n\nCheck for potential memory leaks or resource issues
\n\nAssess caching strategies and network call efficiency
\n\nIdentify scalability bottlenecks

\n\nCode Quality Standards

\n\nEnsure readable, maintainable code structure
\n\nVerify adherence to team coding standards and style guides
\n\nCheck function size, complexity, and single responsibility
\n\nReview naming conventions and code organization
\n\nValidate proper error handling and logging practices

\n\nReview Communication

\n\nProvide specific, actionable feedback with examples
\n\nExplain reasoning behind recommendations to promote learning
\n\nAcknowledge good patterns, solutions, and creative approaches
\n\nAsk clarifying questions when context is unclear
\n\nFocus on improvement rather than criticism

\n\nReview Comment Format

Use this structure for consistent, helpful feedback:

**Issue:** Describe what needs attention

**Suggestion:** Provide specific improvement with code example

**Why:** Explain the reasoning and benefits

\n\nReview Labels and Emojis

\n\n🔒 Security concerns requiring immediate attention
\n\n⚡ Performance issues or optimization opportunities
\n\n🧹 Code cleanup and maintainability improvements
\n\n📚 Documentation gaps or update requirements
\n\n✅ Positive feedback and acknowledgment of good practices
\n\n🚨 Critical issues that block merge
\n\n💭 Questions for clarification or discussion

Always provide constructive feedback that helps the team improve together.

\n
