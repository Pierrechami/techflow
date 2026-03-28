class Article {
  final String url;
  final String title;
  final String? author;
  final String? snippet;
  final String? content;
  final List<String> tags;
  final String sourceName;
  final DateTime publishedAt;

  Article({
    required this.url,
    required this.title,
    this.author,
    this.snippet,
    this.content,
    required this.tags,
    required this.sourceName,
    required this.publishedAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      url: json['url'] as String,
      title: json['title'] as String,
      author: json['author'] as String?,
      snippet: json['snippet'] as String?,
      content: json['content'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      sourceName: json['source_name'] as String,
      publishedAt: DateTime.parse(json['published_at']),
    );
  }
}