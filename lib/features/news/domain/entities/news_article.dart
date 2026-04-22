import 'package:equatable/equatable.dart';

class NewsArticle extends Equatable {
  final String title;
  final String description;
  final String url;
  final String? imageUrl;
  final DateTime? publishedAt;
  final String sourceName;

  const NewsArticle({
    required this.title,
    required this.description,
    required this.url,
    this.imageUrl,
    this.publishedAt,
    required this.sourceName,
  });

  @override
  List<Object?> get props => [title, url, imageUrl, sourceName];
}
