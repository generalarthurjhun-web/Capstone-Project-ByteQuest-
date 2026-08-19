# ByteQuest Design System

A modern, clean, and professional design system for the ByteQuest Instructor/Admin Dashboard.

---

## ðŸŽ¨ Color Palette

### Primary Colors
```css
Electric Blue (Primary)
- Hex: #0B63F6
- HSL: hsl(217, 91%, 50%)
- Usage: Primary buttons, links, active states, focus rings
- Tailwind: bg-primary, text-primary, border-primary

Deep Navy (Foreground)
- Hex: #0F172A
- HSL: hsl(222, 47%, 11%)
- Usage: Main headings, primary text
- Tailwind: text-foreground

Soft Sky Blue (Accent)
- Hex: #DBEAFE
- HSL: hsl(214, 100%, 92%)
- Usage: Active navigation backgrounds, subtle highlights
- Tailwind: bg-accent, text-accent-foreground
```

### Background Colors
```css
Soft Light Gray (Background)
- Hex: #F8FAFC
- HSL: hsl(220, 20%, 98%)
- Usage: Page background
- Tailwind: bg-background

White (Card)
- Hex: #FFFFFF
- HSL: hsl(0, 0%, 100%)
- Usage: Cards, forms, modals, sidebar
- Tailwind: bg-card
```

### Text Colors
```css
Dark Navy (Primary Text)
- Hex: #0F172A
- Usage: Headings, important text
- Tailwind: text-foreground

Slate Gray (Secondary Text)
- Hex: #64748B
- HSL: hsl(215, 16%, 47%)
- Usage: Descriptions, helper text, placeholders
- Tailwind: text-muted-foreground
```

### Border & Divider
```css
Soft Gray
- Hex: #E2E8F0
- HSL: hsl(220, 13%, 91%)
- Usage: Borders, dividers, input borders
- Tailwind: border-border, border-input
```

### Status Colors
```css
Success Green
- Usage: Completed status, success messages
- Tailwind: bg-green-100 text-green-700

Warning Orange
- Usage: Warning states, notifications
- Tailwind: bg-orange-100 text-orange-700

Error Red
- Usage: Errors, destructive actions
- Tailwind: bg-destructive text-destructive-foreground

Info Blue
- Usage: Information, in-progress status
- Tailwind: bg-accent text-accent-foreground
```

---

## ðŸ“ Typography

### Font Family
```css
Primary Font: Plus Jakarta Sans
Weights: 400 (Regular), 500 (Medium), 600 (Semibold), 700 (Bold), 800 (Extrabold)
Fallbacks: -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif
```

### Typography Scale

#### Logo / Brand Name
```tsx
className="text-xl font-bold text-foreground"
// Weight: 700-800
```

#### Page Headings (H1)
```tsx
className="text-2xl md:text-3xl font-bold text-foreground"
// Weight: 700
```

#### Section Headings (H2)
```tsx
className="text-lg font-bold text-foreground"
// Weight: 700
```

#### Subsections (H3)
```tsx
className="text-base font-semibold text-foreground"
// Weight: 600
```

#### Body Text
```tsx
className="text-sm text-muted-foreground font-medium"
// Weight: 400-500
```

#### Labels
```tsx
className="text-sm font-semibold text-foreground"
// Weight: 600
```

#### Buttons
```tsx
className="text-sm font-semibold"
// Weight: 600
```

#### Table Headers
```tsx
className="text-xs uppercase font-semibold text-muted-foreground"
// Weight: 600
```

#### Helper Text
```tsx
className="text-xs text-muted-foreground font-medium"
// Weight: 400
```

---

## ðŸ§© Component Patterns

### Buttons

#### Primary Button
```tsx
<Button className="bg-primary text-primary-foreground hover:bg-primary/90">
  Primary Action
</Button>
```

#### Secondary Button
```tsx
<Button variant="secondary">
  Secondary Action
</Button>
```

#### Outline Button
```tsx
<Button variant="outline">
  Outline Action
</Button>
```

#### Destructive Button
```tsx
<Button variant="destructive">
  Delete
</Button>
```

#### Button Sizes
```tsx
<Button size="sm">Small</Button>
<Button size="default">Default</Button>
<Button size="lg">Large</Button>
<Button size="icon"><Icon /></Button>
```

