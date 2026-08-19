import { AuthLayout } from "@/components/auth/AuthLayout";
import { AuthIllustration } from "@/components/auth/AuthIllustration";
import { AuthCard } from "@/components/auth/AuthCard";
import { AuthBrand } from "@/components/auth/AuthBrand";
import { SignUpForm } from "@/components/auth/SignUpForm";

export default function SignUpPage() {
  return (
    <AuthLayout illustration={<AuthIllustration />}>
      <AuthCard>
        <AuthBrand
          title="Staff account access"
          subtitle="Dashboard accounts are created by an authorized Admin"
        />
        <SignUpForm />
      </AuthCard>
    </AuthLayout>
  );
}
