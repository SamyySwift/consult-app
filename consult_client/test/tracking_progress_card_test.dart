import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:consult_logistics/features/booking/models/booking_model.dart';
import 'package:consult_logistics/features/tracking/screens/tracking_screen.dart';

/// A confirmed booking whose driver was last reported [age] ago, about 5 km
/// from the pickup.
BookingModel bookingSeen(Duration age) => BookingModel.fromSupabaseMap({
      'id': 'B1',
      'status': 'confirmed',
      'pickup_address': 'Jabi Lake Mall, Abuja',
      'pickup_lat': 9.0765,
      'pickup_lng': 7.4250,
      'dropoff_address': 'Kubwa, Abuja',
      'dropoff_lat': 9.1566,
      'dropoff_lng': 7.3285,
      'driver_lat': 9.0765,
      'driver_lng': 7.4705,
      'driver_location_at': DateTime.now().subtract(age).toUtc().toIso8601String(),
    });

Future<void> pumpCard(WidgetTester tester, BookingModel booking) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: LiveProgressCard(booking: booking)),
  ));
}

void main() {
  testWidgets('an old position gives no arrival estimate and says how old it is', (tester) async {
    await pumpCard(tester, bookingSeen(const Duration(minutes: 29)));

    expect(find.textContaining('km to pickup'), findsOneWidget);
    expect(find.text('Based on where the driver was 29 min ago'), findsOneWidget);
    expect(find.textContaining('arrival'), findsNothing);
    expect(find.textContaining('Arrives'), findsNothing);
  });

  testWidgets('a fresh position shows the arrival estimate', (tester) async {
    await pumpCard(tester, bookingSeen(const Duration(seconds: 10)));

    expect(find.textContaining('km to pickup'), findsOneWidget);
    expect(find.textContaining('Estimated arrival in'), findsOneWidget);
    expect(find.textContaining('Based on where'), findsNothing);
  });

  testWidgets('a driver last seen at the pickup is not shown as arriving now', (tester) async {
    final booking = bookingSeen(const Duration(minutes: 10));
    await pumpCard(
      tester,
      BookingModel.fromSupabaseMap({
        'id': booking.id,
        'status': 'confirmed',
        'pickup_lat': 9.0765,
        'pickup_lng': 7.4250,
        'dropoff_lat': 9.1566,
        'dropoff_lng': 7.3285,
        'driver_lat': 9.0766,
        'driver_lng': 7.4251,
        'driver_location_at': booking.driverLocationAt!.toIso8601String(),
      }),
    );

    expect(find.text('Driver was at the pickup point'), findsOneWidget);
    expect(find.text('Based on where the driver was 10 min ago'), findsOneWidget);
    expect(find.text('Arriving now'), findsNothing);
  });
}
