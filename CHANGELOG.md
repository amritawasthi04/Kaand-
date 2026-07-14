# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-07-14

### Added
- **Flutter UI & Interactions**: Modern glassmorphism themes, article cards, detailed dynamic bottom sheet layouts, and onboarding setup.
- **Infinite Scrolling**: Reusable list scroll controllers triggering dynamic page increments at 80% scroll depth.
- **Live Next.js API**: Dynamic routes for search `/api/search`, categories `/api/categories`, category ID `/api/category/[id]`, publishers `/api/publishers`, publisher ID `/api/publisher/[id]`, and trending `/api/trending`.
- **Publisher Adapters & Cleansing Engine**: Extractor adapter configurations for BBC, TechCrunch, The Guardian, and NYT. Strict regex tag filters and entity decoder rules.
- **Image Priority Validation**: 6-tier prioritization mapping that enforces HTTPS check resolution, keyword exclusions, and HEAD size threshold validation.
- **Scrapy crawler service**: Universal Spider, item configurations, deduping pipelines, and docker configuration.
- **SSRF Blockers**: Security CORS configs and loopback DNS blocks.

### Changed
- Refactored Flutter state layers to consume centralized Dio clients and repositories instead of legacy HTTP parsers.

### Fixed
- Next.js hot-reloaded module route compilation warnings.
- Leading slash path resolution bug in Dio client.

### Known Issues
- Image extraction validation requires stable internet subnet routing under restricted corporate proxy environments.
