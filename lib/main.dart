import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/di/injection_container.dart' as di;
import 'core/theme/app_colors.dart';
import 'core/theme/theme_cubit.dart';
import 'core/utils/notification_service.dart';
import 'core/utils/voice_service.dart';
import 'core/utils/offline_storage.dart';
import 'features/metro/presentation/cubits/route_planner/route_planner_cubit.dart';
import 'features/metro/presentation/cubits/arrival_alarm/arrival_alarm_cubit.dart';
import 'features/splash/presentation/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await NotificationService.init();
  await VoiceService.init();
  await OfflineStorage.init();
  await di.init();
  
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
        Locale('fr'),
        Locale('de'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const MetroApp(),
    ),
  );
}

class MetroApp extends StatelessWidget {
  const MetroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => di.sl<ThemeCubit>()),
        BlocProvider(create: (context) => di.sl<RoutePlannerCubit>()),
        BlocProvider(create: (context) => di.sl<ArrivalAlarmCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'app_title'.tr(),
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                primary: AppColors.primary,
                secondary: AppColors.accent,
                surface: AppColors.surface,
                background: AppColors.background,
              ),
              textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme),
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                centerTitle: true,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                brightness: Brightness.dark,
                primary: AppColors.primary,
                secondary: AppColors.accent,
                surface: AppColors.surfaceDark,
                background: AppColors.backgroundDark,
              ),
              textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1F1F1F),
                foregroundColor: Colors.white,
                elevation: 0,
                centerTitle: true,
              ),
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
