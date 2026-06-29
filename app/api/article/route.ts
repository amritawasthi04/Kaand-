import { NextRequest } from 'next/server';
import { z } from 'zod';
import { handleOptions } from '../../../lib/utils/cors';
import { successResponse, errorResponse } from '../../../lib/utils/response';
import { getArticleCache, setArticleCache } from '../../../lib/firebase/firestore';
import { scrapeArticleUrl } from '../../../lib/scraper';
import { generateGeminiSummary } from '../../../lib/ai/gemini';
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
      return errorResponse('Invalid URL format', 'INVALID_URL', 400);
    }

    const { url } = parsed.data;

    // 1. Check if article details are already cached in Firestore
    const cached = await getArticleCache(url);
    if (cached) {
      console.log(`Cache HIT for article: ${url}`);
      return successResponse(cached);
    }

    console.log(`Cache MISS. Scraping article: ${url}`);

    // 2. Perform HTML and text scraping (Cheerio + Readability)
    let scraped;
    try {
      scraped = await scrapeArticleUrl(url);
    } catch (scrapeError: any) {
      console.error(`Scraping failed for ${url}:`, scrapeError);
      return errorResponse(
        `Failed to crawl article content: ${scrapeError.message || 'Scraper timeout'}`,
        'SCRAPING_FAILED',
        502
      );
    }

    // 3. Generate AI summary and reading time using Google Gemini
    let aiResult;
    try {
      aiResult = await generateGeminiSummary(scraped.content, scraped.title);
    } catch (aiError: any) {
      console.error(`AI summary generation failed for ${url}:`, aiError);
      aiResult = {
        summary: scraped.description || 'No detailed summary available (AI model error).',
        readTime: Math.max(1, Math.ceil(scraped.content.length / 1000)),
      };
    }

    // 4. Construct unified Article schema
    const newArticle: Article = {
      id: md5(url),
      title: scraped.title,
      description: scraped.description,
      summary: aiResult.summary,
      image: scraped.image,
      url,
      author: scraped.author,
      source: scraped.source,
      publishedAt: scraped.publishedAt,
      category: 'scraped',
      content: scraped.content,
      readTime: aiResult.readTime,
      language: 'en',
    };

    // 5. Store in Firestore Cache
    await setArticleCache(url, newArticle);

    return successResponse(newArticle);
  } catch (error: any) {
    console.error('Error in GET /api/article:', error);
    return errorResponse(error.message || 'Failed to process article', 'ARTICLE_PROCESS_ERROR');
  }
}
