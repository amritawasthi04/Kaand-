import * as cheerio from 'cheerio';
import { ExtractedArticle, ExtractorAdapter } from '../types';

export abstract class BaseAdapter implements ExtractorAdapter {
  abstract name: string;
  abstract canHandle(url: string): boolean;
  abstract extract(html: string, $: cheerio.CheerioAPI, url: string): Promise<ExtractedArticle>;

  protected getMetaTag($: cheerio.CheerioAPI, properties: string[]): string {
    for (const prop of properties) {
      const val = $(`meta[property="${prop}"]`).attr('content') ||
                  $(`meta[name="${prop}"]`).attr('content') ||
                  $(`meta[itemprop="${prop}"]`).attr('content');
      if (val) {
        return val.trim();
      }
    }
    return '';
  }

  protected getJsonLd($: cheerio.CheerioAPI): any {
    let jsonld: any = {};
    $('script[type="application/ld+json"]').each((_, el) => {
      try {
        const text = $(el).html()?.trim();
        if (!text) return;
        const parsed = JSON.parse(text);
        const graph = parsed['@graph'] || (Array.isArray(parsed) ? parsed : [parsed]);
        for (const item of graph) {
          if (
            item['@type'] === 'NewsArticle' || 
            item['@type'] === 'Article' || 
            item['@type'] === 'BlogPosting'
          ) {
            jsonld = item;
            break;
          }
        }
        if (!jsonld.headline && (parsed.headline || parsed.name)) {
          jsonld = parsed;
        }
      } catch {
        // Ignore json parse error
      }
    });
    return jsonld;
  }

  protected getSourceFromUrl(url: string): string {
    try {
      return new URL(url).hostname.replace(/^www\./, '');
    } catch {
      return 'External Source';
    }
  }

  protected cleanText(text: string): string {
    return text ? text.replace(/\s+/g, ' ').trim() : '';
  }
}
