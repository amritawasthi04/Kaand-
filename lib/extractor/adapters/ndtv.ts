import * as cheerio from 'cheerio';
import { BaseAdapter } from './base';
import { ExtractedArticle } from '../types';

export class NdtvAdapter extends BaseAdapter {
  name = 'ndtv';

  canHandle(url: string): boolean {
    return url.includes('ndtv.com') || url.includes('ndtv.in');
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

    // 3. Image
    const image = 
      (jsonld.image && (typeof jsonld.image === 'string' ? jsonld.image : jsonld.image.url)) ||
      this.getMetaTag($, ['og:image', 'twitter:image']) ||
      '';

    // 4. Author
    const author = this.cleanText(
      (jsonld.author && (typeof jsonld.author === 'string' ? jsonld.author : jsonld.author.name)) ||
      this.getMetaTag($, ['author']) ||
      'NDTV News'
    );

    // 5. Date
    const rawDate = jsonld.datePublished || this.getMetaTag($, ['publish-date', 'article:published_time']);
    let publishedAt = new Date().toISOString();
    if (rawDate) {
      try {
        publishedAt = new Date(rawDate).toISOString();
      } catch {}
    }

    // 6. Content Body Specific to NDTV Article Layouts
    const paragraphs: string[] = [];
    $('div[itemprop="articleBody"] p, .sp-cn p, .ins_storybody p, #storypost p').each((_, el) => {
      const txt = $(el).text().trim();
      if (
        txt.length > 20 && 
        !txt.toLowerCase().includes('click here') && 
        !txt.toLowerCase().includes('sponsored by')
      ) {
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
      source: 'NDTV',
      publishedAt,
      language: 'en'
    };
  }
}
export default NdtvAdapter;
