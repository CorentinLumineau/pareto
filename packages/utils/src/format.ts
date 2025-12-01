/**
 * Format a price in EUR for French locale
 */
export function formatPrice(
  amount: number,
  locale = 'fr-FR',
  currency = 'EUR'
): string {
  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency,
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount);
}

/**
 * Format a price range
 */
export function formatPriceRange(
  min: number,
  max: number,
  locale = 'fr-FR',
  currency = 'EUR'
): string {
  if (min === max) {
    return formatPrice(min, locale, currency);
  }
  return `${formatPrice(min, locale, currency)} - ${formatPrice(max, locale, currency)}`;
}

/**
 * Format a date for French locale
 */
export function formatDate(
  date: Date | string,
  locale = 'fr-FR',
  options?: Intl.DateTimeFormatOptions
): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  return d.toLocaleDateString(locale, options ?? {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });
}

/**
 * Format a date with time for French locale
 */
export function formatDateTime(
  date: Date | string,
  locale = 'fr-FR'
): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  return d.toLocaleString(locale, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

/**
 * Format relative time (e.g., "il y a 2 heures")
 */
export function formatRelativeTime(
  date: Date | string,
  locale = 'fr-FR'
): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  const now = new Date();
  const diffMs = now.getTime() - d.getTime();
  const diffSec = Math.floor(diffMs / 1000);
  const diffMin = Math.floor(diffSec / 60);
  const diffHour = Math.floor(diffMin / 60);
  const diffDay = Math.floor(diffHour / 24);

  const rtf = new Intl.RelativeTimeFormat(locale, { numeric: 'auto' });

  if (diffSec < 60) {
    return rtf.format(-diffSec, 'second');
  }
  if (diffMin < 60) {
    return rtf.format(-diffMin, 'minute');
  }
  if (diffHour < 24) {
    return rtf.format(-diffHour, 'hour');
  }
  if (diffDay < 30) {
    return rtf.format(-diffDay, 'day');
  }

  return formatDate(d, locale);
}

/**
 * Format a percentage
 */
export function formatPercentage(
  value: number,
  locale = 'fr-FR',
  decimals = 0
): string {
  return new Intl.NumberFormat(locale, {
    style: 'percent',
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  }).format(value / 100);
}

/**
 * Format a number with French locale
 */
export function formatNumber(
  value: number,
  locale = 'fr-FR',
  decimals?: number
): string {
  return new Intl.NumberFormat(locale, {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  }).format(value);
}

/**
 * Create a URL-friendly slug from text
 */
export function slugify(text: string): string {
  return text
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '') // Remove diacritics
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .replace(/-+/g, '-');
}

/**
 * Truncate text with ellipsis
 */
export function truncate(text: string, maxLength: number): string {
  if (text.length <= maxLength) {
    return text;
  }
  return `${text.slice(0, maxLength - 3)}...`;
}
