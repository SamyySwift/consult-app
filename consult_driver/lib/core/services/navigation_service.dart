import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';

/// Which part of a job the driver is navigating.
enum NavLeg { toPickup, toDropoff }

/// A road-snapped position from turn-by-turn navigation, with the direction
/// of travel and what's left of the route.
class NavLocation {
  final double lat;
  final double lng;
  /// Degrees clockwise from north; null while stationary.
  final double? heading;
  /// Metres per second, estimated from consecutive positions.
  final double? speed;
  final double? etaS;
  final double? remainingM;

  const NavLocation({
    required this.lat,
    required this.lng,
    this.heading,
    this.speed,
    this.etaS,
    this.remainingM,
  });
}

/// Time and road distance left to the current destination.
class NavProgress {
  final double remainingS;
  final double remainingM;

  const NavProgress({required this.remainingS, required this.remainingM});
}

/// Why navigation couldn't start, with a message for the driver.
class NavStartResult {
  final bool started;
  final String? message;

  const NavStartResult.ok() : started = true, message = null;
  const NavStartResult.failed(this.message) : started = false;
}

/// In-app turn-by-turn navigation using the Google Navigation SDK.
///
/// The session lives for the whole app run so guidance continues when the
/// driver leaves the job screen or locks the phone; only guidance itself is
/// started and stopped per leg.
class NavigationService {
  NavigationService._();
  static final NavigationService instance = NavigationService._();

  // Movement below this is GPS jitter, not a direction of travel
  static const _headingMinMoveM = 3.0;
  static const _firstFixTimeout = Duration(seconds: 20);

  /// True once a navigation session exists (terms accepted and initialised).
  final ValueNotifier<bool> sessionReady = ValueNotifier(false);

  /// True while turn-by-turn guidance is running.
  final ValueNotifier<bool> guiding = ValueNotifier(false);

  /// Time and distance left while guiding.
  final ValueNotifier<NavProgress?> progress = ValueNotifier(null);

  NavLeg? _leg;
  NavLeg? get leg => _leg;

  final _locations = StreamController<NavLocation>.broadcast();
  /// Road-snapped positions while the session is active.
  Stream<NavLocation> get locations => _locations.stream;

  final _arrivals = StreamController<NavLeg>.broadcast();
  /// Emits the leg the driver just arrived at the end of.
  Stream<NavLeg> get arrivals => _arrivals.stream;

  bool _listenersAttached = false;
  Completer<void>? _firstFix;
  LatLng? _lastLocation;
  DateTime? _lastLocationAt;
  double? _lastHeading;

  /// Starts the session without any prompt if the driver accepted Google's
  /// terms before, e.g. after an app restart mid-delivery, and picks up
  /// guidance that was still running.
  Future<void> restoreIfPossible() async {
    try {
      if (!await GoogleMapsNavigator.areTermsAccepted()) return;
      await _ensureSession();
      guiding.value = await GoogleMapsNavigator.isGuidanceRunning();
    } catch (e) {
      debugPrint('Navigation restore failed: $e');
    }
  }

