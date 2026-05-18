import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rafiq_metrro/main.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rafiq_metrro/core/utils/offline_storage.dart';
import 'package:rafiq_metrro/core/di/injection_container.dart' as di;

void main() {
  testWidgets('Theme toggle text triggers exception', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await AppStorage.init();
    await di.init();
    
    // Catch errors
    FlutterError.onError = (details) {
      print('FLUTTER ERROR: ${details.exceptionAsString()}');
    };

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/translations',
        child: const MetroApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Find the toggle button
    final toggleAction = find.byIcon(Icons.dark_mode_rounded).first;
    expect(toggleAction, findsOneWidget);

    print('Tapping toggle...');
    await tester.tap(toggleAction);
    await tester.pumpAndSettle();
    
    print('Toggle successful, no exceptions thrown.');
  });
}
