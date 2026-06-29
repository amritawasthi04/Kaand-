import { GoogleGenerativeAI } from '@google/generative-ai';

const apiKey = process.env.GEMINI_API_KEY;
const genAI = apiKey ? new GoogleGenerativeAI(apiKey) : null;

interface GeminiOutput {
  summary: string;
  bullets: string[];
  category: string;
  tags: string[];
}

export async function aiCleanup(content: string, title: string): Promise<string> {
  if (!genAI || !content || content.trim().length < 150) {
    return content;
  }
  try {
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
    const prompt = `
    You are an expert editor. Clean up the following scraped article text.
    Tasks:
    1. Remove residual web page boilerplate, promotional blurbs, sign-up forms, copyright notices, and navigation elements.
    2. Maintain the main facts, arguments, quotes, and narrative sequence of the article.
    3. Correct broken sentences, merge split paragraphs, and format with standard double-newlines between paragraphs.
    4. Do not invent any new facts or opinions. Preserve original words where appropriate.

    Title: "${title}"
    Scraped Content:
    "${content}"

    Output ONLY the cleaned article text. Do not include introductory notes, comments, or quotes surrounding the text.
    `;
    const result = await model.generateContent(prompt);
    const cleanedText = result.response.text().trim();
    return cleanedText || content;
  } catch (error) {
    console.error('Error during AI Content Cleanup:', error);
    return content;
  }
}

export async function generateGeminiSummary(
  content: string,
  title: string
): Promise<{ summary: string; readTime: number; category: string; tags: string[] }> {
  // Calculate reading time (200 words per minute average)
  const wordCount = content.trim().split(/\s+/).filter(Boolean).length;
  const readTime = Math.max(1, Math.ceil(wordCount / 200));

  if (!genAI || !content || content.trim().length < 50) {
    return {
      summary: `${title}\n\nNo detailed summary available (AI engine offline).`,
      readTime,
      category: 'general',
      tags: [],
    };
  }

  try {
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

    const prompt = `
    You are an expert news editor. Summarize the following news article.
    Title: "${title}"
    Content:
    "${content}"

    Return the response strictly as a valid JSON object matching the following structure:
    {
      "summary": "A concise 2-line overview of the main event (max 30 words).",
      "bullets": [
        "First key highlight line.",
        "Second key highlight line.",
        "Third key highlight line.",
        "Fourth key highlight line.",
        "Fifth key highlight line."
      ],
      "category": "One standard category mapping: technology, business, sports, health, science, world, india, or entertainment",
      "tags": ["3 to 5 brief lowercase keywords describing entities, topics, or themes"]
    }
    Make sure to output ONLY valid JSON. No markdown backticks, no wrap formatting.
    `;

    const result = await model.generateContent(prompt);
    const textResponse = result.response.text().trim();

    // Clean up markdown block wraps if the model returned them
    const cleanJson = textResponse
      .replace(/^```json/i, '')
      .replace(/^```/, '')
      .replace(/```$/, '')
      .trim();

    try {
      const parsed = JSON.parse(cleanJson) as GeminiOutput;
      const summaryText = parsed.summary || 'Summary unavailable.';
      const bullets = Array.isArray(parsed.bullets)
        ? parsed.bullets.slice(0, 5).map(b => `• ${b.trim()}`).join('\n')
        : '';
      
      const summary = `${summaryText}\n\nKey Highlights:\n${bullets}`;
      const category = parsed.category || 'general';
      const tags = Array.isArray(parsed.tags) ? parsed.tags.map(t => t.toLowerCase().trim()) : [];

      return { summary, readTime, category, tags };
    } catch (parseError) {
      console.warn('Failed to parse Gemini response JSON, falling back:', parseError);
      return {
        summary: `${textResponse.slice(0, 300)}...`,
        readTime,
        category: 'general',
        tags: [],
      };
    }
  } catch (error) {
    console.error('Error in generateGeminiSummary:', error);
    return {
      summary: `${title}\n\nFailed to generate AI summary.`,
      readTime,
      category: 'general',
      tags: [],
    };
  }
}
