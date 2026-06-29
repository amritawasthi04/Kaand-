import * as cheerio from 'cheerio';

export function cleanHtmlDom($: cheerio.CheerioAPI): void {
  // Unwanted elements classes and tag names
  const selectorsToStrip = [
    'script', 
    'style', 
    'iframe', 
    'noscript', 
    'header', 
    'footer', 
    'nav', 
    'aside',
    '.cookie-banner', 
    '.cookie-consent', 
    '#cookie-law', 
    '.cookie-overlay',
    '.ads', 
    '.ad-box', 
    '.advertisement', 
    '.sponsored', 
    '.ad-container',
    '[class*="advertisement"]',
    '[id*="google_ads"]',
    '.newsletter-signup', 
    '.newsletter-prompt', 
    '.subscribe-box',
    '.social-share', 
    '.share-buttons', 
    '.sharing',
    '.related-posts', 
    '.related-articles', 
    '.recommended', 
    '.read-more',
    '.paywall-overlay', 
    '.subscription-prompt', 
    '.login-prompt',
    '#comments', 
    '.comments-container', 
    '.discussion',
    '.menu-container', 
    '.main-navigation', 
    '.footer-links'
  ];

  for (const selector of selectorsToStrip) {
    try {
      $(selector).remove();
    } catch (e) {
      // Ignore invalid selectors or deletion issues
    }
  }

  // Strip hidden blocks to prevent paywall excerpts and cookie notifications from being scraped
  $('[style*="display: none"]').remove();
  $('[style*="display:none"]').remove();
  $('[aria-hidden="true"]').remove();
}

export function cleanCleanedContent(content: string): string {
  if (!content) return '';
  return content
    .replace(/\r\n/g, '\n')
    .replace(/\n{3,}/g, '\n\n') // Normalize multiple returns
    .trim();
}
