import * as cheerio from 'cheerio';

export interface ExtractedArticle {
  title: string;
  description: string;
  content: string;
  image: string;
  author: string;
  source: string;
  publishedAt: string;
  language: string;
}

export interface ScoringResult {
  score: number;
  reasons: string[];
}

export interface ExtractorAdapter {
  name: string;
  canHandle(url: string): boolean;
  extract(html: string, $: cheerio.CheerioAPI, url: string): Promise<ExtractedArticle>;
}
