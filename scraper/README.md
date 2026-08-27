# KAAND local scraper

The mobile application calls the Next.js API; this crawler is an optional local
content-ingestion job for warming Firestore or reviewing article extraction.

## Run locally

```powershell
cd scraper
..\.venv\Scripts\python.exe -m pip install -r requirements.txt
..\.venv\Scripts\scrapy.exe crawl universal -O articles.json
```

`articles.json` is ignored output: inspect it locally and delete it when done.
The crawler resolves Google News redirects, extracts full text and tests image
candidates in this order: OpenGraph, Twitter, JSON-LD, RSS enclosure, then
article body. It uses a safe default image only when every candidate fails.

## Production scheduling

Run this job from a worker/VM or CI schedule with only the Firebase service
account supplied as an environment secret. Do not run Scrapy inside the mobile
app: Android and iOS background networking is intentionally limited, and this
would expose publishers to uncontrolled traffic from every device.

## Deploy to Cloud Run

Deploy the existing crawler as a **Cloud Run Job**. Jobs run to completion and
are the right shape for crawling the configured RSS feeds; do not deploy it as
a Vercel function.

```powershell
cd scraper
gcloud auth login
gcloud config set project YOUR_GOOGLE_CLOUD_PROJECT
gcloud run jobs deploy kaand-rss-crawler --source . --region asia-south1 --task-timeout 30m --max-retries 2 --service-account kaand-scraper@YOUR_GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
gcloud run jobs execute kaand-rss-crawler --region asia-south1 --wait
```

Grant `roles/datastore.user` to that service account so it can write Firestore.
The pipeline uses Cloud Run Application Default Credentials; never bake a
service-account JSON key into the image. Schedule the job via Cloud Scheduler
after validating an execution and its Firestore writes.
