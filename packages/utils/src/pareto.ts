import type { ComparisonCriterion, NormalizedScores } from '@pareto/types';

/**
 * Check if a point is Pareto-dominated by another point
 * Point A dominates Point B if A is at least as good as B in all criteria
 * and strictly better in at least one criterion
 */
export function isDominated(
  pointA: NormalizedScores,
  pointB: NormalizedScores,
  criteria: ComparisonCriterion[]
): boolean {
  let strictlyBetter = false;

  for (const criterion of criteria) {
    const { attribute, direction } = criterion;
    const valueA = pointA[attribute];
    const valueB = pointB[attribute];

    if (valueA === undefined || valueB === undefined) {
      continue;
    }

    // For 'maximize': higher is better
    // For 'minimize': lower is better
    const aIsBetter =
      direction === 'maximize' ? valueA > valueB : valueA < valueB;
    const aIsWorse =
      direction === 'maximize' ? valueA < valueB : valueA > valueB;

    if (aIsWorse) {
      return false; // A cannot dominate B if A is worse in any criterion
    }

    if (aIsBetter) {
      strictlyBetter = true;
    }
  }

  return strictlyBetter;
}

/**
 * Check if a product is Pareto-optimal (not dominated by any other product)
 */
export function isParetoOptimal(
  product: NormalizedScores,
  otherProducts: NormalizedScores[],
  criteria: ComparisonCriterion[]
): boolean {
  for (const other of otherProducts) {
    if (isDominated(other, product, criteria)) {
      return false;
    }
  }
  return true;
}

/**
 * Find all Pareto-optimal products from a set
 */
export function findParetoFrontier<T extends { scores: NormalizedScores }>(
  products: T[],
  criteria: ComparisonCriterion[]
): T[] {
  const frontier: T[] = [];

  for (const product of products) {
    const isDominatedByAny = products.some(
      (other) =>
        other !== product &&
        isDominated(other.scores, product.scores, criteria)
    );

    if (!isDominatedByAny) {
      frontier.push(product);
    }
  }

  return frontier;
}

/**
 * Calculate z-score normalization for a value
 */
export function zScoreNormalize(
  value: number,
  mean: number,
  stdDev: number
): number {
  if (stdDev === 0) {
    return 0;
  }
  return (value - mean) / stdDev;
}

/**
 * Calculate min-max normalization for a value (0-1 range)
 */
export function minMaxNormalize(
  value: number,
  min: number,
  max: number
): number {
  if (max === min) {
    return 0.5;
  }
  return (value - min) / (max - min);
}

/**
 * Calculate mean of an array of numbers
 */
export function mean(values: number[]): number {
  if (values.length === 0) {
    return 0;
  }
  return values.reduce((sum, v) => sum + v, 0) / values.length;
}

/**
 * Calculate standard deviation of an array of numbers
 */
export function stdDev(values: number[]): number {
  if (values.length === 0) {
    return 0;
  }
  const avg = mean(values);
  const squaredDiffs = values.map((v) => (v - avg) ** 2);
  return Math.sqrt(mean(squaredDiffs));
}

/**
 * Normalize scores for a set of products
 */
export function normalizeScores(
  products: Array<{ id: string; rawScores: Record<string, number> }>,
  criteria: ComparisonCriterion[]
): Map<string, NormalizedScores> {
  const result = new Map<string, NormalizedScores>();

  // Calculate statistics for each attribute
  const stats = new Map<
    string,
    { values: number[]; min: number; max: number; mean: number; stdDev: number }
  >();

  for (const criterion of criteria) {
    const values = products
      .map((p) => p.rawScores[criterion.attribute])
      .filter((v): v is number => v !== undefined);

    if (values.length > 0) {
      stats.set(criterion.attribute, {
        values,
        min: Math.min(...values),
        max: Math.max(...values),
        mean: mean(values),
        stdDev: stdDev(values),
      });
    }
  }

  // Normalize each product's scores
  for (const product of products) {
    const normalized: NormalizedScores = {};

    for (const criterion of criteria) {
      const rawValue = product.rawScores[criterion.attribute];
      const stat = stats.get(criterion.attribute);

      if (rawValue !== undefined && stat) {
        // Use min-max normalization for consistent 0-1 range
        let normalizedValue = minMaxNormalize(rawValue, stat.min, stat.max);

        // If minimizing, invert the score so higher is better internally
        if (criterion.direction === 'minimize') {
          normalizedValue = 1 - normalizedValue;
        }

        // Apply weight
        normalized[criterion.attribute] = normalizedValue * criterion.weight;
      }
    }

    result.set(product.id, normalized);
  }

  return result;
}

/**
 * Calculate weighted score for a product
 */
export function calculateWeightedScore(
  scores: NormalizedScores,
  criteria: ComparisonCriterion[]
): number {
  let total = 0;
  let weightSum = 0;

  for (const criterion of criteria) {
    const score = scores[criterion.attribute];
    if (score !== undefined) {
      total += score;
      weightSum += criterion.weight;
    }
  }

  return weightSum > 0 ? total / weightSum : 0;
}
