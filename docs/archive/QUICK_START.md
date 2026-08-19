# ByteQuest Web Dashboard - Quick Start Guide

> **SUPERSEDED / HISTORICAL ONLY (2026-08-08):** This document describes the retired Firebase/mock architecture. Do not follow its setup steps. Supabase is the shared production identity/data authority; use the current checkpoint and acceptance reports instead.

## 🚀 Getting Started

### Installation

1. **Install Dependencies**
   ```bash
   pnpm install
   ```

2. **Set Up Environment Variables**
   Create a `.env.local` file in the root directory:
   ```env
   NEXT_PUBLIC_FIREBASE_API_KEY=your_api_key
   NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=your_auth_domain
   NEXT_PUBLIC_FIREBASE_PROJECT_ID=your_project_id
   NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=your_storage_bucket
   NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=your_sender_id
   NEXT_PUBLIC_FIREBASE_APP_ID=your_app_id
   ```

3. **Run Development Server**
   ```bash
   pnpm run dev
   ```

4. **Build for Production**
   ```bash
   pnpm run build
   pnpm run start
   ```

---

## 🎨 What's New

### ✅ Implemented Updates

1. **Font System**
   - ✅ Plus Jakarta Sans applied globally
   - ✅ Proper font weights configured (400, 500, 600, 700, 800)
   - ✅ Fallback fonts added for better compatibility

