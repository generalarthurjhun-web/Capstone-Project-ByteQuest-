import { AuthLayout } from "@/components/auth/AuthLayout";
import { AuthCard } from "@/components/auth/AuthCard";
import { AuthBrand } from "@/components/auth/AuthBrand";
import { LoginForm } from "@/components/auth/LoginForm";
import { LoginIllustration } from "@/components/auth/LoginIllustration";

export default function LoginPage() {
  return (
    <AuthLayout illustration={<LoginIllustration />} light>
      <AuthCard compact>
        <AuthBrand
          title="Sign in to ByteQuest"
          subtitle="Secure access for Instructor and Admin accounts"
          centered
        />
        <LoginForm />
      </AuthCard>
    </AuthLayout>
  );
}
