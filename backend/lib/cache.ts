import NodeCache from 'node-cache';

// Next.js hot-reloading workaround to prevent multiple cache instances in development
const globalForCache = global as unknown as { cache: NodeCache };

export const cache = globalForCache.cache || new NodeCache({
  stdTTL: 900, // 15 minutes default TTL
  checkperiod: 120 // prune expired keys every 2 minutes
});

if (process.env.NODE_ENV !== 'production') {
  globalForCache.cache = cache;
}

export function getCacheStats() {
  return cache.getStats();
}
