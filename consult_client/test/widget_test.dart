import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:consult_logistics/app.dart';
import 'package:consult_logistics/features/auth/providers/auth_provider.dart';
import 'package:consult_logistics/features/booking/providers/booking_provider.dart';
import 'package:consult_logistics/features/auth/screens/onboarding_screen.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Carpital Consult app smoke test', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => BookingProvider()),
          ],
          child: const CarpitalConsultApp(),
        ),
      );
      expect(find.byType(MaterialApp), findsOneWidget);

      // Advance through splash delay cleanly
      await tester.pump(const Duration(milliseconds: 3000));
    });
  });

  testWidgets('OnboardingScreen renders editorial headline, badges, and slide action button',
      (WidgetTester tester) async {
    await tester.runAsync(() async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('CARPITAL CONSULT'), findsNothing);
      expect(find.textContaining('Relocate Your Vehicle'), findsOneWidget);
      expect(find.text('Slide to Get Started'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Live GPS'), findsOneWidget);
      expect(find.text('4.9 ★'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
