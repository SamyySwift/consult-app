import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:consult_logistics/app.dart';
import 'package:consult_logistics/features/auth/providers/auth_provider.dart';
import 'package:consult_logistics/features/booking/providers/booking_provider.dart';

void main() {
  testWidgets('Carpital Consult app smoke test', (WidgetTester tester) async {
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
  });
}
