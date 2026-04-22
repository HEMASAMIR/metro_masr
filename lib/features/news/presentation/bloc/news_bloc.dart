import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/news_article.dart';
import '../../domain/usecases/get_headlines.dart';

abstract class NewsEvent {}

class FetchNews extends NewsEvent {
  final String countryCode;
  FetchNews({this.countryCode = 'eg'});
}

abstract class NewsState {}

class NewsInitial extends NewsState {}
class NewsLoading extends NewsState {}
class NewsLoaded extends NewsState {
  final List<NewsArticle> articles;
  NewsLoaded({required this.articles});
}
class NewsError extends NewsState {
  final String message;
  NewsError({required this.message});
}

class NewsBloc extends Bloc<NewsEvent, NewsState> {
  final GetHeadlines getHeadlines;

  NewsBloc({required this.getHeadlines}) : super(NewsInitial()) {
    on<FetchNews>((event, emit) async {
      emit(NewsLoading());
      final result = await getHeadlines(event.countryCode);
      result.fold(
        (failure) => emit(NewsError(message: failure.message)),
        (articles) => emit(NewsLoaded(articles: articles)),
      );
    });
  }
}
