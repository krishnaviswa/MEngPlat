import type { Metadata } from "next";
import { ClientLayout } from "./ClientLayout";
import "./globals.css";

export const metadata: Metadata = {
  title: "MerchantHub AI",
  description: "Merchant Engagement Platform with AI-powered review analysis",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <ClientLayout>{children}</ClientLayout>
      </body>
    </html>
  );
}
