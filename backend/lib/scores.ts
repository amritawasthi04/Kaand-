/**
 * Live-scores extraction from sports article metadata.
 *
 * RSS feeds do not ship structured scorecards, so we parse score patterns
 * out of article titles/descriptions (same technique the Flutter
 * SportsScoreParser uses client-side) and infer match status from
 * wording + recency.
 */

export interface SportsScore {
  id: string;
  league: string;
  homeTeam: string;
  awayTeam: string;
  homeScore: number;
  awayScore: number;
  status: 'live' | 'final' | 'scheduled' | 'in_progress';
  startTime?: string | null;
  venue?: string | null;
  sport?: string | null;
  tournament?: string | null;
  matchUrl?: string | null;
  imageUrl?: string | null;
  isLive: boolean;
  inning?: string | null;
  overs?: string | null;
  commentary?: string | null;
}

const CRICKET_KEYWORDS = [
  'odi',
  't20',
  'test match',
  'ipl',
  'wicket',
  'innings',
  'runs',
  'cricket',
  'ashes',
  'bbl',
  'psl',
];
const FOOTBALL_KEYWORDS = [
  'football',
  'soccer',
  'premier league',
  'la liga',
  'champions league',
  'world cup',
  'euro',
  'goal',
  'fc ',
  'united',
  'city',
];
const TENNIS_KEYWORDS = ['tennis', 'wimbledon', 'us open', 'grand slam', 'atp', 'wta'];
const NBA_KEYWORDS = ['nba', 'basketball', 'lakers', 'warriors', 'celtics'];

const LIVE_WORDS = ['live', 'in progress', 'underway', 'half-time', 'halftime', 'tea break', 'stumps'];
const FINAL_WORDS = ['beat', 'beats', 'defeat', 'defeated', 'win', 'wins', 'won', 'thrash', 'edge past', 'seal', 'clinch', 'draw', 'held to'];

function detectSport(text: string): string | null {
  const t = text.toLowerCase();
  if (CRICKET_KEYWORDS.some((k) => t.includes(k))) return 'cricket';
  if (FOOTBALL_KEYWORDS.some((k) => t.includes(k))) return 'football';
  if (TENNIS_KEYWORDS.some((k) => t.includes(k))) return 'tennis';
  if (NBA_KEYWORDS.some((k) => t.includes(k))) return 'basketball';
  return null;
}

const TEAM_PREFIX_STOPWORDS = new Set([
  'hammer', 'hammers', 'beat', 'beats', 'defeat', 'defeats', 'defeated', 'stun', 'stuns',
  'stunned', 'edge', 'edges', 'down', 'downs', 'thrash', 'thrashes', 'crush', 'crushes',
  'demolish', 'demolishes', 'outclass', 'outclasses', 'rout', 'routs', 'sink', 'sinks',
  'dump', 'dumps', 'and', 'the', 'match', 'game', 'report', 'highlights', 'result',
  'to', 'in', 'of', 'as', 'for', 'after', 'seal', 'seals', 'sealed', 'win', 'wins', 'won',
]);

function cleanTeamName(raw: string): string {
  const words = raw
    .replace(/\b(live|highlights?|video|watch|score updates?|result|report)\b/gi, '')
    .replace(/\s{2,}/g, ' ')
    .trim()
    .split(' ')
    .filter(Boolean);
  return words
    .filter((w) => !TEAM_PREFIX_STOPWORDS.has(w.toLowerCase().replace(/[^a-z]/g, '')))
    .slice(0, 3)
    .join(' ');
}

function parseInt0(v?: string): number {
  const n = parseInt(v ?? '', 10);
  return Number.isFinite(n) ? n : 0;
}

function inferStatus(titleLower: string, ageMinutes: number | null): { status: SportsScore['status']; isLive: boolean } {
  const hasLiveWord = LIVE_WORDS.some((w) => titleLower.includes(w));
  const hasFinalWord = FINAL_WORDS.some((w) => titleLower.includes(w));
  if (hasLiveWord) return { status: 'live', isLive: true };
  if (hasFinalWord) return { status: 'final', isLive: false };
  // Recently published sports match headline without final wording: treat as live-ish
  if (ageMinutes != null && ageMinutes <= 90) return { status: 'in_progress', isLive: true };
  return { status: 'final', isLive: false };
}

function ageMinutesFrom(publishedAt?: string): number | null {
  if (!publishedAt) return null;
  const t = Date.parse(publishedAt);
  if (Number.isNaN(t)) return null;
  return Math.floor((Date.now() - t) / 60000);
}

/**
 * Attempt to extract a scorecard from an article headline.
 * Returns null when the headline does not look like a match result.
 */
