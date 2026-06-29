import { NextRequest } from 'next/server';
import { z } from 'zod';
import { handleOptions } from '../../../lib/utils/cors';
import { successResponse, errorResponse } from '../../../lib/utils/response';
import { getArticleCache, setArticleCache } from '../../../lib/firebase/firestore';
import { runExtractionEngine } from '../../../lib/extractor/engine';
import { aiCleanup, generateGeminiSummary } from '../../../lib/ai/gemini';
import { Article } from '../../../lib/models/article';
import { md5 } from '../../../lib/utils/hash';

const QuerySchema = z.object({
  url: z.string().url(),
});

export async function OPTIONS() {
  return handleOptions();
}

export async function GET(request: NextRequest) {
  try {
    const urlVal = request.nextUrl.searchParams.get('url');

    if (!urlVal) {
      return errorResponse('Missing url parameter', 'MISSING_URL', 400);
    }

    // Validate parameter structure via Zod
    const parsed = QuerySchema.safeParse({ url: urlVal });
    if (!parsed.success) {
      const errors = parsed.error.errors.map(err => ({
        field: err.path.join('.'),
        message: err.message,
      }));
      return errorResponse('Invalid URL format', 'INVALID_URL', 400, errors);
    }

    const { url } = parsed.data;

    // 1. Check if article details are already cached in Firestore
    const cached = await getArticleCache(url);
    if (cached) {
      console.log(`Universal Engine: Cache HIT for article: ${url}`);
      return successResponse({
        ...cached,
        cached: true,
      });
    }

    console.log(`Universal Engine: Cache MISS. Starting crawler for: ${url}`);

    // 2. Perform modular extraction (using Registry, Cleaner, Adapters, Generic fallback, and Scorer)
    let engineResult;
    try {
      engineResult = await runExtractionEngine(url);
    } catch (scrapeError: any) {
      console.error(`Universal Engine: Crawler failed for ${url}:`, scrapeError);
      return errorResponse(
        `Failed to crawl article content: ${scrapeError.message || 'Scraper timeout'}`,
        'SCRAPING_FAILED',
        502
      );
    }

    const { article, score, extractorUsed } = engineResult;

    // 3. AI Content Polish: Remove residual page layouts / boilerplate
    let polishedContent = article.content;
    try {
      polishedContent = await aiCleanup(article.content, article.title);
    } catch (cleanupError) {
      console.warn('Universal Engine: AI text polishing failed, falling back to raw extract:', cleanupError);
    }

    // 4. AI Summarization & Classification (Gemini 1.5 Flash query)
    let summaryResult;
    try {
      summaryResult = await generateGeminiSummary(polishedContent, article.title);
    } catch (aiError: any) {
      console.error(`Universal Engine: AI summarizer failed for ${url}:`, aiError);
      summaryResult = {
        summary: article.description || 'No summary details generated (AI model timeout).',
        readTime: Math.max(1, Math.ceil(polishedContent.length / 1000)),
        category: 'general',
        tags: [],
      };
    }

    // 5. Construct Normalized Output
    const newArticle: Article = {
      id: md5(url),
      title: article.title,
      description: article.description,
      summary: summaryResult.summary,
      image: article.image,
      url,
      author: article.author,
      source: article.source,
      publishedAt: article.publishedAt,
      category: summaryResult.category || 'general',
      content: polishedContent,
      readTime: summaryResult.readTime,
      language: article.language,
      tags: summaryResult.tags,
      extractionScore: score,
      extractorUsed: extractorUsed,
      cached: false,
    };

    // 6. Save back to Firestore Cache
    await setArticleCache(url, newArticle);

    return successResponse(newArticle);
  } catch (error: any) {
    console.error('Error in GET /api/article:', error);
    return errorResponse(error.message || 'Failed to process article extraction', 'ARTICLE_PROCESS_ERROR');
  }
}
