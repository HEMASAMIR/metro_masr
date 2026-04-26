import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/offline_storage.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(AppStorage.getThemeMode());

  void toggleTheme() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    AppStorage.saveThemeMode(next);
    emit(next);
  }

  void setTheme(ThemeMode mode) {
    AppStorage.saveThemeMode(mode);
    emit(mode);
  }
}
