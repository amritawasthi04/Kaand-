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

  /// Create Article from a Map (backward-compatible with old cache structure)
  factory Article.fromMap(Map<dynamic, dynamic> map) {
    // Backward-compatible field mapping
    final url = (map['url'] ?? map['publisherUrl'] ?? map['link']) as String? ?? '';
    final urlToImage = (map['urlToImage'] ?? map['imageUrl']) as String?;
    final publishedAt = (map['publishedAt'] ?? map['publishedDate']) as String?;
    final sectionName = (map['sectionName'] ?? map['category']) as String?;
    final sourceName = (map['sourceName'] ?? map['source']?['name']) as String?;

    return Article(
      title: map['title'] as String? ?? 'No Title',
      description: map['description'] as String?,
      urlToImage: urlToImage,
      url: url,
      author: map['author'] as String?,
      publishedAt: publishedAt,
      sourceName: sourceName,
      content: map['content'] as String?,
      sectionName: sectionName,
    );
  }

  /// NewsAPI shape (kept for fallback)
  factory Article.fromNewsApi(Map<String, dynamic> json) {
    return Article(
      title: json['title'] ?? 'No Title',
      description: json['description'],
      urlToImage: json['urlToImage'],
      url: json['url'] ?? '',
      author: json['author'],
      publishedAt: json['publishedAt'],
      sourceName: json['source']?['name'],
      content: json['content'],
    );
  }

  /// Guardian API shape
  factory Article.fromGuardian(Map<String, dynamic> json) {
    final fields = json['fields'] as Map<String, dynamic>? ?? {};
    return Article(
      title: fields['headline'] as String? ??
          json['webTitle'] as String? ??
          'No Title',
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
}