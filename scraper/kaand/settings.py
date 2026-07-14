BOT_NAME = "kaand"

SPIDER_MODULES = ["kaand.spiders"]
NEWSPIDER_MODULE = "kaand.spiders"

# Respect robots.txt rules
ROBOTSTXT_OBEY = True

# Concurrency
CONCURRENT_REQUESTS = 16
DOWNLOAD_DELAY = 0.5
CONCURRENT_REQUESTS_PER_DOMAIN = 4

# AutoThrottle
AUTOTHROTTLE_ENABLED = True
AUTOTHROTTLE_START_DELAY = 0.5
AUTOTHROTTLE_MAX_DELAY = 5.0
AUTOTHROTTLE_TARGET_CONCURRENCY = 1.0

# Retry
RETRY_ENABLED = True
RETRY_TIMES = 2
RETRY_HTTP_CODES = [429, 500, 502, 503, 504]

# Timeouts
DOWNLOAD_TIMEOUT = 12

# Item pipelines
ITEM_PIPELINES = {
    "kaand.pipelines.DeduplicatePipeline": 100,
    "kaand.pipelines.ValidationPipeline": 200,
    "kaand.firestore_pipeline.FirestorePipeline": 300,
}

# Structured logging
LOG_FORMAT = "%(asctime)s [%(name)s] %(levelname)s: %(message)s"
LOG_LEVEL = "INFO"

REQUEST_FINGERPRINTER_IMPLEMENTATION = "2.7"
TWISTED_REACTOR = "twisted.internet.asyncioreactor.AsyncioSelectorReactor"
FEED_EXPORT_ENCODING = "utf-8"

# User agent
USER_AGENT = "KAAND/1.0 (+https://github.com/amritawasthi04/Kaand-)"
