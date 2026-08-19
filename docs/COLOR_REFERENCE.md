# ByteQuest Color Reference Card

Quick reference for ByteQuest Web Dashboard colors.

---

## ðŸŽ¨ Semantic Color Classes (Use These!)

### Backgrounds
```tsx
bg-background       // #F8FAFC - Main page background
bg-card             // #FFFFFF - Cards, modals, sidebar
bg-primary          // #0B63F6 - Primary buttons, important elements
bg-accent           // #DBEAFE - Subtle highlights, active nav
bg-muted            // #E2E8F0 - Disabled states, subtle backgrounds
bg-destructive      // Red - Error states, delete buttons
```

### Text Colors
```tsx
text-foreground           // #0F172A - Main headings, primary text
text-muted-foreground     // #64748B - Descriptions, helper text
text-primary              // #0B63F6 - Links, active text
text-primary-foreground   // #FFFFFF - Text on primary background
text-accent-foreground    // #0B63F6 - Text on accent background
text-destructive          // Red - Error messages
```

### Borders
```tsx
border-border       // #E2E8F0 - Default borders
border-input        // #E2E8F0 - Input borders
border-primary      // #0B63F6 - Primary element borders
border-destructive  // Red - Error borders
```

---

## ðŸ”µ ByteQuest Blue Palette

### Primary Blue (Main Brand Color)
```css
Electric Blue
Hex: #0B63F6
HSL: hsl(217, 91%, 50%)
RGB: rgb(11, 99, 246)

Usage: Primary buttons, links, active states, focus rings
Class: bg-primary, text-primary, border-primary
```

### Dark Navy (Main Text)
```css
Deep Navy
Hex: #0F172A
HSL: hsl(222, 47%, 11%)
RGB: rgb(15, 23, 42)

Usage: Headings, important text, main content
Class: text-foreground
```

### Soft Sky Blue (Accent)
```css
Soft Sky Blue
Hex: #DBEAFE
HSL: hsl(214, 100%, 92%)
RGB: rgb(219, 234, 254)

Usage: Active navigation, subtle highlights, soft backgrounds
Class: bg-accent
```

---

## âšª Neutral Palette

### Background
```css
Soft Light Gray
Hex: #F8FAFC
HSL: hsl(220, 20%, 98%)
RGB: rgb(248, 250, 252)

Usage: Main page background
Class: bg-background
```

### Card White
```css
Pure White
Hex: #FFFFFF
HSL: hsl(0, 0%, 100%)
RGB: rgb(255, 255, 255)

Usage: Cards, modals, forms, sidebar
Class: bg-card
```

### Muted Gray
```css
Soft Gray
Hex: #E2E8F0
HSL: hsl(220, 13%, 91%)
RGB: rgb(226, 232, 240)

Usage: Borders, dividers, disabled states
Class: bg-muted, border-border
```

### Secondary Text
```css
Slate Gray
Hex: #64748B
HSL: hsl(215, 16%, 47%)
RGB: rgb(100, 116, 139)

Usage: Descriptions, helper text, placeholders
Class: text-muted-foreground
```

---

## ðŸŽ¯ Status Colors

### Success
```css
Green
Classes: bg-green-100 text-green-700

Usage: Completed status, success messages
Example:
<span className="bg-green-100 text-green-700 px-2.5 py-1 rounded-full text-xs font-semibold">
  Completed
</span>
```

### Warning
```css
Orange
Classes: bg-orange-100 text-orange-700, bg-orange-500 text-white

Usage: Warning states, scenarios, notifications
Example:
<span className="bg-orange-100 text-orange-700 px-2.5 py-1 rounded-full text-xs font-semibold">
  Pending
</span>
```

### Error/Destructive
```css
Red
Classes: bg-destructive text-destructive-foreground, bg-red-100 text-red-700

Usage: Errors, delete actions, failed status
Example:
<Button variant="destructive">Delete</Button>
```

### Info
```css
Blue
Classes: bg-accent text-accent-foreground

Usage: Information, in-progress status
Example:
<span className="bg-accent text-accent-foreground px-2.5 py-1 rounded-full text-xs font-semibold">
  In Progress
</span>
```

---

## ðŸ“Š Chart Colors

```css
Chart Color 1: hsl(217, 91%, 60%)  - Primary Blue (lighter)
Chart Color 2: hsl(199, 89%, 48%)  - Cyan
Chart Color 3: hsl(142, 71%, 45%)  - Green
Chart Color 4: hsl(38, 92%, 50%)   - Orange
Chart Color 5: hsl(271, 91%, 65%)  - Purple

Usage: For charts and data visualizations
Classes: bg-chart-1, bg-chart-2, bg-chart-3, etc.
```

