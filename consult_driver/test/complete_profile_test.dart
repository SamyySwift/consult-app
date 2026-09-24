import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:automove_driver/features/auth/providers/auth_provider.dart';
import 'package:automove_driver/features/auth/screens/complete_profile_screen.dart';
import 'package:automove_driver/core/widgets/driver_button.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('CompleteProfileScreen renders all KYC and personal info fields', (WidgetTester tester) async {
    await tester.runAsync(() async {
      final auth = AuthProvider();
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: auth,
            child: const CompleteProfileScreen(),
          ),
        ),
      );

      // Allow _initSession async microtasks and animations to complete
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Complete Driver Profile'), findsOneWidget);
      expect(find.text('1. Driver’s Personal Information'), findsOneWidget);
      expect(find.text('Full Legal Name'), findsOneWidget);
      expect(find.text('Date of Birth'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Residential Address'), findsOneWidget);
      expect(find.text('2. Emergency Contact / Next of Kin'), findsOneWidget);
      expect(find.text('3. Identification & Verification'), findsOneWidget);
      expect(find.text('NIN Number (National Identity)'), findsOneWidget);
      expect(find.text('Driver’s Licence Image Upload'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byType(DriverButton),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byType(DriverButton), findsOneWidget);
      if (!auth.isLoading) {
        expect(find.text('Complete & Save Profile'), findsOneWidget);
      }

      await tester.pumpWidget(const SizedBox());
    });
  });
}
