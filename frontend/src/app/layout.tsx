import type { Metadata } from "next";
import { Outfit, Source_Sans_3 } from "next/font/google";
import { ClientLayout } from "./ClientLayout";
import "./globals.css";

const outfit = Outfit({
  subsets: ["latin"],
  variable: "--font-outfit",
  display: "swap",
});

const sourceSans = Source_Sans_3({
  subsets: ["latin"],
  variable: "--font-source-sans",
  display: "swap",
});

export const metadata: Metadata = {
  title: "MerchantHub AI",
  description: "Merchant Engagement Platform with AI-powered review analysis",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${outfit.variable} ${sourceSans.variable}`} suppressHydrationWarning>
      <body className="font-sans">
        <ClientLayout>{children}</ClientLayout>
      </body>
    </html>
  );
}
