import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/news_article.dart';
import '../../domain/repositories/news_repository.dart';
import '../datasources/news_remote_datasource.dart';

class NewsRepositoryImpl implements NewsRepository {
  final NewsRemoteDataSource remoteDataSource;

  NewsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<NewsArticle>>> getHeadlines(String countryCode) async {
    try {
      final remoteArticles = await remoteDataSource.getTopHeadlines(countryCode);
      return Right(remoteArticles);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
