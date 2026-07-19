import { getAllDiscoverArticles } from './discover';
import { Article } from './types';
import { categoryFeeds } from './feeds';

// 1. Hero Story Engine
export function getHeroStory(articles: Article[]): Article | null {
  if (articles.length === 0) return null;
  // Select one high quality article: has image, description > 100 chars, and from reputable source
  const reputableSources = ['BBC', 'Reuters', 'The Hindu', 'The Guardian', 'Bloomberg'];
  const candidates = articles.filter(a => 
    a.image && 
    a.image.startsWith('https://') &&
    a.description && 
    a.description.length > 80 &&
    reputableSources.includes(a.source || '')
  );

  return candidates.length > 0 ? candidates[0] : articles[0];
}

// 2. Breaking News Engine
export function getBreakingNews(articles: Article[]): Article[] {
  const breakingKeywords = [
    'breaking', 'emergency', 'disaster', 'crisis', 'announcement', 
    'election', 'modi', 'biden', 'trump', 'launch', 'crash', 'dead', 'kills'
  ];
  
  const breaking = articles.filter(a => {
    const titleLower = a.title.toLowerCase();
    const descLower = (a.description || '').toLowerCase();
    return breakingKeywords.some(kw => titleLower.includes(kw) || descLower.includes(kw));
  });

  return breaking.slice(0, 3);
}

// 3. Editor's Highlights
export function getEditorsHighlights(articles: Article[]): Article[] {
  const categoriesSeen = new Set<string>();
  const highlights: Article[] = [];

  for (const art of articles) {
    const cat = art.category || 'general';
    if (!categoriesSeen.has(cat)) {
      highlights.push(art);
      categoriesSeen.add(cat);
    }
    if (highlights.length >= 8) break;
  }

  // Fallback if not enough categories
  if (highlights.length < 6) {
    for (const art of articles) {
      if (!highlights.some(h => h.url === art.url)) {
        highlights.push(art);
      }
      if (highlights.length >= 8) break;
    }
  }

  return highlights;
}

// 4. Category Highlights
export interface CategoryHighlight {
  category: string;
  articleCount: number;
  featuredArticle: Article | null;
  imageUrl: string;
}

export function getCategoryHighlights(articles: Article[]): CategoryHighlight[] {
  const categories = ['technology', 'business', 'sports', 'science'];
  
  return categories.map(cat => {
    const catArticles = articles.filter(a => a.category?.toLowerCase() === cat);
    const featured = catArticles.length > 0 ? catArticles[0] : null;
    return {
      category: cat.toUpperCase(),
      articleCount: catArticles.length,
      featuredArticle: featured,
      imageUrl: featured?.image || 'https://images.unsplash.com/photo-1504711434969-e33886168f5c?auto=format&fit=crop&w=1200&q=80'
    };
  });
}

// 5. Deduplication Engine
export function deduplicateArticles(articles: Article[]): Article[] {
  const seenUrls = new Set<string>();
  const deduped: Article[] = [];

  for (const art of articles) {
    if (!art.url || seenUrls.has(art.url)) continue;

    // Detect duplicate titles via simple Jaccard or substring checks
    let isDupe = false;
    const titleWords = art.title.toLowerCase().split(/\s+/).filter(w => w.length > 3);
    
    for (const existing of deduped) {
      // If 70% of words overlap, treat as duplicate event coverage
      const existingWords = existing.title.toLowerCase().split(/\s+/).filter(w => w.length > 3);
      const common = titleWords.filter(w => existingWords.includes(w));
      if (common.length > Math.min(titleWords.length, existingWords.length) * 0.7) {
        isDupe = true;
        break;
      }
    }

    if (!isDupe) {
      seenUrls.add(art.url);
      deduped.push(art);
    }
  }

  return deduped;
}
