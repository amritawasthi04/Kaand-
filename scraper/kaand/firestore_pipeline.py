import json
import logging
import os

logger = logging.getLogger(__name__)


class FirestorePipeline:
    """Writes articles to Firestore. Falls back to JSON file if no credentials."""

    def __init__(self):
        self.db = None
        self.fallback_file = None
        self.fallback_items = []

    def open_spider(self, spider):
        cred_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS", "")

        if cred_path and os.path.isfile(cred_path):
            try:
                import firebase_admin
                from firebase_admin import credentials, firestore

                cred = credentials.Certificate(cred_path)
                # ponytail: single default app, multi-project needs named apps
                try:
                    firebase_admin.get_app()
                except ValueError:
                    firebase_admin.initialize_app(cred)

                self.db = firestore.client()
                logger.info("Firestore pipeline initialized.")
            except Exception as e:
                logger.warning(f"Firestore init failed, falling back to JSON: {e}")
                self._init_fallback(spider)
        else:
            logger.info("No GOOGLE_APPLICATION_CREDENTIALS set. Writing to articles.json instead.")
            self._init_fallback(spider)

    def _init_fallback(self, spider):
        out_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "articles.json")
        self.fallback_file = out_path
        self.fallback_items = []

    def process_item(self, item, spider):
        doc_id = item.get("id")
        if not doc_id:
            return item

        if self.db is not None:
            try:
                self.db.collection("articles").document(doc_id).set(item, merge=True)
            except Exception as e:
                logger.error(f"Firestore write failed for {doc_id}: {e}")
        elif self.fallback_file is not None:
            self.fallback_items.append(item)

        return item

    def close_spider(self, spider):
        if self.fallback_file and self.fallback_items:
            with open(self.fallback_file, "w", encoding="utf-8") as f:
                json.dump(self.fallback_items, f, indent=2, ensure_ascii=False)
            logger.info(f"Wrote {len(self.fallback_items)} articles to {self.fallback_file}")
