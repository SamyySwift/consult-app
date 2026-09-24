import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:automove_driver/features/auth/providers/auth_provider.dart';
import 'package:automove_driver/features/profile/screens/profile_screen.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('ProfileScreen renders incomplete KYC banner, progress, and complete profile buttons',
      (WidgetTester tester) async {
    await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues({
        'driver_logged_in': true,
        'driver_id': 'drv_001',
        'driver_first_name': 'Adewale',
        'driver_last_name': 'Okonkwo',
        'driver_email': 'driver@carpitalconsult.com',
        'driver_phone': '+234 812 345 6789',
        'driver_profile_completed': false,
      });

      tester.view.physicalSize = const Size(1080, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final auth = AuthProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: auth,
            child: const ProfileScreen(),
          ),
        ),
      );

      // Allow _initSession async microtasks to load driver from SharedPreferences
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Driver Profile'), findsOneWidget);
      expect(find.text('Driver’s Personal Information'), findsOneWidget);
      expect(find.text('Emergency Contact / Next of Kin'), findsOneWidget);
      expect(find.text('Identification & KYC Verification'), findsOneWidget);
      expect(find.text('Vehicle & Logistics Rig'), findsOneWidget);
      expect(find.text('Complete / Edit KYC Profile'), findsOneWidget);

      // Incomplete state assertions
      expect(find.textContaining('Action Required: Complete Profile'), findsOneWidget);
      expect(find.text('Complete Profile Now'), findsWidgets);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('ProfileScreen renders 100% complete KYC badge and Edit KYC Profile when profile is completed',
      (WidgetTester tester) async {
    await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues({
        'driver_logged_in': true,
        'driver_id': 'drv_002',
        'driver_first_name': 'Chidi',
        'driver_last_name': 'Eze',
        'driver_email': 'chidi@carpitalconsult.com',
        'driver_phone': '+234 809 111 2222',
        'driver_profile_completed': true,
        'driver_dob': '15/08/1992',
        'driver_address': '12 Victoria Island Road',
        'driver_state_lga': 'Lagos, Eti-Osa',
        'driver_emergency_name': 'Ngozi Eze',
        'driver_emergency_phone': '+234 809 999 8888',
        'driver_emergency_relationship': 'Spouse',
        'driver_nin': '12345678901',
        'driver_license_image': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      });

      tester.view.physicalSize = const Size(1080, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final auth = AuthProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: auth,
            child: const ProfileScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Driver Profile'), findsOneWidget);
      expect(find.text('KYC Profile Complete (100%)'), findsOneWidget);
      expect(find.text('Edit KYC Profile'), findsOneWidget);
      expect(find.text('Licence Document Uploaded'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
