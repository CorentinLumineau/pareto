import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  // Enable Turbopack for development
  turbopack: {
    // Additional Turbopack configuration if needed
  },

  // Image optimization
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'images-eu.ssl-images-amazon.com',
      },
      {
        protocol: 'https',
        hostname: 'm.media-amazon.com',
      },
      {
        protocol: 'https',
        hostname: '*.fnac-static.com',
      },
      {
        protocol: 'https',
        hostname: '*.cdiscount.com',
      },
    ],
  },

  // Transpile workspace packages
  transpilePackages: ['@pareto/types', '@pareto/api-client', '@pareto/utils'],

  // Environment variables
  env: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:8080',
  },

  // Headers for security
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'X-Frame-Options',
            value: 'DENY',
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin',
          },
        ],
      },
    ];
  },
};

export default nextConfig;
