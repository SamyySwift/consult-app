// While turn-by-turn guidance runs, driver positions come from the Navigation
// SDK (with ETA) and the separate GPS stream pauses; afterwards GPS resumes.
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:automove_driver/core/services/navigation_service.dart';
import 'package:automove_driver/features/jobs/providers/job_provider.dart';

class FakeGeolocator extends GeolocatorPlatform {
  final positions = StreamController<Position>.broadcast();
  int opened = 0;
  int active = 0;
  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<LocationPermission> checkPermission() async => LocationPermission.whileInUse;
  @override
  Future<LocationPermission> requestPermission() async => LocationPermission.whileInUse;
  @override
  Stream<ServiceStatus> getServiceStatusStream() => const Stream.empty();
  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    opened++;
    late StreamController<Position> c;
    c = StreamController<Position>(
      onListen: () => active++,
      onCancel: () => active--,
    );
    positions.stream.listen(c.add);
    return c.stream;
  }
}

Position pos(double lat, double lng) => Position(
      latitude: lat, longitude: lng, timestamp: DateTime.now(), accuracy: 5,
      altitude: 0, altitudeAccuracy: 0, heading: 90, headingAccuracy: 0, speed: 10, speedAccuracy: 0,
    );

void main() {
  setUpAll(() => dotenv.loadFromString(envString: 'API_BASE_URL=http://api.test'));

  testWidgets('guidance takes over location updates and hands them back', (tester) async {
    final fake = FakeGeolocator();
    GeolocatorPlatform.instance = fake;
    final posts = <Map<String, dynamic>>[];
    final client = MockClient((req) async {
      if (req.url.path == '/api/driver/jobs') {
        return http.Response(jsonEncode([{'id': 'J1', 'status': 'confirmed'}]), 200);
      }
      if (req.url.path == '/api/driver/location') {
        posts.add(jsonDecode(req.body) as Map<String, dynamic>);
      }
      return http.Response('{}', 200);
    });
    final nav = NavigationService.instance;
    Future<void> flush() => tester.runAsync(() => Future.delayed(const Duration(milliseconds: 30)));

    await http.runWithClient(() async {
      final jobs = JobProvider();
      await tester.runAsync(() => jobs.fetchJobs());
      await flush();
      expect(fake.active, 1, reason: 'GPS stream runs for the active job');

      // GPS positions are posted without navigation fields
      fake.positions.add(pos(6.45, 3.47));
      await flush();
      expect(posts.last['jobId'], 'J1');
      expect(posts.last.containsKey('eta_s'), isFalse);

      // Guidance starts: GPS stream stops, positions come from navigation
      nav.guiding.value = true;
      await flush();
      expect(fake.active, 0, reason: 'GPS stream paused while guiding');
      final before = posts.length;
      nav.debugEmitLocation(const NavLocation(lat: 6.4500, lng: 3.4700, heading: 45, etaS: 1200, remainingM: 9000));
      await flush();
      expect(posts.length, before + 1);
      expect(posts.last['eta_s'], 1200);
      expect(posts.last['remaining_m'], 9000);
      expect(posts.last['heading'], 45);

      // Jitter under 2 m within 15 s is not sent
      nav.debugEmitLocation(const NavLocation(lat: 6.450005, lng: 3.470005, etaS: 1195, remainingM: 8990));
      await flush();
      expect(posts.length, before + 1, reason: 'sub-2 m jitter throttled');

      // Real movement is sent
      nav.debugEmitLocation(const NavLocation(lat: 6.4510, lng: 3.4710, etaS: 1150, remainingM: 8800));
      await flush();
      expect(posts.length, before + 2);

      // fetchJobs polling must not reopen the GPS stream mid-guidance
      await tester.runAsync(() => jobs.fetchJobs(silent: true));
      await flush();
      expect(fake.active, 0, reason: 'polling keeps GPS paused while guiding');

      // Guidance ends: navigation positions ignored, GPS stream back
      nav.guiding.value = false;
      await flush();
      expect(fake.active, 1, reason: 'GPS stream resumes after guidance');
      final after = posts.length;
      nav.debugEmitLocation(const NavLocation(lat: 6.46, lng: 3.48));
      await flush();
      expect(posts.length, after, reason: 'no navigation posts when not guiding');

      await tester.pumpWidget(const SizedBox());
      jobs.dispose();
    }, () => client);
  });
}
