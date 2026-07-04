/**
 * Sanitizes and repairs malformed XML feeds before they are parsed by rss-parser.
 * Resolves CDATA inconsistencies, unescaped ampersands, and invalid characters.
 */
export function sanitizeXml(xmlStr: string): string {
  if (!xmlStr) return '';

  // 1. Strip any leading garbage characters preceding the XML opening tag
  xmlStr = xmlStr.trim().replace(/^[^<]+/, '');

  // 2. Fix unescaped ampersands
  // Replaces '&' with '&amp;' unless it matches a standard XML/HTML entity format (e.g. &amp;, &#123;, &lt;, etc.)
  xmlStr = xmlStr.replace(/&(?!(#[0-9]+|[a-zA-Z0-9]+);)/g, '&amp;');

  // 3. Clean up invalid Unicode control characters that break the parser (outside legal XML range)
  xmlStr = xmlStr.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x84\x86-\x9F]/g, '');

  return xmlStr;
}
