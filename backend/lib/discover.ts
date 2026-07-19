import { fetchCategoryNews } from './rss';
import { cache } from './cache';
import { Article } from './types';
import { categoryFeeds } from './feeds';
import { NextResponse } from 'next/server';
import { db } from './firebase';

// Fetch all articles across all RSS feeds, cached for 5 minutes
export async function getAllDiscoverArticles(): Promise<Article[]> {
  const cacheKey = 'discover_all_articles';
  let cached = cache.get<Article[]>(cacheKey);
  if (cached) return cached;

  let articles: Article[] = [];

  // 1. Try Firestore First (Cache-First Spark Tier Optimization)
  if (db) {
    try {
      const snapshot = await db.collection('articles')
        .orderBy('publishedAt', 'desc')
        .limit(200)
        .get();

      if (!snapshot.empty) {
        snapshot.forEach((doc: any) => {
          const data = doc.data();
          articles.push({
            title: data.title || '',
            description: data.description || '',
            summary: data.summary || '',
            url: data.url || '',
            canonical_url: data.canonical_url || '',
            image: data.image || '',
            author: data.author || 'Staff',
            source: data.source || 'News',
            publishedAt: data.publishedAt || '',
            category: data.category || 'general',
            tags: data.tags || [],
          });
        });
        console.log(`Loaded ${articles.length} articles from Firestore.`);
      }
    } catch (err) {
      console.error('Failed to read from Firestore, falling back to RSS:', err);
    }
  }

  // 2. Fallback to RSS Feeds if Firestore is empty or unavailable
  if (articles.length === 0) {
    const categories = Object.keys(categoryFeeds);
    const results = await Promise.all(
      categories.map(async (cat) => {
        try {
          const catKey = `category_${cat}`;
          let cachedCat = cache.get<Article[]>(catKey);
          if (!cachedCat) {
            cachedCat = await fetchCategoryNews(cat);
            cache.set(catKey, cachedCat, 900); // 15 minutes cache for individual feeds
          }
          return cachedCat;
        } catch (err) {
          console.error(`Error loading category ${cat} for discover:`, err);
          return [];
        }
      })
    );
    articles = results.flat();
  }

  // Deduplicate by URL
  const seen = new Set<string>();
  const deduped = articles.filter(a => {
    if (!a.url || seen.has(a.url)) return false;
    seen.add(a.url);
    return true;
  });

  // Sort globally by publication date descending
  deduped.sort((a, b) => {
    const timeA = a.publishedAt ? new Date(a.publishedAt).getTime() : 0;
    const timeB = b.publishedAt ? new Date(b.publishedAt).getTime() : 0;
    return timeB - timeA;
  });

  cache.set(cacheKey, deduped, 300); // 5 minutes global cache
  return deduped;
}

// Normalized response builder
export interface DiscoverResponseOptions {
  page?: number;
  limit?: number;
  total?: number;
  lastUpdated?: string;
  cached?: boolean;
}

export function createDiscoverResponse<T>(
  data: T[],
  options: DiscoverResponseOptions = {}
) {
  const page = options.page ?? 1;
  const limit = options.limit ?? 20;
  
  const startIndex = (page - 1) * limit;
  const endIndex = page * limit;
  const slicedData = data.slice(startIndex, endIndex);
  const hasNext = endIndex < data.length;
  
  const expiresAt = new Date(Date.now() + 300 * 1000).toISOString();

  return NextResponse.json({
    success: true,
    data: slicedData,
    pagination: {
      page,
      limit,
      hasNext,
      nextPage: hasNext ? page + 1 : null,
    },
    metadata: {
      lastUpdated: options.lastUpdated ?? new Date().toISOString(),
      totalItems: data.length,
    },
    cache: {
      cached: options.cached ?? true,
      expiresAt,
    },
  });
}

// Topic Definitions
export interface Topic {
  name: string;
  keywords: string[];
  description: string;
}

export const TOPICS_LIST: Topic[] = [
  { name: 'Technology', keywords: ['tech', 'software', 'ai', 'artificial intelligence', 'apple', 'google', 'microsoft', 'app', 'gadget'], description: 'Computing, mobile devices, and artificial intelligence.' },
  { name: 'Space', keywords: ['space', 'isro', 'nasa', 'moon', 'lunar', 'satellite', 'rocket', 'orbit', 'mars'], description: 'Space exploration, astronomy, and cosmic events.' },
  { name: 'Cricket', keywords: ['cricket', 'ipl', 't20', 'dhoni', 'kohli', 'bcci', 'test match', 'wicket'], description: 'Recent tournaments, matches, and team news.' },
  { name: 'Business', keywords: ['business', 'sensex', 'market', 'stock', 'finance', 'economy', 'inflation', 'trade'], description: 'Global and domestic financial markets and economic updates.' },
  { name: 'Politics', keywords: ['politics', 'election', 'minister', 'government', 'modi', 'bjp', 'congress', 'parliament'], description: 'Political policies, legislative events, and elections.' },
  { name: 'Science', keywords: ['science', 'physics', 'chemistry', 'research', 'scientific', 'dna', 'lab', 'climatology'], description: 'New discoveries, laboratory research, and environmental studies.' },
  { name: 'Health', keywords: ['health', 'medical', 'virus', 'vaccine', 'disease', 'hospital', 'doctor', 'treatment'], description: 'Public health, clinical trials, and medical breakthroughs.' },
  { name: 'Entertainment', keywords: ['entertainment', 'movie', 'actor', 'film', 'netflix', 'showbiz', 'hollywood', 'bollywood'], description: 'Cinema, streaming services, celebrities, and pop culture.' },
  { name: 'Startups', keywords: ['startup', 'founder', 'funding', 'venture capital', 'seed round', 'unicorn', 'investor'], description: 'Entrepreneurship, tech funding rounds, and new enterprises.' },
];

// Region Definitions
export interface Region {
  name: string;
  countries: string[];
}

export const REGIONS_LIST: Region[] = [
  { name: 'India', countries: ['india', 'delhi', 'mumbai', 'bangalore', 'chennai', 'modi', 'isro', 'bjp'] },
  { name: 'World', countries: ['world', 'international', 'global', 'un', 'foreign'] },
  { name: 'North America', countries: ['us', 'usa', 'america', 'washington', 'biden', 'trump', 'canada', 'new york'] },
  { name: 'Europe', countries: ['uk', 'europe', 'london', 'france', 'germany', 'brussels', 'paris', 'berlin'] },
  { name: 'Asia', countries: ['china', 'japan', 'asia', 'pakistan', 'bangladesh', 'beijing', 'tokyo'] },
];