### Cards

#### Standard Card
```tsx
<Card className="border shadow-sm">
  <CardHeader>
    <CardTitle className="text-lg font-bold">Title</CardTitle>
    <CardDescription>Description text</CardDescription>
  </CardHeader>
  <CardContent>
    Content goes here
  </CardContent>
</Card>
```

#### Hover Card
```tsx
<Card className="border shadow-sm hover:shadow-md hover:border-primary/20 transition-all">
  {/* Content */}
</Card>
```

### Inputs

#### Text Input
```tsx
<div className="space-y-2">
  <Label htmlFor="name" className="text-sm font-semibold">Name</Label>
  <Input 
    id="name" 
    type="text" 
    placeholder="Enter name"
    className="h-10"
  />
</div>
```

#### Input with Error
```tsx
<div className="space-y-2">
  <Label htmlFor="email" className="text-sm font-semibold text-destructive">
    Email
  </Label>
  <Input 
    id="email" 
    type="email" 
    className="h-10 border-destructive"
  />
  <p className="text-xs text-destructive">Invalid email format</p>
</div>
```

### Tables

#### Data Table
```tsx
<table className="w-full text-sm text-left">
  <thead className="text-xs text-muted-foreground uppercase bg-muted/50 border-b border-border">
    <tr>
      <th className="px-6 py-3 font-semibold">Column 1</th>
      <th className="px-6 py-3 font-semibold">Column 2</th>
    </tr>
  </thead>
  <tbody className="divide-y divide-border">
    <tr className="bg-card hover:bg-muted/30 transition-colors">
      <td className="px-6 py-4 font-semibold text-foreground">Data</td>
      <td className="px-6 py-4 text-muted-foreground">Data</td>
    </tr>
  </tbody>
</table>
```

### Badges

#### Status Badges
```tsx
// Success
<span className="px-2.5 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-700">
  Completed
</span>

// In Progress
<span className="px-2.5 py-1 text-xs font-semibold rounded-full bg-accent text-accent-foreground">
  In Progress
</span>

// Warning
<span className="px-2.5 py-1 text-xs font-semibold rounded-full bg-orange-100 text-orange-700">
  Warning
</span>

// Error
<span className="px-2.5 py-1 text-xs font-semibold rounded-full bg-red-100 text-red-700">
  Failed
</span>
```

### Navigation

#### Sidebar Item (Active)
```tsx
<Link
  href="/dashboard"
  className="flex items-center gap-3 px-3 py-2.5 rounded-lg bg-accent text-accent-foreground shadow-sm"
>
  <Icon className="w-5 h-5 shrink-0" />
  <span className="font-medium">Dashboard</span>
</Link>
```

#### Sidebar Item (Inactive)
```tsx
<Link
  href="/modules"
  className="flex items-center gap-3 px-3 py-2.5 rounded-lg text-muted-foreground hover:bg-accent/50 hover:text-accent-foreground transition-all duration-200"
>
  <Icon className="w-5 h-5 shrink-0" />
  <span className="font-medium">Modules</span>
</Link>
```

---

## ðŸ“ Spacing Scale

### Padding
```css
p-2   = 0.5rem (8px)   - Icon buttons, small elements
p-3   = 0.75rem (12px) - Navigation items, small cards
p-4   = 1rem (16px)    - Quick action cards
p-6   = 1.5rem (24px)  - Card content, card headers
p-8   = 2rem (32px)    - Main content area
```

### Gap
```css
gap-2  = 0.5rem (8px)   - Tight spacing
gap-3  = 0.75rem (12px) - Default icon-text gap
gap-4  = 1rem (16px)    - Card grid gap
gap-6  = 1.5rem (24px)  - Section spacing
```

### Margin
```css
mt-1  = 0.25rem (4px)
mt-2  = 0.5rem (8px)
mt-4  = 1rem (16px)
mt-6  = 1.5rem (24px)  - Content top margin
mb-6  = 1.5rem (24px)  - Section bottom margin
```

---

## ðŸŽ¯ Border Radius

