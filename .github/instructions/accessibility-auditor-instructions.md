---

applyTo: **/*.html

---

\n\nAccessibility Auditor Guidelines

When evaluating code or content for accessibility compliance:

When generating code, ensure accessibility compliance by following these priorities:

\n\nSemantic HTML First

\n\nUse proper semantic elements: `<nav>`, `<main>`, `<section>`, `<article>`, `<header>`, `<footer>`
\n\nStructure headings sequentially (h1 → h2 → h3, never skip levels)
\n\nUse one `<h1>` per page with descriptive heading text

\n\nEssential ARIA Requirements

\n\nAdd `alt` text to all images
\n\nLabel form inputs with `<label>` or `aria-label`
\n\nEnsure interactive elements have accessible names
\n\nUse `aria-expanded` for collapsible content
\n\nAdd `role`, `aria-labelledby`, and `aria-describedby` when semantic HTML isn't sufficient

\n\nKeyboard Navigation

\n\nAll interactive elements must be keyboard accessible
\n\nProvide visible focus indicators (minimum 2px outline)
\n\nInclude skip links: `<a href="#main">Skip to main content</a>`
\n\nUse logical tab order that matches visual layout

\n\nColor and Contrast

\n\nEnsure 4.5:1 contrast ratio for normal text, 3:1 for large text
\n\nDon't rely solely on color to convey information

\n\nQuick Test Questions

\n\nCan you navigate the entire interface using only Tab/Shift+Tab/Enter?
\n\nAre all images and icons properly described?
\n\nCan screen reader users understand the content and functionality?

\n\nScreen Reader Compatibility

# Provide descriptive text for all non-text content

\n\nImages: Use alt text that describes function, not just appearance
\n\nGood: `alt="Submit form"`
\n\nAvoid: `alt="Blue button"`
\n\nForm inputs: Associate every input with a `<label>` element
\n\nLinks: Use descriptive link text
\n\nGood: "Download the accessibility report (PDF, 2MB)"
\n\nAvoid: "Click here" or "Read more"

## Announce dynamic content updates

\n\nUse `aria-live="polite"` for status updates
\n\nUse `aria-live="assertive"` for urgent notifications
\n\nUpdate screen reader users when content changes without page reload

---

\n\nColor and Contrast Requirements

## Meet these specific contrast ratios

\n\nNormal text (under 18pt): Minimum 4.5:1 contrast ratio
\n\nLarge text (18pt+ or 14pt+ bold): Minimum 3:1 contrast ratio
\n\nUI components and graphics: Minimum 3:1 contrast ratio

## Provide multiple visual cues

\n\nUse color + icon + text for status indicators
\n\nAdd patterns or textures to distinguish chart elements
\n\nInclude text labels on graphs and data visualizations

---

\n\nTesting Integration Steps

## Include these automated checks

\n\nRun axe-core accessibility scanner in CI/CD pipeline
\n\nTest with lighthouse accessibility audit
\n\nValidate HTML markup for semantic correctness

## Perform these manual tests

\n\nNavigate entire interface using only Tab and arrow keys
\n\nTest with screen reader (NVDA on Windows, VoiceOver on Mac)
\n\nVerify 200% zoom doesn't break layout or hide content
\n\nCheck color contrast with tools like WebAIM Color Contrast Checker

---

\n\nForm Design Standards

## Create accessible form experiences

\n\nPlace labels above or to the left of form fields
\n\nGroup related fields with `<fieldset>` and `<legend>`
\n\nDisplay validation errors immediately after the field with `aria-describedby`
\n\nUse `aria-required="true"` for required fields
\n\nProvide clear instructions before users start filling out forms

## Error message format

```html
<input aria-describedby="email-error" aria-invalid="true" />

<div id="email-error">Please enter a valid email address</div>
```text
---

**Code Generation Rule:** Always include accessibility comments explaining ARIA attributes and semantic choices. Test code with keyboard navigation before suggesting it's complete.

\n
