import { ExtractorAdapter } from './types';
import { BbcAdapter } from './adapters/bbc';
import { NdtvAdapter } from './adapters/ndtv';
import { TheHinduAdapter } from './adapters/thehindu';

const ADAPTERS: ExtractorAdapter[] = [
  new BbcAdapter(),
  new NdtvAdapter(),
  new TheHinduAdapter(),
];

export function getAdapterForUrl(url: string): ExtractorAdapter | null {
  try {
    for (const adapter of ADAPTERS) {
      if (adapter.canHandle(url)) {
        return adapter;
      }
    }
  } catch (err) {
    console.error('Registry failed to evaluate URL:', url, err);
  }
  return null;
}
