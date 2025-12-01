import { View, Text, Pressable, ScrollView } from 'react-native';
import { Link } from 'expo-router';

export default function HomeScreen() {
  return (
    <ScrollView className="flex-1 bg-white">
      {/* Hero Section */}
      <View className="bg-primary-50 px-6 py-12">
        <Text className="mb-4 text-center text-3xl font-bold text-gray-900">
          Trouvez le{' '}
          <Text className="text-primary-600">meilleur compromis</Text>
        </Text>
        <Text className="mb-8 text-center text-lg text-gray-600">
          Comparez les smartphones avec l'optimisation Pareto
        </Text>

        <Link href="/compare" asChild>
          <Pressable className="rounded-lg bg-primary-600 px-6 py-4">
            <Text className="text-center text-lg font-semibold text-white">
              Comparer les smartphones
            </Text>
          </Pressable>
        </Link>
      </View>

      {/* Features */}
      <View className="px-6 py-8">
        <Text className="mb-6 text-center text-2xl font-bold text-gray-900">
          Pourquoi Pareto ?
        </Text>

        <FeatureCard
          icon="⚖️"
          title="Optimisation Pareto"
          description="Trouvez les produits optimaux selon vos critères"
        />
        <FeatureCard
          icon="🏪"
          title="6 Marchands"
          description="Amazon, Fnac, Cdiscount, Darty, Boulanger, LDLC"
        />
        <FeatureCard
          icon="🎯"
          title="Vos Priorités"
          description="Ajustez l'importance de chaque critère"
        />
      </View>
    </ScrollView>
  );
}

function FeatureCard({
  icon,
  title,
  description,
}: {
  icon: string;
  title: string;
  description: string;
}) {
  return (
    <View className="mb-4 rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
      <Text className="mb-2 text-3xl">{icon}</Text>
      <Text className="mb-1 text-lg font-semibold text-gray-900">{title}</Text>
      <Text className="text-gray-600">{description}</Text>
    </View>
  );
}
