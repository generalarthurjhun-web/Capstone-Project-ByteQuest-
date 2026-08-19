# ByteQuest Authentication System Guide

> **SUPERSEDED / HISTORICAL ONLY (2026-08-08):** The Firebase authentication design below is retired. Current Mobile and Web authentication uses the same Supabase Auth project with database-enforced roles and account states.

## 🎨 Overview

The ByteQuest authentication system features a clean, minimalist, and modern SaaS-style design with a split-screen layout that showcases computer hardware visuals on the left and authentication forms on the right.

---

## 📁 File Structure

```
src/
├── app/
│   ├── login/
│   │   └── page.tsx              # Login page
│   └── signup/
│       └── page.tsx              # Sign up page
│
├── components/
│   └── auth/
│       ├── AuthLayout.tsx        # Main layout wrapper
│       ├── AuthIllustration.tsx  # Left side 3D illustration
│       ├── AuthCard.tsx          # Card container with glow effect
│       ├── AuthBrand.tsx         # Logo and page title
│       ├── LoginForm.tsx         # Login form component
│       ├── SignUpForm.tsx        # Sign up form component
│       ├── PasswordInput.tsx     # Password field with toggle
│       ├── FormErrorMessage.tsx  # Error message display
│       └── AuthFooterLink.tsx    # Footer navigation links
│
├── lib/
│   └── validations.ts            # Form validation logic
│
└── types/
    └── auth.ts                   # TypeScript types for auth
```

---

## 🎨 Design Features

### Layout
- **Desktop**: 55% illustration / 45% form split
- **Mobile**: Stacked vertically with centered form
- **Background**: Soft light gray to pale blue gradient
- **Card**: Large rounded white card with shadow

### Color Palette
```css
Primary Blue:    #0B63F6
Dark Navy:       #0F172A
Soft Sky Blue:   #DBEAFE
Background:      #F8FAFC
Card:            #FFFFFF
Border:          #E2E8F0
Text Primary:    #0F172A
Text Secondary:  #64748B
```

### Typography
- **Font**: Plus Jakarta Sans
- **Headings**: Bold (700)
- **Labels**: Semibold (600)
- **Body**: Medium (500)
- **Buttons**: Semibold (600)

---

## 🔐 Pages

### 1. Login Page (`/login`)

**Features:**
- Email input with mail icon
- Password input with visibility toggle
- Remember me checkbox
- Forgot password link
- Sign in button with loading state
- Link to sign up page
- Security message

**Fields:**
- Email (required, validated)
- Password (required)
- Remember Me (optional)

**Validation:**
- Email format validation
- Required field checks
- Firebase authentication error handling

### 2. Sign Up Page (`/signup`)

**Features:**
- Full name input
- Email input
- Password input with visibility toggle
- Confirm password input
- Role selection dropdown (Instructor/Administrator)
- Terms agreement checkbox
- Create account button with loading state
- Link to login page
- Approval message

**Fields:**
- Full Name (required, min 2 characters)
- Email (required, validated)
- Password (required, min 6 characters)
- Confirm Password (required, must match)
- Role (required, dropdown)
- Terms Agreement (required checkbox)

**Validation:**
- All fields required
- Email format validation
- Password length check
- Password match verification
- Role selection validation
- Terms agreement check

---

## 🎯 Components

### AuthLayout
Main wrapper providing split-screen layout.

**Props:**
- `children`: Form content
- `illustration`: Left side illustration

**Responsive:**
- Desktop: Side-by-side
- Mobile: Stacked

### AuthIllustration
Left side visual section with 3D computer parts.

**Features:**
- Computer hardware image from `/Computer Parts.png`
- Decorative geometric shapes
- Dotted patterns
- Welcome message
- Blue glow effects

### AuthCard
Rounded white card with layered glow effect.

**Features:**
- Soft shadow
- Rounded corners (3xl)
- Background glow layer
- Responsive padding

### AuthBrand
Logo and page heading section.

**Props:**
- `title`: Main heading
- `subtitle`: Description text

**Features:**
- ByteQuest logo with hexagon icon
- Orange accent square
- Centered alignment

### PasswordInput
Reusable password field with visibility toggle.

**Props:**
- `id`: Field identifier
- `value`: Current value
- `onChange`: Value change handler
- `placeholder`: Placeholder text
- `error`: Error state boolean

**Features:**
- Eye/EyeOff icon toggle
- Show/hide password
- Error styling

### FormErrorMessage
Error message display component.

**Props:**
- `message`: Error text

**Features:**
- Alert icon
- Red destructive color
- Only shows when message exists

### AuthFooterLink
Bottom navigation link component.

**Props:**
- `text`: Description text
- `linkText`: Link text
- `href`: Navigation URL

---

## 🔧 Validation System

### Email Validation
```typescript
const validateEmail = (email: string): boolean => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};
```

### Password Validation
```typescript
const validatePassword = (password: string): boolean => {
  return password.length >= 6;
};
```

### Form Validation
- Checks all required fields
- Validates email format
- Validates password strength
- Confirms password match (sign up)
- Validates role selection (sign up)
- Checks terms agreement (sign up)

---

## 🔥 Firebase Integration

### Login Flow
```typescript
await signInWithEmailAndPassword(auth, email, password);
```

### Sign Up Flow
```typescript
// 1. Create Firebase user
const userCredential = await createUserWithEmailAndPassword(
  auth,
  email,
  password
);

// 2. Save user data to Firestore
await setDoc(doc(db, "users", userCredential.user.uid), {
  uid: userCredential.user.uid,
  email: email,
  displayName: fullName,
  role: role,
  status: "active",
  createdAt: Timestamp.now(),
  updatedAt: Timestamp.now(),
});
```

