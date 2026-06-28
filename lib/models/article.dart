class Article {
  final String title;
  final String? description;
  final String? urlToImage;
  final String url;
  final String? author;
  final String? publishedAt;
  final String? sourceName;
  final String? content;
  final String? sectionName;

  Article({
    required this.title,
    this.description,
    this.urlToImage,
    required this.url,
    this.author,
    this.publishedAt,
    this.sourceName,
    this.content,
    this.sectionName,
  });

  /// Convert Article to a Map for serialization
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'urlToImage': urlToImage,
      'url': url,
      'author': author,
      'publishedAt': publishedAt,
      'sourceName': sourceName,
      'content': content,
      'sectionName': sectionName,
    };
  }

  /// Create Article from a Map (for Hive and Firestore caching)
  factory Article.fromMap(Map<dynamic, dynamic> map) {
    return Article(
      title: map['title'] as String? ?? 'No Title',
      description: map['description'] as String?,
      urlToImage: map['urlToImage'] as String?,
      url: map['url'] as String? ?? '',
      author: map['author'] as String?,
      publishedAt: map['publishedAt'] as String?,
      sourceName: map['sourceName'] as String?,
      content: map['content'] as String?,
      sectionName: map['sectionName'] as String?,
    );
  }

  /// Create Article from the Cloudflare Worker JSON response
  factory Article.fromWorkerJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] as String? ?? 'No Title',
      description: json['description'] as String?,
      urlToImage: json['imageUrl'] as String?,
      url: json['url'] as String? ?? '',
      author: json['author'] as String?,
      publishedAt: json['publishedAt'] as String?,
      sourceName: json['source'] as String? ?? 'News',
      content: json['content'] as String?,
      sectionName: json['sectionName'] as String?,
    );
  }

  /// Create Article from The Guardian API response shape
  factory Article.fromGuardian(Map<String, dynamic> json) {
    final fields = json['fields'] as Map<String, dynamic>? ?? {};
    return Article(
      title: fields['headline'] as String? ?? json['webTitle'] as String? ?? 'No Title',
      description: fields['trailText'] as String?,
      urlToImage: fields['thumbnail'] as String?,
      url: json['webUrl'] as String? ?? '',
      author: fields['byline'] as String?,
      publishedAt: json['webPublicationDate'] as String?,
      sourceName: 'The Guardian',
      content: fields['bodyText'] as String?,
      sectionName: json['sectionName'] as String?,
    );
  }

  /// Creates a copy of the article with updated description, image, and resolved URL from a details scrape
  Article copyWithScrapeDetails({
    required String? description,
    required String? imageUrl,
    String? resolvedUrl,
  }) {
    return Article(
      title: title,
      description: description ?? this.description,
      urlToImage: imageUrl ?? this.urlToImage,
      url: resolvedUrl ?? url,
      author: author,
      publishedAt: publishedAt,
      sourceName: sourceName,
      content: content,
      sectionName: sectionName,
    );
  }
}
