import crypto from 'crypto';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { db } from './firebase';
import { categoryFeeds } from './feeds';
import { fetchCategoryNews } from './rss';
import { Article } from './types';

const RETENTION_MS = 30 * 24 * 60 * 60 * 1000;
const MAX_BATCH = 400;

export interface IngestReport {
  ok: boolean;
  reason?: string;
  fetched: number;
  written: number;
  purged: number;
  categories: Record<string, { fetched: number; written: number }>;
  durationMs: number;
  finishedAt: string;
}

export async function ingestAll(): Promise<IngestReport> {
  const start = Date.now();
  const report: IngestReport = {
    ok: false,
    fetched: 0,
    written: 0,
    purged: 0,
    categories: {},
    durationMs: 0,
    finishedAt: new Date().toISOString(),
  };

  if (!db) {
    report.reason = 'firestore-not-configured';
    return report;
  }

  const categories = Object.keys(categoryFeeds);

  const results = await Promise.all(
    categories.map(async (category) => {
      let fetched = 0;
      let written = 0;
      try {
        const articles = await fetchCategoryNews(category);
        fetched = articles.length;

        if (articles.length > 0) {
          const writer = db.bulkWriter();
          for (const art of articles) {
            const id = canonicalId(art.url);
            const ref = db.collection('articles').doc(id);
            writer.set(
              ref,
              {
                title: art.title,
                description: art.description ?? '',
                image: art.image ?? '',
                url: art.url,
                canonical_url: art.canonical_url ?? art.url,
                author: art.author ?? 'Staff',
                source: art.source ?? 'News',
                category,
                publishedAt: art.publishedAt ?? '',
                publishedAtMs: parsePublishedAtMs(art.publishedAt),
                ingestedAt: FieldValue.serverTimestamp(),
              },
              { merge: true }
            );
            written++;
          }
          await writer.close();
        }
      } catch (err) {
        console.error(`[ingest] category ${category} failed:`, err);
      }
      return { category, fetched, written };
    })
  );

  for (const r of results) {
    report.fetched += r.fetched;
    report.written += r.written;
    report.categories[r.category] = { fetched: r.fetched, written: r.written };
  }

  try {
    report.purged = await purgeOldArticles();
  } catch (err) {
    console.error('[ingest] purge failed:', err);
  }

  try {
    await db.collection('system').doc('ingestMeta').set({
      lastRun: FieldValue.serverTimestamp(),
      fetched: report.fetched,
      written: report.written,
      purged: report.purged,
      ok: true,
    });
  } catch (err) {
    console.error('[ingest] meta write failed:', err);
  }

  report.ok = true;
  report.durationMs = Date.now() - start;
  report.finishedAt = new Date().toISOString();
  return report;
}

export async function getCategoryArticlesFromStore(
  category: string,
  limit = 120
): Promise<Article[] | null> {
  if (!db) return null;
  try {
    const snapshot = await (db as FirebaseFirestore.Firestore)
      .collection('articles')
      .where('category', '==', category)
      .limit(500)
      .get();
    if (snapshot.empty) return null;
    const articles: Article[] = snapshot.docs.map((doc) => {
      const d = doc.data();
      return {
        title: d.title ?? 'No Title',
        description: d.description ?? '',
        image: d.image ?? '',
        url: d.url ?? '',
        canonical_url: d.canonical_url ?? d.url ?? '',
        author: d.author ?? 'Staff',
        source: d.source ?? 'News',
        category: d.category ?? category,
        publishedAt: d.publishedAt ?? '',
      };
    });
    articles.sort(
      (a, b) => parseTimeMs(b.publishedAt) - parseTimeMs(a.publishedAt)
    );
    return articles.slice(0, limit);
  } catch (err) {
    console.error('[store] read failed:', err);
    return null;
  }
}

export async function searchArchiveArticles(
  query: string,
  maxResults = 50
): Promise<Article[]> {
  if (!db) return [];
  try {
    const snapshot = await (db as FirebaseFirestore.Firestore)
      .collection('articles')
      .orderBy('publishedAtMs', 'desc')
      .limit(300)
      .get();
    const q = query.toLowerCase();
    return snapshot.docs
      .map((doc) => {
        const d = doc.data();
        return {
          title: d.title ?? 'No Title',
          description: d.description ?? '',
          image: d.image ?? '',
          url: d.url ?? '',
          canonical_url: d.canonical_url ?? d.url ?? '',
          author: d.author ?? 'Staff',
          source: d.source ?? 'News',
          category: d.category ?? 'general',
          publishedAt: d.publishedAt ?? '',
        } as Article;
      })
      .filter(
        (a) =>
          a.title.toLowerCase().includes(q) ||
          (a.description ?? '').toLowerCase().includes(q) ||
          (a.source ?? '').toLowerCase().includes(q)
      )
      .slice(0, maxResults);
  } catch (err) {
    console.error('[store] archive search failed:', err);
    return [];
  }
}

async function purgeOldArticles(): Promise<number> {
  const cutoff = Timestamp.fromMillis(Date.now() - RETENTION_MS);
  let deleted = 0;
  for (;;) {
    const snapshot = await (db as FirebaseFirestore.Firestore)
      .collection('articles')
      .where('ingestedAt', '<', cutoff)
      .limit(MAX_BATCH)
      .get();
    if (snapshot.empty) break;
    const writer = db.bulkWriter();
    snapshot.docs.forEach((doc) => writer.delete(doc.ref));
    await writer.close();
    deleted += snapshot.size;
  }
  return deleted;
}

function canonicalId(url: string): string {
  return crypto.createHash('sha256').update(url).digest('hex');
}

function parsePublishedAtMs(value?: string): number {
  return parseTimeMs(value);
}

function parseTimeMs(value?: string): number {
  if (!value) return 0;
  const t = Date.parse(value);
  return Number.isFinite(t) ? t : 0;
}
