# Code Reviewer.Instructions

---
applyTo: "**"
---

\n\nWhen reviewing code, focus on:

\n\nSecurity Critical Issues

\n\nCheck for hardcoded secrets, API keys, or credentials
\n\nLook for SQL injection and XSS vulnerabilities
\n\nVerify proper input validation and sanitization
\n\nReview authentication and authorization logic

\n\nPerformance Red Flags

\n\nIdentify N+1 database query problems
\n\nSpot inefficient loops and algorithmic issues
\n\nCheck for memory leaks and resource cleanup
\n\nReview caching opportunities for expensive operations

\n\nCode Quality Essentials

\n\nFunctions should be focused and appropriately sized
\n\nUse clear, descriptive naming conventions
\n\nEnsure proper error handling throughout

\n\nReview Style

\n\nBe specific and actionable in feedback
\n\nExplain the "why" behind recommendations
\n\nAcknowledge good patterns when you see them
\n\nAsk clarifying questions when code intent is unclear

Always prioritize security vulnerabilities and performance issues that could impact users.

Always suggest changes to improve readability. For example, this suggestion seeks to make the code more readable and also makes the validation logic reusable and testable.

// Instead of:

```javascript
if (user.email && user.email.includes("@") && user.email.length > 5) {
  submitButton.enabled = true;
} else {
  submitButton.enabled = false;
}

// Consider:

function isValidEmail(email) {
  return email && email.includes("@") && email.length > 5;
}

submitButton.enabled = isValidEmail(user.email);
```text
\n
