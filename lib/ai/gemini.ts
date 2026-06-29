import { GoogleGenerativeAI } from '@google/generative-ai';

const apiKey = process.env.GEMINI_API_KEY;
const genAI = apiKey ? new GoogleGenerativeAI(apiKey) : null;

interface GeminiOutput {
  summary: string;
  bullets: string[];
}

export async function generateGeminiSummary(
  content: string,
  title: string
): Promise<{ summary: string; readTime: number }> {
  // 1. Calculate reading time (200 words per minute average)
  const wordCount = content.trim().split(/\s+/).filter(Boolean).length;
  const readTime = Math.max(1, Math.ceil(wordCount / 200));

  if (!genAI || !content || content.trim().length < 50) {
    return {
      summary: `${title}\n\nNo detailed summary available (AI engine offline).`,
      readTime,
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
      ]
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

      return { summary, readTime };
    } catch (parseError) {
      console.warn('Failed to parse Gemini response JSON, falling back:', parseError);
      // Regex fallback if JSON parser fails
      return {
        summary: `${textResponse.slice(0, 300)}...`,
        readTime,
      };
    }
  } catch (error) {
    console.error('Error in generateGeminiSummary:', error);
    return {
      summary: `${title}\n\nFailed to generate AI summary.`,
      readTime,
    };
  }
}
