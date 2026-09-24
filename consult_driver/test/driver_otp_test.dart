import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:automove_driver/features/auth/providers/auth_provider.dart';
import 'package:automove_driver/features/auth/screens/otp_screen.dart';
import 'package:automove_driver/core/widgets/driver_button.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('DriverOtpScreen renders correctly with email and pin fields', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const DriverOtpScreen(email: 'driver@carpitalconsult.com'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Security Verification'), findsOneWidget);
      expect(find.text('Verify Your Driver Account'), findsOneWidget);
      expect(find.textContaining('driver@carpitalconsult.com'), findsOneWidget);
      expect(find.byType(DriverButton), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
