import { getCategoryArticlesFromStore } from '../lib/ingest';
import { extractScoresFromArticles } from '../lib/scores';

async function main() {
  const articles = await getCategoryArticlesFromStore('sports', 300);
  if (!articles || articles.length === 0) {
    console.error('No sports articles in store');
    process.exit(1);
  }
  console.log(`sports articles in store: ${articles.length}`);

  const scores = extractScoresFromArticles(articles);
  console.log(`extracted scores: ${scores.length}\n`);

  for (const s of scores.slice(0, 15)) {
    console.log(
      `[${s.isLive ? 'LIVE' : s.status.toUpperCase()}] [${s.sport}] ${s.homeTeam} ${s.homeScore}-${s.awayScore} ${s.awayTeam} — ${s.league}`
    );
  }

  // Also sanity-check patterns against synthetic headlines
  const samples = [
    { title: 'India 285/3 vs Australia 280/9 - Live Cricket Score', url: 'u1', source: 'ESPN' },
    { title: 'Lakers 112-108 Warriors: NBA roundup', url: 'u2', source: 'ESPN' },
    { title: 'Arsenal vs Chelsea - 2-1: Premier League result', url: 'u3', source: 'BBC' },
    { title: 'Spain beat England 2-1 to win Euro 2024', url: 'u4', source: 'BBC' },
    { title: 'Rohit Sharma hits century as India seal T20 series', url: 'u5', source: 'TOI' },
  ];
  const extracted = extractScoresFromArticles(samples);
  console.log(`\nsynthetic extraction: ${extracted.length}/5`);
  for (const s of extracted) {
    console.log(`  ${s.homeTeam} ${s.homeScore}-${s.awayScore} ${s.awayTeam} [${s.status}]`);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
