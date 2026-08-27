import { ingestAll } from '../lib/ingest';

async function main() {
  const started = Date.now();
  const report = await ingestAll();
  console.log(JSON.stringify(report, null, 2));
  console.log(`[ingest] done in ${Date.now() - started}ms`);
  if (!report.ok) {
    process.exit(1);
  }
}

main().catch((err) => {
  console.error('[ingest] fatal:', err);
  process.exit(1);
});
