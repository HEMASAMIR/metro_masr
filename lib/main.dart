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
              scaffoldBackgroundColor: AppColors.background,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                primary: AppColors.primary,
                secondary: AppColors.accent,
                surface: AppColors.surface,
                background: AppColors.background,
              ),
              textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme),
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
                centerTitle: true,
                scrolledUnderElevation: 0,
              ),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                backgroundColor: AppColors.surface,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: AppColors.textSecondary,
                elevation: 8,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: AppColors.backgroundDark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                brightness: Brightness.dark,
                primary: AppColors.accent, // Use accent for primary pop in dark mode
                secondary: AppColors.accent,
                surface: AppColors.surfaceDark,
                background: AppColors.backgroundDark,
              ),
              textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.surfaceDark,
                foregroundColor: Colors.white,
                elevation: 0,
                centerTitle: true,
                scrolledUnderElevation: 0,
              ),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                backgroundColor: AppColors.surfaceDark,
                selectedItemColor: AppColors.accent,
                unselectedItemColor: AppColors.textSecondaryDark,
                elevation: 8,
              ),
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
