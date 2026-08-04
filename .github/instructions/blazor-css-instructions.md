---
applyTo: "**/*.razor,**/*.razor.css"
---

# Blazor & CSS Instructions

## Blazor Components

- Always add component-specific CSS in a corresponding `.razor.css` file
- When creating a new component, automatically create a matching `.razor.css` file
- Ignore warnings in Blazor components (they are often false positives)
- Use scoped CSS through the `.razor.css` pattern instead of global styles
- Make sure light and dark theme are respected throughout — never use hard-coded `rgb` or hex values; always define them in the main CSS
- Always add namespace declarations to Blazor components matching their folder structure
- For ASP.NET Core/Blazor, use dependency injection for services and configuration

## Component Structure

- Keep components small and focused
- Extract reusable logic into services
- Use cascading parameters sparingly
- Prefer component parameters over cascading values

## CSS Best Practices

- Use Bootstrap's built-in spacing utilities (`m-*`, `p-*`) for consistent spacing
- Always wrap card content in a `.card-body` element for consistent padding
- Define common padding/margin values as CSS variables in `app.css`
- Use semantic class names that describe the component's purpose
- Avoid direct element styling; prefer class-based selectors
- Keep component-specific styles in `.razor.css` files
- Avoid fixed pixel values for responsive elements
- Use CSS Grid or Flexbox for layout instead of absolute positioning
- Style from the component's root element down to maintain CSS specificity
- When adjusting padding/margin, check both light and dark themes
- Use CSS variables for repeated values (spacing, border-radius, etc.)
- Test responsive behavior across different viewport sizes
- Use `rem`/`em` units for font sizes and spacing for better accessibility
- Document any magic numbers or non-obvious style choices in comments
