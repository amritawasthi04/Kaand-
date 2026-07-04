class Article {
  final String title;
  final String? description;
  final String? summary;
  final String? urlToImage;
  final String url;
  final String? author;
  final String? publishedAt;
  final String? sourceName;
  final String? content;
  final String? sectionName;
  final int? readTime;
  final String? language;
  final List<String>? tags;

  Article({
    required this.title,
    this.description,
    this.summary,
    this.urlToImage,
    required this.url,
    this.author,
    this.publishedAt,
    this.sourceName,
    this.content,
    this.sectionName,
    this.readTime,
    this.language,
    this.tags,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'summary': summary,
      'urlToImage': urlToImage,
      'url': url,
      'author': author,
      'publishedAt': publishedAt,
      'sourceName': sourceName,
      'content': content,
      'sectionName': sectionName,
      'readTime': readTime,
      'language': language,
      'tags': tags,
    };
  }

  factory Article.fromMap(Map<dynamic, dynamic> map) {
    return Article(
      title: map['title'] as String? ?? 'No Title',
      description: map['description'] as String?,
      summary: map['summary'] as String?,
      urlToImage: map['urlToImage'] as String?,
      url: map['url'] as String? ?? '',
      author: map['author'] as String?,
      publishedAt: map['publishedAt'] as String?,
      sourceName: map['sourceName'] as String?,
      content: map['content'] as String?,
      sectionName: map['sectionName'] as String?,
      readTime: map['readTime'] as int?,
      language: map['language'] as String?,
      tags: map['tags'] != null ? List<String>.from(map['tags'] as Iterable) : null,
    );
  }

  factory Article.fromJson(Map<String, dynamic> json) {
    final tagsRaw = json['tags'];
    List<String>? tagsList;
    if (tagsRaw is List) {
      tagsList = tagsRaw.map((e) => e.toString()).toList();
    }
    return Article(
      title: json['title'] as String? ?? 'No Title',
      description: json['description'] as String?,
      summary: json['summary'] as String?,
      urlToImage: json['image'] as String? ?? json['urlToImage'] as String?,
      url: json['url'] as String? ?? '',
      author: json['author'] as String? ?? 'Staff',
      publishedAt: json['publishedAt'] as String?,
      sourceName: json['source'] as String? ?? 'News',
      content: json['content'] as String?,
      sectionName: json['category'] as String? ?? json['sectionName'] as String?,
      readTime: json['readTime'] as int?,
      language: json['language'] as String?,
      tags: tagsList,
    );
  }

  Article copyWithScrapeDetails({
    String? description,
    String? imageUrl,
    String? resolvedUrl,
    String? summary,
    String? content,
    int? readTime,
    String? author,
    List<String>? tags,
  }) {
    return Article(
      title: title,
      description: description ?? this.description,
      summary: summary ?? this.summary,
      urlToImage: imageUrl ?? this.urlToImage,
      url: resolvedUrl ?? url,
      author: author ?? this.author,
      publishedAt: publishedAt,
      sourceName: sourceName,
      content: content ?? this.content,
      sectionName: sectionName,
      readTime: readTime ?? this.readTime,
      language: language,
      tags: tags ?? this.tags,
    );
  }

  String get relativeTime {
    if (publishedAt == null) return 'recently';
    try {
      final date = DateTime.parse(publishedAt!);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y';
      if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo';
      if (diff.inDays > 0) return '${diff.inDays}d';
      if (diff.inHours > 0) return '${diff.inHours}h';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m';
      return 'now';
    } catch (_) {
      return 'recently';
    }
  }
}
