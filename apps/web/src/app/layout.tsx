import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';
import { Providers } from './providers';

const inter = Inter({
  subsets: ['latin'],
  variable: '--font-inter',
});

export const metadata: Metadata = {
  title: {
    default: 'Pareto Comparateur - Trouvez les meilleurs produits',
    template: '%s | Pareto Comparateur',
  },
  description:
    'Comparez les smartphones avec l\'optimisation Pareto. Trouvez le meilleur compromis entre prix, performance et qualité parmi les offres Amazon, Fnac, Cdiscount et plus.',
  keywords: [
    'comparateur',
    'prix',
    'smartphone',
    'Pareto',
    'France',
    'Amazon',
    'Fnac',
    'Cdiscount',
  ],
  authors: [{ name: 'Pareto Comparateur' }],
  robots: {
    index: true,
    follow: true,
  },
  openGraph: {
    type: 'website',
    locale: 'fr_FR',
    siteName: 'Pareto Comparateur',
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="fr" className={inter.variable}>
      <body className="min-h-screen bg-background antialiased">
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