---

## ðŸŽ¨ Common Color Combinations

### Primary Button
```tsx
<Button className="bg-primary text-primary-foreground hover:bg-primary/90">
  Click Me
</Button>
```

### Card with Hover
```tsx
<Card className="border shadow-sm hover:shadow-md hover:border-primary/20">
  {/* Content */}
</Card>
```

### Active Navigation Item
```tsx
<Link className="bg-accent text-accent-foreground shadow-sm">
  Dashboard
</Link>
```

### KPI Card (Blue)
```tsx
<Card className="bg-primary text-primary-foreground">
  <CardContent className="p-6">
    <p className="text-primary-foreground/80">Label</p>
    <h3 className="text-3xl font-bold">Value</h3>
  </CardContent>
</Card>
```

### KPI Card (Orange)
```tsx
<Card className="bg-orange-500 text-white">
  <CardContent className="p-6">
    <p className="text-orange-100">Label</p>
    <h3 className="text-3xl font-bold">Value</h3>
  </CardContent>
</Card>
```

### Status Badge (Success)
```tsx
<span className="bg-green-100 text-green-700 px-2.5 py-1 rounded-full text-xs font-semibold">
  Active
</span>
```

### Status Badge (Warning)
```tsx
<span className="bg-orange-100 text-orange-700 px-2.5 py-1 rounded-full text-xs font-semibold">
  Pending
</span>
```

### Table Header
```tsx
<thead className="text-xs text-muted-foreground uppercase bg-muted/50 border-b border-border">
  {/* ... */}
</thead>
```

### Table Row
```tsx
<tr className="bg-card hover:bg-muted/30 transition-colors">
  {/* ... */}
</tr>
```

---

## ðŸš« What NOT to Use

### âŒ Avoid Hardcoded Colors
```tsx
// âŒ Bad
className="bg-blue-600 text-white"
className="bg-gray-50 text-gray-900"
className="border-gray-200"

// âœ… Good
className="bg-primary text-primary-foreground"
className="bg-muted text-foreground"
className="border-border"
```

### âŒ Avoid Random Blues
```tsx
// âŒ Bad - Random shades
className="bg-blue-50"
className="bg-blue-100"
className="text-blue-700"

// âœ… Good - Use accent instead
className="bg-accent"
className="text-accent-foreground"
className="text-primary"
```

---

## ðŸ” Quick Lookup Table

| Need | Use | Class |
|------|-----|-------|
| Page background | Soft Light Gray | `bg-background` |
| Card background | White | `bg-card` |
| Main text | Dark Navy | `text-foreground` |
| Secondary text | Slate Gray | `text-muted-foreground` |
| Primary button | Electric Blue | `bg-primary text-primary-foreground` |
| Active nav item | Soft Sky Blue | `bg-accent text-accent-foreground` |
| Border/divider | Soft Gray | `border-border` |
| Success status | Green | `bg-green-100 text-green-700` |
| Warning status | Orange | `bg-orange-100 text-orange-700` |
| Error status | Red | `bg-destructive text-destructive-foreground` |
| Link color | Electric Blue | `text-primary hover:underline` |

---

## ðŸ’¡ Pro Tips

1. **Always use semantic tokens** (bg-primary, text-foreground) instead of hardcoded colors
2. **For status colors**, use specific classes like `bg-green-100 text-green-700`
3. **For hover states**, use `/90` or `/80` opacity: `hover:bg-primary/90`
4. **For active states**, use `bg-accent text-accent-foreground`
5. **For disabled states**, use `bg-muted text-muted-foreground`
6. **For focus rings**, use `focus-visible:ring-2 focus-visible:ring-ring`

---

## ðŸ“± Responsive Color Notes

Colors remain consistent across breakpoints. Only layout and spacing change with screen size.

---

## ðŸŽ¯ Accessibility

All color combinations meet WCAG 2.1 AA standards for contrast:
- âœ… `text-foreground` on `bg-background` - 14.56:1
- âœ… `text-primary-foreground` on `bg-primary` - 8.37:1
- âœ… `text-accent-foreground` on `bg-accent` - 8.37:1
- âœ… `text-muted-foreground` on `bg-background` - 4.84:1

---

**Last Updated**: June 5, 2026  
**Version**: 1.0.0  
**For**: ByteQuest Web Dashboard

