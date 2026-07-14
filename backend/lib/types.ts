export interface Article {
  title: string;
  description?: string;
  summary?: string;
  image?: string;
  url: string;
  author?: string;
  publishedAt?: string;
  source?: string;
  content?: string;
  category?: string;
  readTime?: number;
  language?: string;
  tags?: string[];
}

export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
  pagination?: {
    page: number;
    limit: number;
    total: number;
    hasMore: boolean;
  };
  timestamp: string;
}
