import type { Metadata } from "next";
import { Inter } from "next/font/google";
import { ClientLayout } from "./ClientLayout";
import "./globals.css";

const inter = Inter({ subsets: ["latin"], variable: "--font-inter" });

export const metadata: Metadata = {
  title: "MerchantHub AI",
  description: "Merchant Engagement Platform with AI-powered review analysis",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={inter.variable}>
      <body className="font-sans">
        <ClientLayout>{children}</ClientLayout>
      </body>
    </html>
  );
}
