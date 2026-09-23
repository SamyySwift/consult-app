import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:consult_logistics/core/widgets/slide_action_button.dart';

void main() {
  testWidgets('SlideActionButton renders label and icon', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: SlideActionButton(
                label: 'Get Started',
                onSlideComplete: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Get Started'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
  });

  testWidgets('SlideActionButton triggers onSlideComplete when dragged past threshold',
      (WidgetTester tester) async {
    bool completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: SlideActionButton(
                label: 'Slide to Continue',
                threshold: 0.5,
                onSlideComplete: () {
                  completed = true;
                },
              ),
            ),
          ),
        ),
      ),
    );

    final knobFinder = find.byIcon(Icons.arrow_forward_rounded);
    expect(knobFinder, findsOneWidget);

    // Drag the knob across to the right
    await tester.drag(knobFinder, const Offset(260, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(completed, isTrue);

    // Allow the post-complete reset timer to finish cleanly
    await tester.pump(const Duration(milliseconds: 700));
  });

  testWidgets('SlideActionButton does not trigger if released before threshold',
      (WidgetTester tester) async {
    bool completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: SlideActionButton(
                label: 'Slide to Continue',
                threshold: 0.7,
                onSlideComplete: () {
                  completed = true;
                },
              ),
            ),
          ),
        ),
      ),
    );

    final knobFinder = find.byIcon(Icons.arrow_forward_rounded);

    // Drag only 40 pixels (far below threshold)
    await tester.drag(knobFinder, const Offset(40, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(completed, isFalse);
  });

  testWidgets('SlideActionButton triggers on tap when allowTapToSlide is true',
      (WidgetTester tester) async {
    bool completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: SlideActionButton(
                label: 'Tap or Slide',
                allowTapToSlide: true,
                onSlideComplete: () {
                  completed = true;
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(SlideActionButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(completed, isTrue);

    // Allow the post-complete reset timer to finish cleanly
    await tester.pump(const Duration(milliseconds: 700));
  });
}
