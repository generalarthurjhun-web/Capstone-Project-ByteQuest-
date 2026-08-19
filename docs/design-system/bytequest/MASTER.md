# Design System Master File

> **LOGIC:** When building a specific page, first check `docs/design-system/bytequest/pages/[page-name].md`.
> If that file exists, its rules **override** this Master file.
> If not, strictly follow the rules below.

---

**Project:** ByteQuest
**Generated:** 2026-08-07 23:47:17
**Category:** Educational Technology / Competency Assessment Platform
**Design Dials:** Variance 4/10 (Balanced / Modern) | Motion 2/10 (Subtle) | Density 7/10 (Standard)

---

## Global Rules

### Color Palette

| Role | Hex | CSS Variable |
|------|-----|--------------|
| Primary | `#1E3A8A` | `--color-primary` |
| On Primary | `#FFFFFF` | `--color-on-primary` |
| Secondary | `#3B82F6` | `--color-secondary` |
| Accent/CTA | `#7C3AED` | `--color-accent` |
| Background | `#F8FAFC` | `--color-background` |
| Foreground | `#1E40AF` | `--color-foreground` |
| Muted | `#E9EEF5` | `--color-muted` |
| Border | `#BFDBFE` | `--color-border` |
| Destructive | `#DC2626` | `--color-destructive` |
| Ring | `#1E3A8A` | `--color-ring` |

**Color Notes:** Knowledge blue + link purple + clean white

### Typography

- **Heading Font:** Inter
- **Body Font:** Inter
- **Mood:** minimal, clean, swiss, functional, neutral, professional
- **Google Fonts:** [Inter + Inter](https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap)

**CSS Import:**
```css
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');
```

### Spacing Variables

*Density: 7/10 â€” Standard*

| Token | Value | Usage |
|-------|-------|-------|
| `--space-xs` | `4px` / `0.25rem` | Tight gaps |
| `--space-sm` | `8px` / `0.5rem` | Icon gaps, inline spacing |
| `--space-md` | `16px` / `1rem` | Standard padding |
| `--space-lg` | `24px` / `1.5rem` | Section padding |
| `--space-xl` | `32px` / `2rem` | Large gaps |
| `--space-2xl` | `48px` / `3rem` | Section margins |
| `--space-3xl` | `64px` / `4rem` | Hero padding |

### Shadow Depths

| Level | Value | Usage |
|-------|-------|-------|
| `--shadow-sm` | `0 1px 2px rgba(0,0,0,0.05)` | Subtle lift |
| `--shadow-md` | `0 4px 6px rgba(0,0,0,0.1)` | Cards, buttons |
| `--shadow-lg` | `0 10px 15px rgba(0,0,0,0.1)` | Modals, dropdowns |
| `--shadow-xl` | `0 20px 25px rgba(0,0,0,0.15)` | Hero images, featured cards |

---

## Component Specs

### Buttons

```css
/* Primary Button */
.btn-primary {
  background: #7C3AED;
  color: white;
  padding: 12px 24px;
  border-radius: 8px;
  font-weight: 600;
  transition: all 200ms ease;
  cursor: pointer;
}

.btn-primary:hover {
  opacity: 0.9;
  transform: translateY(-1px);
}

/* Secondary Button */
.btn-secondary {
  background: transparent;
  color: #1E3A8A;
  border: 2px solid #1E3A8A;
  padding: 12px 24px;
  border-radius: 8px;
  font-weight: 600;
  transition: all 200ms ease;
  cursor: pointer;
}
```

### Cards

```css
.card {
  background: #F8FAFC;
  border-radius: 12px;
  padding: 24px;
  box-shadow: var(--shadow-md);
  transition: all 200ms ease;
  cursor: pointer;
}

.card:hover {
  box-shadow: var(--shadow-lg);
  transform: translateY(-2px);
}
```

### Inputs

```css
.input {
  padding: 12px 16px;
  border: 1px solid #E2E8F0;
  border-radius: 8px;
  font-size: 16px;
  transition: border-color 200ms ease;
}

.input:focus {
  border-color: #1E3A8A;
  outline: none;
  box-shadow: 0 0 0 3px #1E3A8A20;
}
```

### Modals

```css
.modal-overlay {
  background: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(4px);
}

.modal {
  background: white;
  border-radius: 16px;
  padding: 32px;
  box-shadow: var(--shadow-xl);
  max-width: 500px;
  width: 90%;
}
```

---

## Style Guidelines

**Style:** Swiss Modernism 2.0

**Keywords:** Grid system, Helvetica, modular, asymmetric, international style, rational, clean, mathematical spacing

**Best For:** Corporate sites, architecture, editorial, SaaS, museums, professional services, documentation

**Key Effects:** display: grid, grid-template-columns: repeat(12 1fr), gap: 1rem, mathematical ratios, clear hierarchy

### Page Patterns

- **Learner Mobile:** task-first vertical flow with compact context, one primary action, visible state, and a workspace-first simulation canvas.
- **Instructor Web:** scoped operational workspace with restrained summary cards, evidence-first review, contextual actions, and responsive tables/lists.
- **Admin Web:** governance workspace with account state, access scope, audit evidence, and safeguarded destructive actions.
- **Assessment Review:** context â†’ authority state â†’ ordered evidence â†’ criterion outcomes â†’ Instructor decision â†’ immutable revision history â†’ release.

---

## Motion

**Scroll Reveal** (Subtle) â€” Trigger: scroll (viewport enter) | Duration: 300-400ms | Easing: `power1.out`

```js
gsap.from(el, { opacity: 0, y: 12, duration: 0.35, ease: 'power1.out', scrollTrigger: { trigger: el, start: 'top 90%', toggleActions: 'play none none reverse' } });
```

**Framework notes:** Requires the ScrollTrigger plugin registered once via gsap.registerPlugin(ScrollTrigger)

- âœ… Keep the y offset small (8-16px) so it reads as a fade, not a slide
- âŒ Don't reveal below-the-fold content needed for SEO/crawlers as invisible-by-default without a no-JS fallback
- âš¡ toggleActions 'play none none reverse' avoids re-triggering on every scroll direction change

---

## Anti-Patterns (Do NOT Use)

- âŒ Slow updates
- âŒ No automation

### Additional Forbidden Patterns

- âŒ **Emojis as icons** â€” Use SVG icons (Heroicons, Lucide, Simple Icons)
- âŒ **Missing cursor:pointer** â€” All clickable elements must have cursor:pointer
- âŒ **Layout-shifting hovers** â€” Avoid scale transforms that shift layout
- âŒ **Low contrast text** â€” Maintain 4.5:1 minimum contrast ratio
- âŒ **Instant state changes** â€” Always use transitions (150-300ms)
- âŒ **Invisible focus states** â€” Focus states must be visible for a11y

---

## Pre-Delivery Checklist

Before delivering any UI code, verify:

- [ ] No emojis used as icons (use SVG instead)
- [ ] All icons from consistent icon set (Heroicons/Lucide)
- [ ] `cursor-pointer` on all clickable elements
- [ ] Hover states with smooth transitions (150-300ms)
- [ ] Light mode: text contrast 4.5:1 minimum
- [ ] Focus states visible for keyboard navigation
- [ ] `prefers-reduced-motion` respected
- [ ] Responsive: 375px, 768px, 1024px, 1440px
- [ ] No content hidden behind fixed navbars
- [ ] No horizontal scroll on mobile

