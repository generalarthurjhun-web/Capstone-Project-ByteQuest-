import React from "react";
import Link from "next/link";

interface AuthFooterLinkProps {
  text: string;
  linkText: string;
  href: string;
}

export function AuthFooterLink({ text, linkText, href }: AuthFooterLinkProps) {
  return (
    <div className="text-center text-sm">
      <span className="text-muted-foreground font-medium">{text}</span>{" "}
      <Link 
        href={href}
        prefetch={true}
        className="text-primary font-semibold hover:underline transition-colors"
      >
        {linkText}
      </Link>
    </div>
  );
}
