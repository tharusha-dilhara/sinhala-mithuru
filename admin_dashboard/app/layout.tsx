import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Sinhala Mithuru - Admin Dashboard",
  description: "Admin control panel for Sinhala Mithuru educational platform — manage schools, teachers, classes and students.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="si" suppressHydrationWarning>
      <head>
        <link
          href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&family=Noto+Sans+Sinhala:wght@400;500;600;700&display=swap"
          rel="stylesheet"
        />
      </head>
      <body className="antialiased" suppressHydrationWarning>{children}</body>
    </html>
  );
}
