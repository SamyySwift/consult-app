// A driver can carry several vehicles; the active-job screen must show the job
// that was opened, not just the first one, and switch between them.
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
// ignore: implementation_imports
import 'package:google_navigation_flutter/src/google_navigation_flutter_platform_interface.dart';
// ignore: implementation_imports
import 'package:google_navigation_flutter/src/method_channel/method_channel.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:automove_driver/features/jobs/providers/job_provider.dart';
import 'package:automove_driver/features/jobs/screens/active_job_screen.dart';

/// Stands in for Google's native map, which can't render in widget tests.
class FakeNavigationPlatform extends GoogleMapsNavigationPlatform {
  FakeNavigationPlatform()
      : super(NavigationSessionAPIImpl(), MapViewAPIImpl(), ImageRegistryAPIImpl(), AutoMapViewAPIImpl());

  @override
  Widget buildMapView({
    required MapViewInitializationOptions initializationOptions,
    required PlatformViewCreatedCallback onPlatformViewCreated,
    required MapReadyCallback onMapReady,
  }) =>
      const ColoredBox(color: Colors.black12);

  @override
  Widget buildNavigationView({
    required MapViewInitializationOptions initializationOptions,
    required PlatformViewCreatedCallback onPlatformViewCreated,
    required MapReadyCallback onMapReady,
  }) =>
      const ColoredBox(color: Colors.black12);
}

class FakeGeolocator extends GeolocatorPlatform {
  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<LocationPermission> checkPermission() async => LocationPermission.whileInUse;
  @override
  Stream<ServiceStatus> getServiceStatusStream() => const Stream.empty();
  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) => const Stream.empty();
}

Map<String, dynamic> job(String id, String status, String model) => {
      'id': id,
      'status': status,
      'vehicle_year': '2022',
      'vehicle_make': 'Toyota',
      'vehicle_model': model,
      'pickup_address': 'Kubwa General Hospital, Abuja',
      'pickup_lat': 9.1566,
      'pickup_lng': 7.3285,
      'dropoff_address': 'Café 24, Wuse 2, Abuja',
      'dropoff_lat': 9.0795,
      'dropoff_lng': 7.4735,
    };

final client = MockClient((req) async {
  if (req.url.path == '/api/driver/jobs') {
    return http.Response(jsonEncode([job('J1', 'confirmed', 'Camry'), job('J2', 'inTransit', 'Corolla')]), 200);
  }
  return http.Response('{}', 404);
});

/// Runs [body] with the fake API, ignoring only google_fonts' "font not
/// bundled" errors and the map's missing native channels; anything else fails.
Future<void> guarded(Future<void> Function() body) {
  final done = Completer<void>();
  runZonedGuarded(() async {
    await http.runWithClient(body, () => client);
    done.complete();
  }, (error, stack) {
    final text = error.toString();
    if (text.contains('allowRuntimeFetching') || error is PlatformException || error is MissingPluginException) {
      return;
    }
    if (!done.isCompleted) done.completeError(error, stack);
  });
  return done.future;
}

Future<void> settle(WidgetTester tester) async {
  await Future.delayed(const Duration(milliseconds: 30));
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() => dotenv.loadFromString(envString: 'API_BASE_URL=http://api.test'));
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    GoogleMapsNavigationPlatform.instance = FakeNavigationPlatform();
    GeolocatorPlatform.instance = FakeGeolocator();
  });

  testWidgets('opens the requested job and switches between active jobs', (tester) async {
    // Wider than a phone: the test font draws every glyph as a square
    tester.view.physicalSize = const Size(520 * 3, 1100 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.runAsync(() => guarded(() async {
          final jobs = JobProvider();
          await jobs.fetchJobs();
          expect(jobs.activeJobs.map((j) => j.id), ['J2', 'J1'], reason: 'handover before pickup');

          await tester.pumpWidget(ChangeNotifierProvider.value(
            value: jobs,
            child: const MaterialApp(home: ActiveJobScreen(jobId: 'J1')),
          ));
          await settle(tester);

          // Opened J1 (the pickup), even though J2 is more urgent
          expect(find.text('Confirm Vehicle Pickup'), findsOneWidget);
          expect(find.text('Finalize & Client Handover'), findsNothing);
          // The test font is wide, so the second chip sits past the screen edge
          expect(find.text('Pick up · 2022 Toyota Camry', skipOffstage: false), findsOneWidget);
          expect(find.text('Hand over · 2022 Toyota Corolla'), findsOneWidget);

          // Switch to the Corolla handover with its chip
          await tester.tap(find.text('Hand over · 2022 Toyota Corolla'));
          await settle(tester);
          expect(find.text('Finalize & Client Handover'), findsOneWidget);
          expect(find.text('Confirm Vehicle Pickup'), findsNothing);

          await tester.pumpWidget(const SizedBox());
          jobs.dispose();
        }));
  });

  testWidgets('a job opened directly shows its own next step', (tester) async {
    tester.view.physicalSize = const Size(520 * 3, 1100 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.runAsync(() => guarded(() async {
          final jobs = JobProvider();
          await jobs.fetchJobs();
          await tester.pumpWidget(ChangeNotifierProvider.value(
            value: jobs,
            child: const MaterialApp(home: ActiveJobScreen(jobId: 'J2')),
          ));
          await settle(tester);
          expect(find.text('Finalize & Client Handover'), findsOneWidget);
          expect(find.text('Confirm Vehicle Pickup'), findsNothing);
          await tester.pumpWidget(const SizedBox());
          jobs.dispose();
        }));
  });
}
