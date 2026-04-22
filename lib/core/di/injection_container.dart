import 'package:get_it/get_it.dart';
import '../../features/metro/data/repositories/metro_repository_impl.dart';
import '../../features/metro/domain/repositories/metro_repository.dart';
import '../../features/metro/presentation/cubits/route_planner/route_planner_cubit.dart';
import '../../features/metro/presentation/cubits/nearby_stations_cubit.dart';
import '../../features/metro/presentation/cubits/arrival_alarm/arrival_alarm_cubit.dart';
import '../../features/community/domain/repositories/community_repository.dart';
import '../../features/community/data/repositories/community_repository_impl.dart';
import '../../features/community/presentation/cubits/community_cubit.dart';
import '../../core/theme/theme_cubit.dart';
import 'package:dio/dio.dart';
import '../../features/news/data/datasources/news_remote_datasource.dart';
import '../../features/news/data/repositories/news_repository_impl.dart';
import '../../features/news/domain/repositories/news_repository.dart';
import '../../features/news/domain/usecases/get_headlines.dart';
import '../../features/news/presentation/bloc/news_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core
  sl.registerLazySingleton(() => ThemeCubit());

  // Features - Metro / Community
  // Cubits
  sl.registerFactory(() => RoutePlannerCubit(sl()));
  sl.registerFactory(() => NearbyStationsCubit(sl()));
  sl.registerFactory(() => ArrivalAlarmCubit());
  sl.registerFactory(() => CommunityCubit(sl()));

  // Repositories
  sl.registerLazySingleton<MetroRepository>(() => MetroRepositoryImpl());
  sl.registerLazySingleton<CommunityRepository>(() => CommunityRepositoryImpl());

  // Ext
  sl.registerLazySingleton(() => Dio());

  // News Feature
  sl.registerFactory(() => NewsBloc(getHeadlines: sl()));
  sl.registerLazySingleton(() => GetHeadlines(sl()));
  sl.registerLazySingleton<NewsRepository>(() => NewsRepositoryImpl(remoteDataSource: sl()));
  sl.registerLazySingleton<NewsRemoteDataSource>(() => NewsRemoteDataSourceImpl(dio: sl()));
}