  /// Shows Google's terms if needed, then starts guidance to the destination.
  Future<NavStartResult> start({
    required NavLeg leg,
    required double lat,
    required double lng,
    required String title,
  }) async {
    try {
      if (!await GoogleMapsNavigator.areTermsAccepted()) {
        final accepted = await GoogleMapsNavigator.showTermsAndConditionsDialog(
          'Carpital Consult Driver',
          'Carpital Consult',
        );
        if (!accepted) {
          return const NavStartResult.failed(
            'In-app navigation needs Google\'s terms to be accepted.',
          );
        }
      }

      await _ensureSession();
      await _waitForFirstFix();

      final status = await GoogleMapsNavigator.setDestinations(
        Destinations(
          waypoints: [
            NavigationWaypoint.withLatLngTarget(
              title: title,
              target: LatLng(latitude: lat, longitude: lng),
            ),
          ],
          // The job map draws its own pickup and drop-off markers
          displayOptions: NavigationDisplayOptions(showDestinationMarkers: false),
          routingOptions: RoutingOptions(travelMode: NavigationTravelMode.driving),
        ),
      );
      if (status != NavigationRouteStatus.statusOk) {
        return NavStartResult.failed(_routeStatusMessage(status));
      }

      await GoogleMapsNavigator.setAudioGuidance(
        NavigationAudioGuidanceSettings(
          guidanceType: NavigationAudioGuidanceType.alertsAndGuidance,
          isBluetoothAudioEnabled: true,
        ),
      );
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // Keep guiding (and sending the driver's position) with the screen locked
        await GoogleMapsNavigator.allowBackgroundLocationUpdates(true);
      }

      await GoogleMapsNavigator.startGuidance();
      _leg = leg;
      guiding.value = true;
      return const NavStartResult.ok();
    } catch (e) {
      debugPrint('Navigation start failed: $e');
      return const NavStartResult.failed('Navigation couldn\'t start. Please try again.');
    }
  }

  /// Stops guidance and clears the route. The session stays for next time.
  Future<void> stop() async {
    _leg = null;
    progress.value = null;
    if (!guiding.value && !sessionReady.value) return;
    guiding.value = false;
    try {
      await GoogleMapsNavigator.stopGuidance();
      await GoogleMapsNavigator.clearDestinations();
    } catch (e) {
      debugPrint('Navigation stop failed: $e');
    }
  }

  /// Feeds a position as if it came from the SDK, for unit tests.
  @visibleForTesting
  void debugEmitLocation(NavLocation location) => _locations.add(location);

  /// Drives the current route with simulated GPS, for testing on
  /// emulators and simulators. Debug builds only.
  Future<void> simulateDrive() async {
    if (!kDebugMode || !guiding.value) return;
    await GoogleMapsNavigator.simulator.simulateLocationsAlongExistingRoute();
  }

  Future<void> _ensureSession() async {
    if (sessionReady.value && await GoogleMapsNavigator.isInitialized()) return;

    await _attachListeners();
    await GoogleMapsNavigator.initializeNavigationSession(
      notificationOptions: const NavigationNotificationOptions(
        defaultMessage: 'Carpital Consult delivery navigation',
        resumeAppOnTap: true,
      ),
    );
    sessionReady.value = true;
  }

  Future<void> _attachListeners() async {
    if (_listenersAttached) return;
    _listenersAttached = true;

    await GoogleMapsNavigator.setRoadSnappedLocationUpdatedListener(_onLocation);
    GoogleMapsNavigator.setOnRemainingTimeOrDistanceChangedListener(
      (e) => progress.value = NavProgress(
        remainingS: e.remainingTime,
        remainingM: e.remainingDistance,
      ),
      remainingTimeThresholdSeconds: 10,
      remainingDistanceThresholdMeters: 25,
    );
    GoogleMapsNavigator.setOnArrivalListener((_) async {
      final arrivedLeg = _leg;
      await stop();
      if (arrivedLeg != null) _arrivals.add(arrivedLeg);
    });
  }

  /// Route calculation fails until the SDK has a location, so wait for one.
  Future<void> _waitForFirstFix() async {
    if (_lastLocation != null) return;
    _firstFix ??= Completer<void>();
    await _firstFix!.future.timeout(_firstFixTimeout, onTimeout: () {});
  }

  void _onLocation(RoadSnappedLocationUpdatedEvent event) {
    final here = event.location;
    final now = DateTime.now();

    double? heading;
    double? speed;
    final prev = _lastLocation;
    final prevAt = _lastLocationAt;
    if (prev != null && prevAt != null) {
      final moved = _metersBetween(prev, here);
      if (moved >= _headingMinMoveM) {
        heading = _bearing(prev, here);
        final seconds = now.difference(prevAt).inMilliseconds / 1000;
        if (seconds > 0) speed = moved / seconds;
      } else {
        // Barely moved: keep the last direction only while guidance is active
        heading = guiding.value ? _lastHeading : null;
      }
    }

    if (heading != null) _lastHeading = heading;
    // Only significant moves become the reference point, so heading and speed
    // are measured over real travel rather than GPS jitter
    if (prev == null || _metersBetween(prev, here) >= _headingMinMoveM) {
      _lastLocation = here;
      _lastLocationAt = now;
    }

    final fix = _firstFix;
    if (fix != null && !fix.isCompleted) fix.complete();

    final p = progress.value;
    _locations.add(NavLocation(
      lat: here.latitude,
      lng: here.longitude,
      heading: heading,
      speed: speed,
      etaS: guiding.value ? p?.remainingS : null,
      remainingM: guiding.value ? p?.remainingM : null,
    ));
  }

  static String _routeStatusMessage(NavigationRouteStatus status) {
    switch (status) {
      case NavigationRouteStatus.apiKeyNotAuthorized:
        return 'Navigation isn\'t set up for this app yet. Please contact support.';
      case NavigationRouteStatus.quotaExceeded:
      case NavigationRouteStatus.quotaCheckFailed:
        return 'Navigation is unavailable right now. Please try again later.';
      case NavigationRouteStatus.networkError:
        return 'No internet connection. Check your connection and try again.';
      case NavigationRouteStatus.routeNotFound:
        return 'Couldn\'t find a driving route to this address.';
      case NavigationRouteStatus.locationUnavailable:
      case NavigationRouteStatus.locationUnknown:
        return 'Waiting for GPS. Try again in a moment.';
      default:
        return 'Navigation couldn\'t start. Please try again.';
    }
  }

  static double _metersBetween(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(a.latitude * math.pi / 180) *
            math.cos(b.latitude * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  /// Initial bearing from [a] to [b], in degrees clockwise from north.
  static double _bearing(LatLng a, LatLng b) {
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }
}
