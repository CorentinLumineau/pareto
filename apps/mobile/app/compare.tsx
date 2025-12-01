import { View, Text, ScrollView, ActivityIndicator } from 'react-native';
import { useProducts } from '@pareto/api-client';

export default function CompareScreen() {
  const { data, isLoading, error } = useProducts();

  if (isLoading) {
    return (
      <View className="flex-1 items-center justify-center bg-white">
        <ActivityIndicator size="large" color="#0ea5e9" />
        <Text className="mt-4 text-gray-600">Chargement des produits...</Text>
      </View>
    );
  }

  if (error) {
    return (
      <View className="flex-1 items-center justify-center bg-white px-6">
        <Text className="mb-2 text-xl font-bold text-red-600">Erreur</Text>
        <Text className="text-center text-gray-600">
          Impossible de charger les produits. Vérifiez votre connexion.
        </Text>
      </View>
    );
  }

  const products = data?.items ?? [];

  return (
    <ScrollView className="flex-1 bg-gray-50">
      <View className="p-4">
        <Text className="mb-4 text-xl font-bold text-gray-900">
          Smartphones ({products.length})
        </Text>

        {products.length === 0 ? (
          <View className="rounded-xl bg-white p-6">
            <Text className="text-center text-gray-600">
              Aucun produit trouvé. Les données seront bientôt disponibles.
            </Text>
          </View>
        ) : (
          products.map((product) => (
            <ProductCard key={product.id} product={product} />
          ))
        )}
      </View>
    </ScrollView>
  );
}

function ProductCard({ product }: { product: { id: string; name: string; bestPrice?: number | null } }) {
  return (
    <View className="mb-3 rounded-xl bg-white p-4 shadow-sm">
      <Text className="text-lg font-semibold text-gray-900">
        {product.name}
      </Text>
      {product.bestPrice && (
        <Text className="mt-1 text-primary-600">
          {new Intl.NumberFormat('fr-FR', {
            style: 'currency',
            currency: 'EUR',
          }).format(product.bestPrice)}
        </Text>
      )}
    </View>
  );
}
