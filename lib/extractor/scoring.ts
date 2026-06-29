import { ExtractedArticle, ScoringResult } from './types';

export function scoreExtraction(article: ExtractedArticle): ScoringResult {
  const reasons: string[] = [];
  let points = 0;
  let maxPoints = 0;

  // 1. Title Quality (max 10 points)
  maxPoints += 10;
  if (article.title && article.title.length > 5 && article.title !== 'No Title') {
    points += 10;
  } else {
    reasons.push('Title is missing or too short.');
  }

  // 2. Content Length (max 30 points)
  maxPoints += 30;
  const wordCount = article.content ? article.content.split(/\s+/).filter(Boolean).length : 0;
  if (wordCount > 600) {
    points += 30;
  } else if (wordCount > 250) {
    points += 20;
    reasons.push('Content is moderately short (250-600 words).');
  } else if (wordCount > 50) {
    points += 10;
    reasons.push('Content is very short (50-250 words).');
  } else {
    reasons.push('Content contains insufficient text (<50 words).');
  }

  // 3. Description Presence (max 10 points)
  maxPoints += 10;
  if (article.description && article.description.trim().length > 10) {
    points += 10;
  } else {
    reasons.push('Description is missing or empty.');
  }

  // 4. Author Presence (max 10 points)
  maxPoints += 10;
  if (article.author && article.author !== 'Staff' && article.author !== 'Unknown' && article.author !== 'The Guardian') {
    points += 10;
  } else {
    reasons.push('Author attribution is missing or generic.');
  }

  // 5. Image Presence (max 10 points)
  maxPoints += 10;
  if (article.image && article.image.startsWith('http')) {
    points += 10;
  } else {
    reasons.push('Cover image URL is missing or invalid.');
  }

  // 6. Publication Date (max 10 points)
  maxPoints += 10;
  if (article.publishedAt && !isNaN(Date.parse(article.publishedAt))) {
    const pubTime = new Date(article.publishedAt).getTime();
    const now = Date.now();
    if (Math.abs(now - pubTime) > 60 * 1000) {
      points += 10;
    } else {
      points += 5;
      reasons.push('Publication date is set to current fallback timestamp.');
    }
  } else {
    reasons.push('Publication date is missing or invalid.');
  }

  // 7. Paywall / Cookie Overlay Keywords (Deduct up to 25 points)
  const contentLower = article.content.toLowerCase();
  const paywallKeywords = [
    'paywall', 
    'subscribe to read', 
    'support our journalism',
    'please log in', 
    'create an account', 
    'exclusive content for subscribers',
    'sign in to continue', 
    'read the rest of this article by subscribing',
    'cookie consent',
    'enable javascript'
  ];
  
  let paywallHits = 0;
  for (const keyword of paywallKeywords) {
    if (contentLower.includes(keyword)) {
      paywallHits++;
    }
  }

  if (paywallHits > 0) {
    const penalty = Math.min(25, paywallHits * 8);
    points = Math.max(0, points - penalty);
    reasons.push(`Paywall or overlay text markers detected (penalty: -${penalty} points).`);
  }

  const score = maxPoints > 0 ? parseFloat((points / maxPoints).toFixed(2)) : 0;
  return { score, reasons };
}
