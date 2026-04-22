import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/news_article.dart';
import '../repositories/news_repository.dart';

class GetHeadlines {
  final NewsRepository repository;

  GetHeadlines(this.repository);

  Future<Either<Failure, List<NewsArticle>>> call(String countryCode) async {
    return await repository.getHeadlines(countryCode);
  }
}
