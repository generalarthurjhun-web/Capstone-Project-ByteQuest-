export interface LoginFormData {
  email: string;
  password: string;
  rememberMe: boolean;
}

export interface SignUpFormData {
  fullName: string;
  email: string;
  password: string;
  confirmPassword: string;
  agreedToTerms: boolean;
}

export interface AuthError {
  field?: string;
  message: string;
}

export type UserRole = "learner" | "instructor" | "admin";
export type AccountStatus =
  | "active"
  | "inactive"
  | "deactivated"
  | "pending"
  | "suspended";

export interface AppProfile {
  id: string;
  userId: string;
  fullName: string;
  email: string;
  avatarUrl: string | null;
  role: UserRole;
  status: AccountStatus;
  createdAt: string;
  updatedAt: string;
  deactivatedAt: string | null;
  deactivationReason: string | null;
}
