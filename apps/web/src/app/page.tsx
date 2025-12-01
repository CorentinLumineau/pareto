import Link from 'next/link';

export default function HomePage() {
  return (
    <main className="flex min-h-screen flex-col">
      {/* Hero Section */}
      <section className="flex flex-1 flex-col items-center justify-center bg-gradient-to-b from-primary-50 to-white px-4 py-20">
        <h1 className="mb-6 text-center text-5xl font-bold text-gray-900">
          Trouvez le{' '}
          <span className="text-primary-600">meilleur compromis</span>
        </h1>
        <p className="mb-8 max-w-2xl text-center text-xl text-gray-600">
          Comparez les smartphones avec l'optimisation Pareto. Pas seulement le
          moins cher, mais le meilleur rapport qualité-prix selon{' '}
          <strong>vos</strong> critères.
        </p>

        <div className="flex gap-4">
          <Link
            href="/compare/smartphones"
            className="rounded-lg bg-primary-600 px-8 py-3 font-semibold text-white transition hover:bg-primary-700"
          >
            Comparer les smartphones
          </Link>
          <Link
            href="/about"
            className="rounded-lg border border-gray-300 bg-white px-8 py-3 font-semibold text-gray-700 transition hover:bg-gray-50"
          >
            Comment ça marche ?
          </Link>
        </div>
      </section>

      {/* Features Section */}
      <section className="bg-white px-4 py-20">
        <div className="mx-auto max-w-6xl">
          <h2 className="mb-12 text-center text-3xl font-bold text-gray-900">
            Pourquoi Pareto Comparateur ?
          </h2>

          <div className="grid gap-8 md:grid-cols-3">
            <FeatureCard
              title="Optimisation Pareto"
              description="Trouvez les produits qui ne sont battus par aucun autre sur TOUS vos critères. La science au service de vos achats."
              icon="⚖️"
            />
            <FeatureCard
              title="6 Marchands"
              description="Amazon, Fnac, Cdiscount, Darty, Boulanger, LDLC. Les prix les plus récents de France."
              icon="🏪"
            />
            <FeatureCard
              title="Vos Priorités"
              description="Prix, batterie, appareil photo, stockage... Ajustez l'importance de chaque critère selon vos besoins."
              icon="🎯"
            />
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t bg-gray-50 px-4 py-8">
        <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-4 text-sm text-gray-600 md:flex-row">
          <p>&copy; 2025 Pareto Comparateur. Tous droits réservés.</p>
          <div className="flex gap-6">
            <Link href="/transparence" className="hover:text-primary-600">
              Transparence
            </Link>
            <Link href="/mentions-legales" className="hover:text-primary-600">
              Mentions légales
            </Link>
            <Link href="/confidentialite" className="hover:text-primary-600">
              Confidentialité
            </Link>
          </div>
        </div>
      </footer>
    </main>
  );
}

function FeatureCard({
  title,
  description,
  icon,
}: {
  title: string;
  description: string;
  icon: string;
}) {
  return (
    <div className="rounded-xl border bg-white p-6 shadow-sm transition hover:shadow-md">
      <div className="mb-4 text-4xl">{icon}</div>
      <h3 className="mb-2 text-xl font-semibold text-gray-900">{title}</h3>
      <p className="text-gray-600">{description}</p>
    </div>
  );
}
