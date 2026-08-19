import React from "react";
import { AlertCircle } from "lucide-react";

interface FormErrorMessageProps {
  message?: string;
}

export function FormErrorMessage({ message }: FormErrorMessageProps) {
  if (!message) return null;

  return (
    <div className="mt-1.5 flex items-center gap-2 text-xs font-medium text-destructive">
      <AlertCircle className="h-3.5 w-3.5" aria-hidden="true" />
      <span>{message}</span>
    </div>
  );
}
