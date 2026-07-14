FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Default: crawl all feeds, output to stdout JSON lines
CMD ["scrapy", "crawl", "universal"]
