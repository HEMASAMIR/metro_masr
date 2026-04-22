import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/news_article.dart';

abstract class NewsRepository {
  Future<Either<Failure, List<NewsArticle>>> getHeadlines(String countryCode);
}
