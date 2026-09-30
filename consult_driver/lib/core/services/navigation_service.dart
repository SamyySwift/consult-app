import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// The driver reached the stop they were navigating to.
class NavArrival {
  final String jobId;
  final NavLeg leg;

  const NavArrival({required this.jobId, required this.leg});
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

  // Which job's stop guidance leads to. A driver can have several active
  // jobs, so the job screen needs to know which one this is. Saved so an app
  // restart mid-delivery restores guidance onto the right job.
  static const _prefsJobId = 'nav_job_id';
  static const _prefsLeg = 'nav_leg';
  String? _jobId;
  String? get jobId => _jobId;
  NavLeg? _leg;
  NavLeg? get leg => _leg;

  final _locations = StreamController<NavLocation>.broadcast();
  /// Road-snapped positions while the session is active.
  Stream<NavLocation> get locations => _locations.stream;

  final _arrivals = StreamController<NavArrival>.broadcast();
  /// Emits the leg the driver just arrived at the end of.
  Stream<NavArrival> get arrivals => _arrivals.stream;

  bool _listenersAttached = false;
  StreamSubscription<RemainingTimeOrDistanceChangedEvent>? _progressSub;
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
      final running = await GoogleMapsNavigator.isGuidanceRunning();
      if (running) {
        final prefs = await SharedPreferences.getInstance();
        _jobId = prefs.getString(_prefsJobId);
        final leg = prefs.getString(_prefsLeg);
        _leg = NavLeg.values.where((l) => l.name == leg).firstOrNull;
      }
      guiding.value = running;
    } catch (e) {
      debugPrint('Navigation restore failed: $e');
    }
  }

  /// Shows Google's terms if needed, then starts guidance to the destination.
  Future<NavStartResult> start({
    required String jobId,
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
      final located = await _waitForFirstFix();

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
        final noLocation = status == NavigationRouteStatus.locationUnavailable ||
            status == NavigationRouteStatus.locationUnknown;
        // The SDK never reported a single position: on iOS this is also what a
        // key Google rejects looks like, since the plugin can't report it there
        if (noLocation && !located) {
          return const NavStartResult.failed(
            'Navigation can\'t get your location. If this keeps happening, '
            'navigation may not be set up for this app yet; use Google Maps for now.',
          );
        }
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
      _jobId = jobId;
      _leg = leg;
      unawaited(_saveTarget());
      guiding.value = true;
      // The listener only reports changes, so show the starting figures now
      try {
        final now = await GoogleMapsNavigator.getCurrentTimeAndDistance();
        progress.value = NavProgress(remainingS: now.time, remainingM: now.distance);
      } catch (e) {
        debugPrint('Initial time/distance unavailable: $e');
      }
      return const NavStartResult.ok();
    } on SessionInitializationException catch (e) {
      // Android reports these up front; iOS only logs a rejected key
      debugPrint('Navigation session failed: ${e.code}');
      switch (e.code) {
        case SessionInitializationError.notAuthorized:
          return const NavStartResult.failed(
            'Navigation isn\'t set up for this app yet. Please contact support.',
          );
        case SessionInitializationError.locationPermissionMissing:
          return const NavStartResult.failed(
            'Allow location access for this app to use navigation.',
          );
        case SessionInitializationError.termsNotAccepted:
          return const NavStartResult.failed(
            'In-app navigation needs Google\'s terms to be accepted.',
          );
      }
    } catch (e) {
      debugPrint('Navigation start failed: $e');
      return const NavStartResult.failed('Navigation couldn\'t start. Please try again.');
    }
  }

  /// Stops guidance and clears the route. The session stays for next time.
  Future<void> stop() async {
    _jobId = null;
    _leg = null;
    progress.value = null;
    unawaited(_saveTarget());
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

  /// Sets which job guidance leads to, as [start] would, for unit tests.
  @visibleForTesting
  void debugSetTarget(String jobId, NavLeg leg) {
    _jobId = jobId;
    _leg = leg;
  }

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
    // Must come after the session exists: the plugin applies the thresholds to
    // the session's navigator, and creating a session resets them to "never"
    await _progressSub?.cancel();
    _progressSub = GoogleMapsNavigator.setOnRemainingTimeOrDistanceChangedListener(
      (e) => progress.value = NavProgress(
        remainingS: e.remainingTime,
        remainingM: e.remainingDistance,
      ),
      remainingTimeThresholdSeconds: 10,
      remainingDistanceThresholdMeters: 25,
    );
    sessionReady.value = true;
  }

  Future<void> _attachListeners() async {
    if (_listenersAttached) return;
    _listenersAttached = true;

    await GoogleMapsNavigator.setRoadSnappedLocationUpdatedListener(_onLocation);
    GoogleMapsNavigator.setOnArrivalListener((_) async {
      final arrivedJob = _jobId;
      final arrivedLeg = _leg;
      await stop();
      if (arrivedJob != null && arrivedLeg != null) {
        _arrivals.add(NavArrival(jobId: arrivedJob, leg: arrivedLeg));
      }
    });
  }

  Future<void> _saveTarget() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jobId = _jobId;
      final leg = _leg;
      if (jobId == null || leg == null) {
        await prefs.remove(_prefsJobId);
        await prefs.remove(_prefsLeg);
      } else {
        await prefs.setString(_prefsJobId, jobId);
        await prefs.setString(_prefsLeg, leg.name);
      }
    } catch (e) {
      debugPrint('Saving navigation target failed: $e');
    }
  }

  /// Route calculation fails until the SDK has a location, so wait for one.
  /// Returns false if none arrived in time.
  Future<bool> _waitForFirstFix() async {
    if (_lastLocation != null) return true;
    _firstFix ??= Completer<void>();
    await _firstFix!.future.timeout(_firstFixTimeout, onTimeout: () {});
    return _lastLocation != null;
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
