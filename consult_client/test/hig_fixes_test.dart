import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:consult_logistics/core/utils/motion.dart';
import 'package:consult_logistics/core/widgets/status_badge.dart';
import 'package:consult_logistics/core/widgets/tap_target.dart';
import 'package:consult_logistics/features/booking/models/booking_model.dart';
import 'package:consult_logistics/features/payments/screens/payment_history_screen.dart';

void main() {
  group('TapTarget', () {
    testWidgets('gives a small child a 44x44 hit region', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TapTarget(
                onTap: () => taps++,
                child: const SizedBox(width: 20, height: 16),
              ),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(TapTarget));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));

      // A tap near the corner, outside the 20x16 child, still counts.
      final topLeft = tester.getTopLeft(find.byType(TapTarget));
      await tester.tapAt(topLeft + const Offset(2, 2));
      expect(taps, 1);
    });

    testWidgets('is announced as a button', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: TapTarget(
            onTap: () {},
            semanticLabel: 'See all',
            child: const Text('See All'),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(TapTarget)),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          label: 'See all\nSee All',
        ),
      );
      handle.dispose();
    });
  });

  group('Reduce Motion', () {
    Widget host({
      required bool reduce,
      required Widget Function(BuildContext) child,
    }) => MediaQuery(
      data: MediaQueryData(disableAnimations: reduce),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(builder: child),
      ),
    );

    testWidgets('entrance() returns the child untouched when on', (
      tester,
    ) async {
      const key = Key('content');
      late Widget result;
      await tester.pumpWidget(
        host(
          reduce: true,
          child: (context) =>
              result = const SizedBox(key: key).entrance(context),
        ),
      );
      expect(result, isA<SizedBox>());
      expect(find.byKey(key), findsOneWidget);
    });

    testWidgets('entrance() animates when off', (tester) async {
      late Widget result;
      await tester.pumpWidget(
        host(
          reduce: false,
          child: (context) => result = const SizedBox().entrance(context),
        ),
      );
      expect(result, isNot(isA<SizedBox>()));
      await tester.pumpAndSettle();
    });

    testWidgets('motionAware() shows the end state at once when on', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          reduce: true,
          child: (context) => const Text('Hi')
              .motionAware(context, delay: const Duration(seconds: 5))
              .fadeIn(duration: const Duration(seconds: 1)),
        ),
      );
      // No time has passed, yet the text is already fully opaque.
      final opacities = tester.widgetList<Opacity>(find.byType(Opacity));
      for (final o in opacities) {
        expect(o.opacity, 1);
      }
      final fades = tester.widgetList<FadeTransition>(
        find.byType(FadeTransition),
      );
      expect(fades, isNotEmpty);
      for (final f in fades) {
        expect(f.opacity.value, 1);
      }
      // Animate always schedules a zero-length start timer; let it fire.
      await tester.pump(const Duration(milliseconds: 1));
    });
  });

  group('Payments', () {
    BookingModel booking(String status, double amount) =>
        BookingModel.fromSupabaseMap({
          'id': status,
          'status': status,
          'total_amount': amount,
        });

    test('Total Spent leaves out pending and cancelled bookings', () {
      final bookings = [
        booking('pending', 75000),
        booking('cancelled', 120000),
        booking('confirmed', 100000),
        booking('in_transit', 50000),
        booking('delivered', 25000),
      ];
      expect(totalPaid(bookings), 175000);
    });

    test('Total Spent is zero with nothing paid', () {
      expect(totalPaid([booking('pending', 75000)]), 0);
      expect(totalPaid(const []), 0);
    });
  });

  group('isTrackable', () {
    test('covers every status where a driver has the vehicle', () {
      final trackable = BookingStatusEnum.values.where((s) => s.isTrackable);
      expect(trackable, [
        BookingStatusEnum.pickedUp,
        BookingStatusEnum.inTransit,
        BookingStatusEnum.outForDelivery,
      ]);
    });
  });
}
