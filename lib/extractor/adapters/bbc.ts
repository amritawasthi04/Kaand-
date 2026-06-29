import * as cheerio from 'cheerio';
import { BaseAdapter } from './base';
import { ExtractedArticle } from '../types';

export class BbcAdapter extends BaseAdapter {
  name = 'bbc';

  canHandle(url: string): boolean {
    return url.includes('bbc.com') || url.includes('bbc.co.uk');
  }

  async extract(html: string, $: cheerio.CheerioAPI, url: string): Promise<ExtractedArticle> {
    const jsonld = this.getJsonLd($);

    // 1. Title
    const title = this.cleanText(
      jsonld.headline ||
      this.getMetaTag($, ['og:title', 'twitter:title']) ||
      $('h1').first().text() ||
      'No Title'
    );

    // 2. Description
    const description = this.cleanText(
      jsonld.description ||
      this.getMetaTag($, ['og:description', 'description']) ||
      ''
    );

    // 3. Cover Image
    const image = 
      (jsonld.image && (typeof jsonld.image === 'string' ? jsonld.image : jsonld.image.url)) ||
      this.getMetaTag($, ['og:image', 'twitter:image']) ||
      '';

    // 4. Author
    const author = this.cleanText(
      (jsonld.author && (typeof jsonld.author === 'string' ? jsonld.author : jsonld.author.name)) ||
      this.getMetaTag($, ['author', 'twitter:creator']) ||
      'BBC News'
    );

    // 5. Date
    const rawDate = jsonld.datePublished || jsonld.uploadDate || this.getMetaTag($, ['article:published_time']);
    let publishedAt = new Date().toISOString();
    if (rawDate) {
      try {
        publishedAt = new Date(rawDate).toISOString();
      } catch {}
    }

    // 6. Content Body Specific to BBC Layout
    const paragraphs: string[] = [];
    $('article p, [data-component="text-block"] p, div[class*="RichText"] p').each((_, el) => {
      const txt = $(el).text().trim();
      if (txt.length > 20 && !txt.startsWith('Copyright') && !txt.includes('shared this')) {
        paragraphs.push(txt);
      }
    });

    const content = paragraphs.join('\n\n');

    return {
      title,
      description,
      content,
      image,
      author,
      source: 'BBC News',
      publishedAt,
      language: 'en'
    };
  }
}
export default BbcAdapter;