export function extractScoreFromHeadline(input: {
  title: string;
  description?: string;
  url: string;
  source?: string;
  publishedAt?: string;
  image?: string;
}): SportsScore | null {
  const { title, url, source, publishedAt, image } = input;
  if (!title || title.length < 8) return null;

  const titleLower = title.toLowerCase();
  const descLower = (input.description ?? '').toLowerCase();
  const combined = `${title} ${input.description ?? ''}`;
  const sport = detectSport(combined) ?? (titleLower.includes('vs') || titleLower.includes(' v ') ? 'sports' : null);
  if (!sport) return null;

  const ageMinutes = ageMinutesFrom(publishedAt);
  const { status, isLive } = inferStatus(titleLower + ' ' + descLower, ageMinutes);

  // Pattern A — cricket: "India 285/3 vs Australia 280/9", "IND 185 vs AUS 181/8"
  const cricketVsPattern =
    /([A-Za-z][A-Za-z .&']{1,30}?)\s+(\d{1,3})(?:\/(\d{1,2}))?\s+(?:vs\.?|v\.?|against)\s+([A-Za-z][A-Za-z .&']{1,30}?)\s+(\d{1,3})(?:\/(\d{1,2}))?/i;
  let m = title.match(cricketVsPattern);
  if (m && sport === 'cricket') {
    return {
      id: url,
      league: source ?? 'Cricket',
      homeTeam: cleanTeamName(m[1]),
      awayTeam: cleanTeamName(m[4]),
      homeScore: parseInt0(m[2]),
      awayScore: parseInt0(m[5]),
      status,
      startTime: publishedAt ?? null,
      sport: 'cricket',
      matchUrl: url,
      imageUrl: image ?? null,
      isLive,
      inning: m[3] ? `${m[3]}/${m[2]}` : null,
      overs: null,
      commentary: null,
    };
  }

  // Pattern B — generic "A X–Y B" / "A X:Y B" (football, basketball)
  const genericScorePattern =
    /([A-Za-z][A-Za-z .&']{2,35}?)\s+(\d{1,3})\s*[-–—:]\s*(\d{1,3})\s+([A-Za-z][A-Za-z .&']{2,35})/;
  m = title.match(genericScorePattern);
  if (m) {
    const home = cleanTeamName(m[1]);
    const away = cleanTeamName(m[4]);
    if (home.length >= 2 && away.length >= 2 && home.toLowerCase() !== away.toLowerCase()) {
      return {
        id: url,
        league: source ?? 'Sports',
        homeTeam: home,
        awayTeam: away,
        homeScore: parseInt0(m[2]),
        awayScore: parseInt0(m[3]),
        status,
        startTime: publishedAt ?? null,
        sport,
        matchUrl: url,
        imageUrl: image ?? null,
        isLive,
        inning: null,
        overs: null,
        commentary: null,
      };
    }
  }

  // Pattern C — "A vs B" with score inside parentheses or dash later: "Team A vs Team B - 2-1"
  const vsPattern = /([A-Za-z][A-Za-z .&']{2,35}?)\s+(?:vs\.?|v\.?)\s+([A-Za-z][A-Za-z .&']{2,35}?)\s*[-–—:,]\s*(\d{1,3})\s*[-–—:]\s*(\d{1,3})/i;
  m = title.match(vsPattern);
  if (m) {
    return {
      id: url,
      league: source ?? 'Sports',
      homeTeam: cleanTeamName(m[1]),
      awayTeam: cleanTeamName(m[2]),
      homeScore: parseInt0(m[3]),
      awayScore: parseInt0(m[4]),
      status,
      startTime: publishedAt ?? null,
      sport,
      matchUrl: url,
      imageUrl: image ?? null,
      isLive,
      inning: null,
      overs: null,
      commentary: null,
    };
  }

  return null;
}

/**
 * Run extraction over a batch of sports articles; dedupe by teams pairing.
 */
export function extractScoresFromArticles(articles: {
  title: string;
  description?: string;
  url: string;
  source?: string;
  publishedAt?: string;
  image?: string;
}[]): SportsScore[] {
  const scores: SportsScore[] = [];
  const seen = new Set<string>();

  for (const art of articles) {
    const score = extractScoreFromHeadline(art);
    if (!score) continue;
    const key = [score.homeTeam.toLowerCase(), score.awayTeam.toLowerCase()].sort().join('|') + '|' + (score.sport ?? '');
    if (seen.has(key)) continue;
    seen.add(key);
    scores.push(score);
  }

  // Live first, then most recent
  scores.sort((a, b) => {
    if (a.isLive !== b.isLive) return a.isLive ? -1 : 1;
    const ta = a.startTime ? Date.parse(a.startTime) : 0;
    const tb = b.startTime ? Date.parse(b.startTime) : 0;
    return tb - ta;
  });

  return scores;
}
