import { db } from './config';
import { Article } from '../models/article';
import { TTL_FEED, TTL_ARTICLE, DISABLE_CACHE } from '../constants';
import { md5 } from '../utils/hash';

export async function getFeedCache(category: string): Promise<Article[] | null> {
  if (!db || DISABLE_CACHE) return null;
  try {
    const doc = await db.collection('feed_cache').doc(category).get();
    if (!doc.exists) return null;
    const data = doc.data();
    if (!data) return null;

    const now = Date.now();
    const expiresAt = data.expiresAt ? new Date(data.expiresAt).getTime() : 0;
    if (now > expiresAt) {
      console.log(`Feed cache for ${category} expired.`);
      return null;
    }
    return data.articles as Article[];
  } catch (error) {
    console.error(`Error reading feed cache for ${category}:`, error);
    return null;
  }
}

export async function setFeedCache(category: string, articles: Article[]): Promise<void> {
  if (!db || DISABLE_CACHE) return;
  try {
    const now = Date.now();
    await db.collection('feed_cache').doc(category).set({
      updatedAt: new Date(now).toISOString(),
      expiresAt: new Date(now + TTL_FEED).toISOString(),
      articles,
    });
    console.log(`Saved feed cache for ${category}.`);
  } catch (error) {
    console.error(`Error setting feed cache for ${category}:`, error);
  }
}

export async function getArticleCache(url: string): Promise<Article | null> {
  if (!db || DISABLE_CACHE) return null;
  try {
    const docId = md5(url);
    const doc = await db.collection('article_cache').doc(docId).get();
    if (!doc.exists) return null;
    const data = doc.data();
    if (!data) return null;

    const now = Date.now();
    const expiresAt = data.expiresAt ? new Date(data.expiresAt).getTime() : 0;
    if (now > expiresAt) {
      console.log(`Article cache for ${url} expired.`);
      return null;
    }
    return data as unknown as Article;
  } catch (error) {
    console.error(`Error reading article cache for ${url}:`, error);
    return null;
  }
}

export async function setArticleCache(url: string, article: Article): Promise<void> {
  if (!db || DISABLE_CACHE) return;
  try {
    const docId = md5(url);
    const now = Date.now();
    await db.collection('article_cache').doc(docId).set({
      ...article,
      cachedAt: new Date(now).toISOString(),
      expiresAt: new Date(now + TTL_ARTICLE).toISOString(),
    });
    console.log(`Saved article cache for ${url}.`);
  } catch (error) {
    console.error(`Error setting article cache for ${url}:`, error);
  }
}

export async function getGuardianCache(key: string): Promise<Article[] | null> {
  if (!db || DISABLE_CACHE) return null;
  try {
    const doc = await db.collection('guardian_cache').doc(key).get();
    if (!doc.exists) return null;
    const data = doc.data();
    if (!data) return null;

    const now = Date.now();
    const expiresAt = data.expiresAt ? new Date(data.expiresAt).getTime() : 0;
    if (now > expiresAt) {
      console.log(`Guardian cache for ${key} expired.`);
      return null;
    }
    return data.articles as Article[];
  } catch (error) {
    console.error(`Error reading guardian cache for ${key}:`, error);
    return null;
  }
}

export async function setGuardianCache(key: string, articles: Article[]): Promise<void> {
  if (!db || DISABLE_CACHE) return;
  try {
    const now = Date.now();
    await db.collection('guardian_cache').doc(key).set({
      updatedAt: new Date(now).toISOString(),
      expiresAt: new Date(now + TTL_FEED).toISOString(),
      articles,
    });
    console.log(`Saved guardian cache for ${key}.`);
  } catch (error) {
    console.error(`Error setting guardian cache for ${key}:`, error);
  }
}

export interface ScraperHealth {
  totalPublishers: number;
  passed: number;
  failed: number;
  averageScrapeTimeMs: number;
  cacheHitRate: number;
  failureReasons: Record<string, number>;
  lastRunTimestamp: string;
}

export async function getScraperHealth(): Promise<ScraperHealth | null> {
  if (!db) return null;
  try {
    const doc = await db.collection('scraper_health').doc('latest').get();
    if (!doc.exists) return null;
    return doc.data() as ScraperHealth;
  } catch (error) {
    console.error('Error getting scraper health:', error);
    return null;
  }
}

export async function setScraperHealth(health: ScraperHealth): Promise<void> {
  if (!db) return;
  try {
    await db.collection('scraper_health').doc('latest').set(health);
  } catch (error) {
    console.error('Error setting scraper health:', error);
  }
}

export async function recordScrapeMetric(success: boolean, elapsedMs: number, reason?: string): Promise<void> {
  if (!db) return;
  try {
    const docRef = db.collection('scraper_health').doc('latest');
    await db.runTransaction(async (transaction) => {
      const doc = await transaction.get(docRef);
      const nowStr = new Date().toISOString();
      let health: ScraperHealth;
      if (doc.exists) {
        const data = doc.data() as ScraperHealth;
        const newTotal = (data.totalPublishers || 0) + 1;
        const newPassed = (data.passed || 0) + (success ? 1 : 0);
        const newFailed = (data.failed || 0) + (success ? 0 : 1);
        const currentAvg = data.averageScrapeTimeMs || 0;
        const newAvg = (currentAvg * (newTotal - 1) + elapsedMs) / newTotal;
        
        const newReasons = { ...(data.failureReasons || {}) };
        if (!success && reason) {
          const cleanReason = reason.replace(/[\.\#\$\/\[\]]/g, '_');
          newReasons[cleanReason] = (newReasons[cleanReason] || 0) + 1;
        }
        
        health = {
          totalPublishers: newTotal,
          passed: newPassed,
          failed: newFailed,
          averageScrapeTimeMs: parseFloat(newAvg.toFixed(2)),
          cacheHitRate: data.cacheHitRate || 0,
          failureReasons: newReasons,
          lastRunTimestamp: nowStr,
        };
      } else {
        const cleanReason = reason ? reason.replace(/[\.\#\$\/\[\]]/g, '_') : 'Unknown';
        health = {
          totalPublishers: 1,
          passed: success ? 1 : 0,
          failed: success ? 0 : 1,
          averageScrapeTimeMs: elapsedMs,
          cacheHitRate: 0,
          failureReasons: !success ? { [cleanReason]: 1 } : {},
          lastRunTimestamp: nowStr,
        };
      }
      transaction.set(docRef, health);
    });
  } catch (error) {
    console.error('Error recording scrape metric:', error);
  }
}


