import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:automove_driver/core/theme/driver_colors.dart';
import 'package:automove_driver/core/utils/motion.dart';
import 'package:automove_driver/core/widgets/surface.dart';
import 'package:automove_driver/core/widgets/tap_target.dart';

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
      await tester.tapAt(
        tester.getTopLeft(find.byType(TapTarget)) + const Offset(2, 2),
      );
      expect(taps, 1);
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

    testWidgets('motionAware() starts from the beginning when off', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          reduce: false,
          child: (context) => const Text(
            'Hi',
          ).motionAware(context).fadeIn(duration: const Duration(seconds: 1)),
        ),
      );
      final fade = tester.widget<FadeTransition>(find.byType(FadeTransition));
      expect(fade.opacity.value, lessThan(1));
      await tester.pumpAndSettle();
    });
  });

  group('SurfaceCard', () {
    testWidgets('is flat: solid surface, hairline border, no blur', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: SurfaceCard(child: Text('Job'))),
      );
      expect(find.byType(BackdropFilter), findsNothing);
      final box = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(SurfaceCard),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = box.decoration! as BoxDecoration;
      expect(decoration.color, DriverColors.surface);
      expect((decoration.border! as Border).top.color, DriverColors.border);
    });
  });
}