### Error Handling
- `auth/user-not-found` → "No account found with this email."
- `auth/wrong-password` → "Incorrect password."
- `auth/email-already-in-use` → "An account with this email already exists."
- `auth/weak-password` → "Password is too weak."
- `auth/too-many-requests` → "Too many failed attempts."

---

## 📱 Responsive Design

### Desktop (≥1024px)
- Split screen: 55% / 45%
- Full illustration visible
- Side-by-side layout

### Tablet (768px - 1023px)
- Illustration hidden
- Centered form
- Adjusted spacing

### Mobile (<768px)
- Illustration hidden
- Full-width form
- Stacked layout
- Touch-friendly inputs

---

## 🎨 Styling Details

### Input Fields
```tsx
- Height: h-11
- Border: border-border
- Focus: ring-2 ring-ring
- Icons: Left-aligned with pl-10
- Error: border-destructive
```

### Buttons
```tsx
- Height: h-11
- Font: font-semibold
- Primary: bg-primary text-primary-foreground
- Loading: Loader2 icon with animation
```

### Cards
```tsx
- Border radius: rounded-3xl
- Shadow: shadow-2xl shadow-primary/5
- Padding: p-8 md:p-10
- Background glow: blur-3xl accent/20
```

---

## 🚀 Usage

### Navigate to Login
```typescript
router.push('/login');
```

### Navigate to Sign Up
```typescript
router.push('/signup');
```

### After Successful Auth
```typescript
router.push('/dashboard');
```

---

## ✅ Features Checklist

### Login Page
- [x] Email input with icon
- [x] Password input with visibility toggle
- [x] Remember me checkbox
- [x] Forgot password link
- [x] Form validation
- [x] Firebase authentication
- [x] Loading states
- [x] Error handling
- [x] Link to sign up
- [x] Security message

### Sign Up Page
- [x] Full name input
- [x] Email input with icon
- [x] Password input with toggle
- [x] Confirm password input
- [x] Role dropdown
- [x] Terms checkbox
- [x] Form validation
- [x] Firebase authentication
- [x] Firestore data saving
- [x] Loading states
- [x] Error handling
- [x] Link to login
- [x] Approval message

### Visual Design
- [x] Split-screen layout
- [x] 3D computer illustration
- [x] Rounded white card
- [x] Soft shadows
- [x] Blue gradient effects
- [x] Decorative shapes
- [x] Welcome section
- [x] ByteQuest branding
- [x] Responsive design
- [x] Mobile optimization

---

## 🎯 Best Practices

### Component Reusability
- Separate concerns
- Reusable form components
- Consistent styling
- Type-safe props

### Validation
- Client-side validation first
- Clear error messages
- Field-specific errors
- Immediate feedback

### UX/UI
- Loading states on buttons
- Disabled state during submission
- Clear visual hierarchy
- Accessible labels and inputs
- Touch-friendly mobile design

### Security
- Password visibility toggle
- Secure Firebase auth
- Protected routes
- Input validation
- Error handling without exposing details

---

## 🔄 Flow Diagram

```
Login Page
    ↓
  Validate
    ↓
Firebase Auth
    ↓
Success → Dashboard
    ↓
  Error → Show Message


Sign Up Page
    ↓
  Validate
    ↓
Create Firebase User
    ↓
Save to Firestore
    ↓
Success → Dashboard
    ↓
  Error → Show Message
```

---

## 📝 Testing Checklist

### Manual Testing
- [ ] Login with valid credentials
- [ ] Login with invalid email
- [ ] Login with wrong password
- [ ] Sign up with all fields
- [ ] Sign up with missing fields
- [ ] Sign up with existing email
- [ ] Password visibility toggle works
- [ ] Remember me checkbox works
- [ ] Terms checkbox validation
- [ ] Password match validation
- [ ] Role selection works
- [ ] Links navigate correctly
- [ ] Loading states show
- [ ] Error messages display
- [ ] Mobile responsive
- [ ] Tablet responsive

---

## 🎨 Customization

### Change Colors
Update in `src/app/globals.css`:
```css
--primary: 217 91% 50%;  /* #0B63F6 */
```

### Change Logo
Replace hexagon icon in `AuthBrand.tsx`:
```tsx
<Hexagon className="w-7 h-7 text-white fill-white" />
```

### Change Illustration
Replace image path in `AuthIllustration.tsx`:
```tsx
src="/Computer Parts.png"
```

### Adjust Layout Ratio
Modify in `AuthLayout.tsx`:
```tsx
lg:w-[55%]  // Left side
lg:w-[45%]  // Right side
```

---

## 🐛 Troubleshooting

### Image Not Loading
- Check if `/Computer Parts.png` exists in `public/` folder
- Verify image file name and extension
- Clear Next.js cache: `rm -rf .next`

### Firebase Errors
- Verify `.env.local` configuration
- Check Firebase project settings
- Enable Email/Password auth in Firebase Console
- Create Firestore database

### Styling Issues
- Clear browser cache
- Rebuild project: `pnpm run build`
- Check Tailwind configuration
- Verify Plus Jakarta Sans font loading

---

## 📚 Resources

- [Next.js Documentation](https://nextjs.org/docs)
- [Firebase Auth](https://firebase.google.com/docs/auth)
- [Tailwind CSS](https://tailwindcss.com/docs)
- [shadcn/ui](https://ui.shadcn.com)
- [Lucide Icons](https://lucide.dev)

---

**Created**: June 5, 2026  
**Version**: 1.0.0  
**Status**: Production Ready