2. **Color Theme**
   - ✅ ByteQuest Electric Blue (#0B63F6) as primary
   - ✅ Soft Light Gray background (#F8FAFC)
   - ✅ Semantic color tokens throughout
   - ✅ Dark mode colors defined (ready to activate)

3. **Component Updates**
   - ✅ All layout components updated
   - ✅ Dashboard page fully themed
   - ✅ Login page modernized
   - ✅ Modules page updated
   - ✅ Users page updated
   - ✅ All UI components enhanced

4. **Typography**
   - ✅ Consistent font hierarchy
   - ✅ Improved font weights
   - ✅ Better readability

5. **UI/UX Improvements**
   - ✅ Clean, minimalist design
   - ✅ Modern SaaS aesthetic
   - ✅ Better hover states
   - ✅ Enhanced focus states
   - ✅ Improved spacing
   - ✅ Consistent styling

---

## 📁 Project Structure

```
ByteQuest Web/
├── src/
│   ├── app/                      # Next.js App Router pages
│   │   ├── layout.tsx            # ✅ Updated with Plus Jakarta Sans
│   │   ├── globals.css           # ✅ Updated with new color theme
│   │   ├── page.tsx              # Landing page
│   │   ├── login/                # ✅ Updated
│   │   ├── dashboard/            # ✅ Updated
│   │   ├── modules/              # ✅ Updated
│   │   ├── users/                # ✅ Updated
│   │   ├── scenarios/
│   │   ├── competencies/
│   │   ├── assessment-criteria/
│   │   ├── progress/
│   │   ├── analytics/
│   │   ├── reports/
│   │   ├── leaderboard/
│   │   ├── profile/
│   │   ├── settings/
│   │   └── logs/
│   │
│   ├── components/
│   │   ├── auth/                 # ✅ Updated
│   │   │   └── protected-route.tsx
│   │   ├── layout/               # ✅ Updated
│   │   │   ├── dashboard-layout.tsx
│   │   │   ├── sidebar.tsx
│   │   │   ├── topbar.tsx
│   │   │   └── breadcrumbs.tsx
│   │   └── ui/                   # ✅ Updated
│   │       ├── button.tsx
│   │       ├── input.tsx
│   │       ├── card.tsx
│   │       ├── label.tsx
│   │       ├── skeleton.tsx
│   │       ├── badge.tsx
│   │       └── ... (other shadcn components)
│   │
│   ├── hooks/
│   │   ├── use-auth.tsx          # Authentication hook
│   │   └── use-mobile.tsx        # Responsive hook
│   │
│   ├── lib/
│   │   ├── firebase.ts           # Firebase configuration
│   │   └── utils.ts              # Utility functions
│   │
│   ├── services/
│   │   └── firebase.service.ts   # Firebase CRUD operations
│   │
│   └── types/
│       └── index.ts              # TypeScript type definitions
│
├── public/                       # Static assets
├── tailwind.config.ts            # ✅ Updated with font config
├── package.json                  # Dependencies
└── next.config.ts                # Next.js configuration
```

---

## 🎨 Using the Design System

### Colors

Always use semantic color classes:

```tsx
// ✅ Good
<div className="bg-primary text-primary-foreground">

// ❌ Avoid
<div className="bg-blue-600 text-white">
```

### Semantic Color Reference

```tsx
bg-background          // #F8FAFC - Page background
bg-card                // #FFFFFF - Cards, modals
bg-primary             // #0B63F6 - Primary actions
bg-accent              // #DBEAFE - Soft highlights
bg-muted               // #E2E8F0 - Subtle backgrounds

text-foreground        // #0F172A - Main text
text-muted-foreground  // #64748B - Secondary text
text-primary           // #0B63F6 - Links, active states

border-border          // #E2E8F0 - Borders, dividers
```

### Typography

```tsx
// Page Heading
<h1 className="text-2xl md:text-3xl font-bold text-foreground">

// Section Heading
<h2 className="text-lg font-bold text-foreground">

// Body Text
<p className="text-sm text-muted-foreground font-medium">

// Labels
<label className="text-sm font-semibold text-foreground">
```

### Components

```tsx
// Button
<Button>Primary Action</Button>
<Button variant="outline">Secondary</Button>
<Button variant="destructive">Delete</Button>

// Input
<Input className="h-10" placeholder="Enter text..." />

// Card
<Card className="border shadow-sm">
  <CardHeader>
    <CardTitle className="text-lg font-bold">Title</CardTitle>
  </CardHeader>
  <CardContent>Content</CardContent>
</Card>
```

---

## 🔐 Authentication

### Login Credentials

For development/testing, you'll need to set up Firebase Authentication users.

**Default Roles:**
- `admin` - Full system access
- `instructor` - Course management access
- `learner` - Cannot access web dashboard (mobile app only)

### Protected Routes

All dashboard routes are automatically protected by the `ProtectedRoute` component.

```tsx
// Already implemented in DashboardLayout
<ProtectedRoute>
  {/* Your protected content */}
</ProtectedRoute>
```

---

## 📊 Firebase Setup

### Required Collections

1. **users** - User accounts and profiles
2. **modules** - Learning modules
3. **scenarios** - Simulation scenarios
4. **competencies** - Competency standards
5. **progress** - Learner progress tracking
6. **logs** - System activity logs
7. **assessment-criteria** - Assessment rubrics

### Firestore Rules (Example)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Only authenticated users
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 🛠️ Common Tasks

### Adding a New Page

1. Create page file in `src/app/your-page/page.tsx`
2. Wrap with `DashboardLayout`
3. Add navigation item to sidebar (`src/components/layout/sidebar.tsx`)

```tsx
// src/app/your-page/page.tsx
"use client";

import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export default function YourPage() {
  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl md:text-3xl font-bold text-foreground">
            Page Title
          </h1>
          <p className="text-muted-foreground mt-1 font-medium">
            Page description
          </p>
        </div>

        <Card className="border shadow-sm">
          <CardHeader>
            <CardTitle>Card Title</CardTitle>
          </CardHeader>
          <CardContent>
            {/* Your content */}
          </CardContent>
        </Card>
      </div>
    </DashboardLayout>
  );
}
```

### Adding a New Component

1. Create component in appropriate directory
2. Follow naming conventions (PascalCase)
3. Use TypeScript for type safety
4. Apply semantic color classes

```tsx
// src/components/your-component.tsx
interface YourComponentProps {
  title: string;
  description?: string;
}

export function YourComponent({ title, description }: YourComponentProps) {
  return (
    <div className="p-6 border border-border rounded-lg">
      <h3 className="font-bold text-foreground">{title}</h3>
      {description && (
        <p className="text-sm text-muted-foreground mt-1">{description}</p>
      )}
    </div>
  );
}
```

### Creating a Form

```tsx
"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export function YourForm() {
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    
    try {
      // Your submit logic
    } catch (error) {
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Card className="border shadow-sm">
      <CardHeader>
        <CardTitle className="text-lg font-bold">Form Title</CardTitle>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="space-y-2">
            <Label htmlFor="field" className="text-sm font-semibold">
              Field Label
            </Label>
            <Input
              id="field"
              type="text"
              placeholder="Enter value"
              className="h-10"
              required
            />
          </div>

          <Button type="submit" className="w-full h-11" disabled={loading}>
            {loading ? "Submitting..." : "Submit"}
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}
```

---

## 🐛 Troubleshooting

### Font Not Loading

1. Check if Next.js is running in development mode
2. Clear browser cache
3. Verify `layout.tsx` imports Plus Jakarta Sans correctly
4. Check browser DevTools → Network tab for font loading

### Colors Not Applying

1. Check if CSS variables are defined in `globals.css`
2. Verify Tailwind is processing the classes
3. Clear `.next` cache and rebuild: `rm -rf .next && pnpm run dev`
4. Check browser DevTools → Elements tab for applied classes

### Build Errors

```bash
# Clear cache and rebuild
rm -rf .next
rm -rf node_modules
pnpm install
pnpm run build
```

### TypeScript Errors

```bash
# Check for errors
pnpm run lint

# If needed, regenerate types
rm -rf .next
pnpm run dev
```

---

## 📖 Additional Resources

- **Design System**: See `DESIGN_SYSTEM.md` for complete design guidelines
- **Updates Summary**: See `UPDATES_SUMMARY.md` for detailed changelog
- **Next.js Docs**: https://nextjs.org/docs
- **Tailwind CSS**: https://tailwindcss.com/docs
- **shadcn/ui**: https://ui.shadcn.com
- **Firebase**: https://firebase.google.com/docs

---

## ✅ Checklist for New Developers

- [ ] Clone repository
- [ ] Install dependencies (`pnpm install`)
- [ ] Set up `.env.local` with Firebase credentials
- [ ] Run development server (`pnpm run dev`)
- [ ] Review `DESIGN_SYSTEM.md`
- [ ] Review existing pages for patterns
- [ ] Test authentication flow
- [ ] Explore the dashboard
- [ ] Check responsive layout on mobile

---

## 🤝 Contributing

When adding new features:

1. Follow the established design system
2. Use semantic color classes
3. Maintain consistent spacing
4. Apply proper TypeScript types
5. Test responsive layouts
6. Check for accessibility
7. Update documentation if needed

---

## 📝 Notes

- **Font**: Plus Jakarta Sans is now the primary font
- **Colors**: Use semantic tokens, not hardcoded colors
- **Spacing**: Follow the established spacing scale
- **Components**: Reuse existing UI components
- **TypeScript**: All components should be properly typed
- **Responsive**: All pages should work on mobile, tablet, and desktop

---

**Version**: 1.0.0  
**Last Updated**: June 5, 2026  
**Need Help?** Check `UPDATES_SUMMARY.md` or `DESIGN_SYSTEM.md`
