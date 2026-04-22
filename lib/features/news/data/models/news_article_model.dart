import '../../domain/entities/news_article.dart';

class NewsArticleModel extends NewsArticle {
  const NewsArticleModel({
    required super.title,
    required super.description,
    required super.url,
    super.imageUrl,
    super.publishedAt,
    required super.sourceName,
  });

  factory NewsArticleModel.fromJson(Map<String, dynamic> json) {
    return NewsArticleModel(
      title: json['title'] ?? 'بدون عنوان',
      description: json['description'] ?? 'لا يوجد تفاصيل إضافية لهذا الخبر.',
      url: json['url'] ?? '',
      imageUrl: json['urlToImage'],
      publishedAt: json['publishedAt'] != null ? DateTime.tryParse(json['publishedAt']) : null,
      sourceName: json['source']?['name'] ?? 'مجهول',
    );
  }
}
