import { LoginFormData, SignUpFormData, AuthError } from "@/types/auth";

export const validateEmail = (email: string): boolean => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

export const validatePassword = (password: string): boolean => {
  return password.length >= 6;
};

export const validateLoginForm = (data: LoginFormData): AuthError | null => {
  if (!data.email.trim()) {
    return { field: 'email', message: 'Email is required' };
  }
  
  if (!validateEmail(data.email)) {
    return { field: 'email', message: 'Please enter a valid email address' };
  }
  
  if (!data.password) {
    return { field: 'password', message: 'Password is required' };
  }
  
  return null;
};

export const validateSignUpForm = (data: SignUpFormData): AuthError | null => {
  if (!data.fullName.trim()) {
    return { field: 'fullName', message: 'Full name is required' };
  }
  
  if (data.fullName.trim().length < 2) {
    return { field: 'fullName', message: 'Full name must be at least 2 characters' };
  }
  
  if (!data.email.trim()) {
    return { field: 'email', message: 'Email is required' };
  }
  
  if (!validateEmail(data.email)) {
    return { field: 'email', message: 'Please enter a valid email address' };
  }
  
  if (!data.password) {
    return { field: 'password', message: 'Password is required' };
  }
  
  if (!validatePassword(data.password)) {
    return { field: 'password', message: 'Password must be at least 6 characters' };
  }
  
  if (!data.confirmPassword) {
    return { field: 'confirmPassword', message: 'Please confirm your password' };
  }
  
  if (data.password !== data.confirmPassword) {
    return { field: 'confirmPassword', message: 'Passwords do not match' };
  }
  
  if (!data.agreedToTerms) {
    return { field: 'agreedToTerms', message: 'You must agree to the terms and privacy policy' };
  }
  
  return null;
};