```css
rounded-sm  = 0.125rem (2px)  - Small elements
rounded-md  = 0.375rem (6px)  - Inputs, badges
rounded-lg  = 0.5rem (8px)    - Cards, buttons (default)
rounded-xl  = 0.75rem (12px)  - Large cards, modals
rounded-2xl = 1rem (16px)     - Special cards, brand elements
rounded-full = 9999px         - Circular elements, badges
```

---

## ðŸŽ­ Shadows

### Shadow Scale
```css
shadow-sm   - Default cards, buttons
shadow      - Elevated elements
shadow-md   - Hover states, dropdowns
shadow-lg   - Modals, important overlays
shadow-xl   - Max elevation, login card
```

### Custom Shadows
```css
shadow-primary/20  - Blue-tinted shadow for primary elements
shadow-border/5    - Subtle shadow with theme color
```

---

## âš¡ Transitions

### Standard Transitions
```css
transition-colors      - Color changes
transition-all         - All properties
transition-transform   - Scale, translate effects
transition-shadow      - Shadow changes
```

### Duration
```css
duration-200  - Quick transitions (default)
duration-300  - Standard transitions
duration-500  - Slow, emphasized transitions
```

---

## ðŸŽ¨ Usage Examples

### KPI Card
```tsx
<Card className="border shadow-sm hover:shadow-md transition-all">
  <CardContent className="p-6">
    <div className="flex items-center justify-between mb-4">
      <div className="p-2.5 rounded-lg bg-accent">
        <Icon className="w-5 h-5 text-primary" />
      </div>
    </div>
    <div>
      <p className="text-sm font-medium text-muted-foreground">Total Users</p>
      <h3 className="text-2xl font-bold text-foreground mt-1">1,234</h3>
    </div>
  </CardContent>
</Card>
```

### Quick Action Card
```tsx
<Link href="/action">
  <Card className="border shadow-sm hover:shadow-md hover:border-primary/20 transition-all group cursor-pointer">
    <CardContent className="p-4 flex items-center gap-4">
      <div className="p-2.5 rounded-lg bg-accent transition-all group-hover:scale-110">
        <Icon className="w-5 h-5 text-primary" />
      </div>
      <span className="font-semibold text-foreground group-hover:text-primary transition-colors">
        Action Label
      </span>
    </CardContent>
  </Card>
</Link>
```

### Form Layout
```tsx
<form className="space-y-6">
  <div className="space-y-2">
    <Label htmlFor="field" className="text-sm font-semibold">
      Field Label
    </Label>
    <Input 
      id="field" 
      type="text" 
      placeholder="Enter value"
      className="h-10"
    />
    <p className="text-xs text-muted-foreground">Helper text</p>
  </div>
  
  <Button type="submit" className="w-full h-11 font-semibold">
    Submit
  </Button>
</form>
```

---

## ðŸ” Best Practices

### Do's âœ…
- Use semantic color classes (bg-primary, text-foreground)
- Maintain consistent spacing (p-6 for cards, gap-4 for grids)
- Use font-semibold for labels and buttons
- Apply hover states for interactive elements
- Use shadow-sm for default cards
- Include transition classes for smooth interactions

### Don'ts âŒ
- Avoid hardcoded hex colors (#0B63F6)
- Don't mix different border radius values randomly
- Avoid inconsistent font weights
- Don't use harsh shadows (shadow-2xl)
- Avoid neon or overly saturated colors
- Don't skip hover/focus states

---

## ðŸ“± Responsive Guidelines

### Mobile First Approach
```tsx
// Base styles for mobile
className="text-sm p-4"

// Tablet and up
className="text-sm md:text-base p-4 md:p-6"

// Desktop
className="text-sm md:text-base lg:text-lg p-4 md:p-6 lg:p-8"
```

### Grid Layouts
```tsx
// Responsive grid
className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4"
```

---

## ðŸš€ Quick Start

### Import Components
```tsx
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
```

### Use Semantic Colors
```tsx
// Good âœ…
<div className="bg-primary text-primary-foreground">

// Avoid âŒ
<div className="bg-blue-600 text-white">
```

### Maintain Consistency
```tsx
// Button heights: h-10 or h-11
// Input heights: h-10
// Card padding: p-6
// Grid gaps: gap-4 or gap-6
// Border radius: rounded-lg
```

---

**Version**: 1.0.0  
**Last Updated**: June 5, 2026  
**Maintained By**: ByteQuest Development Team

