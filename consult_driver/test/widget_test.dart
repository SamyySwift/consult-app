import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:automove_driver/app.dart';
import 'package:automove_driver/features/auth/providers/auth_provider.dart';
import 'package:automove_driver/features/jobs/providers/job_provider.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Driver app smoke test', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => JobProvider()),
          ],
          child: const CarpitalConsultDriverApp(),
        ),
      );
      expect(find.byType(MaterialApp), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
