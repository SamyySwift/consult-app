import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import '../models/job_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/driver_location_access.dart';
import '../../../core/services/navigation_service.dart';

class JobProvider extends ChangeNotifier with WidgetsBindingObserver {
  List<JobModel> _allJobs = [];
  bool _isLoading = false;
  bool _hasLoadedFromApi = false;
  Timer? _pollingTimer;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<ServiceStatus>? _serviceStatusSub;
  bool _startingTracking = false;
  LocationAccess? _locationAccess;

  // While turn-by-turn guidance runs, positions come from the Navigation SDK
  // (road-snapped, with ETA) instead of the GPS stream above.
  StreamSubscription<NavLocation>? _navLocationSub;
  bool _navRestoreAttempted = false;
  DateTime? _lastNavPostAt;
  NavLocation? _lastNavPosted;
  // Send a navigation position after this much movement, or this long apart so
  // the client's ETA keeps updating while stuck in traffic
  static const _navPostMinMoveM = 2.0;
  static const _navPostMaxGap = Duration(seconds: 15);

  /// The driver's latest position while tracking an active job. A separate
  /// notifier so the map can follow it without rebuilding every listener of
  /// this provider on each GPS fix.
  final ValueNotifier<Position?> driverPosition = ValueNotifier(null);

  List<JobModel> get allJobs => List.unmodifiable(_allJobs);
  bool get isLoading => _isLoading;

  /// True when the driver has a job but the client can't see their location.
  bool get locationBlocked =>
      hasActiveDelivery && _locationAccess != null && _locationAccess != LocationAccess.granted;

  JobProvider() {
    fetchJobs();
    _startPolling();
    WidgetsBinding.instance.addObserver(this);
    try {
      // Restart tracking when the driver turns location services back on
      _serviceStatusSub = Geolocator.getServiceStatusStream().listen((_) => recheckLocation());
    } catch (e) {
      debugPrint('Location service status unavailable: $e');
    }
    _navLocationSub = NavigationService.instance.locations.listen(_onNavLocation);
    NavigationService.instance.guiding.addListener(_onGuidingChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NavigationService.instance.guiding.removeListener(_onGuidingChanged);
    _navLocationSub?.cancel();
    _serviceStatusSub?.cancel();
    _pollingTimer?.cancel();
    _stopLocationTracking();
    driverPosition.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The driver may have changed location permission in Settings
    if (state == AppLifecycleState.resumed) recheckLocation();
  }

  /// Re-reads location access and restarts tracking for the active job.
  Future<void> recheckLocation() async {
    _stopLocationTracking();
    if (hasActiveDelivery) {
      await _startLocationTracking();
    } else {
      _locationAccess = await DriverLocationAccess.check();
      notifyListeners();
    }
  }

  /// Start background polling every 5 seconds to sync live jobs
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      fetchJobs(silent: true);
    });
  }

  /// Fetch jobs from Railway API
  Future<void> fetchJobs({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final res = await ApiClient.instance.get('/api/driver/jobs');
      if (res.isSuccess && res.data != null) {
        final List<dynamic> data = res.data as List<dynamic>;
        final List<JobModel> remoteJobs = data
            .map((item) => JobModel.fromSupabaseMap(item as Map<String, dynamic>))
            .toList();
        _allJobs = remoteJobs;
        _hasLoadedFromApi = true;

        // Share location for the whole job, including the drive to pickup
        if (hasActiveDelivery) {
          _startLocationTracking();
          if (!_navRestoreAttempted) {
            // Picks up guidance still running from before an app restart
            _navRestoreAttempted = true;
            NavigationService.instance.restoreIfPossible();
          }
        } else {
          _stopLocationTracking();
          // e.g. the job was cancelled while the driver was navigating
          if (NavigationService.instance.guiding.value) NavigationService.instance.stop();
        }
      }
    } catch (e) {
      debugPrint('Error fetching jobs from Railway API: $e');
      // Only use mock data if we've never successfully loaded from API
      if (!_hasLoadedFromApi && _allJobs.isEmpty) {
        _allJobs = generateMockJobs();
      }
    } finally {
      if (!silent) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  /// Jobs newly assigned by admin that the driver hasn't confirmed yet.
  List<JobModel> get assignedJobs =>
      _allJobs.where((j) => j.status == JobStatus.assigned).toList();

  /// Jobs the driver has confirmed and is actively working on.
  /// Jobs the driver is working on, most urgent first: handovers (in transit),
  /// then vehicles already picked up, then pickups, each by pickup time.
  List<JobModel> get activeJobs {
    int urgency(JobStatus s) => switch (s) {
      JobStatus.inTransit => 0,
      JobStatus.pickedUp => 1,
      _ => 2,
    };
    final jobs = _allJobs.where((j) => j.isActive).toList();
    jobs.sort((a, b) {
      final byStatus = urgency(a.status).compareTo(urgency(b.status));
      if (byStatus != 0) return byStatus;
      final aAt = a.pickup.scheduledAt;
      final bAt = b.pickup.scheduledAt;
      if (aAt == null || bAt == null) return 0;
      return aAt.compareTo(bAt);
    });
    return jobs;
  }

  JobModel? jobById(String id) => _allJobs.where((j) => j.id == id).firstOrNull;

  /// The single current active job (there should only be one at a time).
  /// The most urgent active job.
  JobModel? get activeJob => activeJobs.isNotEmpty ? activeJobs.first : null;

  /// True when the driver currently has an active delivery.
  bool get hasActiveDelivery => activeJob != null;

  /// True when the driver has any pending assignment to confirm.
  bool get hasPendingAssignment => assignedJobs.isNotEmpty;

  List<JobModel> get completedJobs =>
      _allJobs.where((j) => j.status == JobStatus.completed).toList();

  List<JobModel> get cancelledJobs =>
      _allJobs.where((j) => j.status == JobStatus.cancelled).toList();

  int get totalAssigned => _allJobs
      .where((j) => j.status != JobStatus.cancelled)
      .length;

  int get totalCompleted => completedJobs.length;

  /// Driver confirms an admin-assigned job.
  Future<bool> confirmJob(String jobId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiClient.instance.post('/api/driver/jobs/$jobId/accept', {});
    } catch (e) {
      debugPrint('API confirmJob error: $e');
    }

    final idx = _allJobs.indexWhere((j) => j.id == jobId);
    if (idx != -1) {
      _allJobs[idx] = _allJobs[idx].copyWith(
        status: JobStatus.confirmed,
        confirmedAt: DateTime.now(),
      );
    }
    _startLocationTracking();

    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Guidance took over or handed back location updates.
  void _onGuidingChanged() {
    if (NavigationService.instance.guiding.value) {
      _stopLocationTracking();
      _lastNavPosted = null;
      _lastNavPostAt = null;
    } else if (hasActiveDelivery) {
      _startLocationTracking();
    }
  }

  void _onNavLocation(NavLocation loc) {
    // The SDK reports positions whenever the session is open; only guidance
    // replaces the GPS stream, so ignore the rest to avoid double updates.
    if (!hasActiveDelivery || !NavigationService.instance.guiding.value) return;

    final last = _lastNavPosted;
    final lastAt = _lastNavPostAt;
    final moved = last == null
        ? double.infinity
        : Geolocator.distanceBetween(last.lat, last.lng, loc.lat, loc.lng);
    final stale = lastAt == null || DateTime.now().difference(lastAt) >= _navPostMaxGap;
    if (moved < _navPostMinMoveM && !stale) return;

    _lastNavPosted = loc;
    _lastNavPostAt = DateTime.now();
    _postLocation(
      lat: loc.lat,
      lng: loc.lng,
      heading: loc.heading,
      speed: loc.speed,
      navJobId: NavigationService.instance.jobId,
      etaS: loc.etaS,
      remainingM: loc.remainingM,
    );
  }

  /// Submit pickup condition form with optional images and audio, then mark as pickedUp.
  Future<void> submitPickupCondition({
    required String jobId,
    required String description,
    required List<File> imageFiles,
    File? audioFile,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      List<String> imageDataUris = [];
      String? audioDataUri;

      // Convert images to base64 data URIs
      for (int i = 0; i < imageFiles.length; i++) {
        try {
          final file = imageFiles[i];
          final bytes = await file.readAsBytes();
          final base64Str = base64Encode(bytes);
          final ext = file.path.split('.').last.toLowerCase();
          final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
          imageDataUris.add('data:$mime;base64,$base64Str');
        } catch (e) {
          debugPrint('Image encode $i failed: $e');
        }
      }

      // Convert audio to base64 data URI
      if (audioFile != null) {
        try {
          final bytes = await audioFile.readAsBytes();
          final base64Str = base64Encode(bytes);
          final ext = audioFile.path.split('.').last.toLowerCase();
          final mime = ext == 'm4a' ? 'audio/mp4' : 'audio/$ext';
          audioDataUri = 'data:$mime;base64,$base64Str';
        } catch (e) {
          debugPrint('Audio encode failed: $e');
        }
      }

      // Update via Railway API
      await ApiClient.instance.post('/api/driver/jobs/$jobId/status', {
        'status': 'pickedUp',
        'pickupConditionDesc': description,
        if (imageDataUris.isNotEmpty) 'pickupConditionImages': imageDataUris,
        'pickupConditionAudio': ?audioDataUri,
      });

      // Update local state
      final idx = _allJobs.indexWhere((j) => j.id == jobId);
      if (idx != -1) {
        _allJobs[idx] = _allJobs[idx].copyWith(
          status: JobStatus.pickedUp,
          pickedUpAt: DateTime.now(),
          pickupConditionDesc: description,
          pickupConditionImages: imageDataUris.isEmpty ? null : imageDataUris,
          pickupConditionAudio: audioDataUri,
        );
      }
      // The pickup is done, so guidance to it is no longer needed
      final nav = NavigationService.instance;
      if (nav.jobId == jobId && nav.leg == NavLeg.toPickup) await nav.stop();
    } catch (e) {
      debugPrint('API submitPickupCondition error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Advance job through status pipeline: confirmed → pickedUp → inTransit → completed (delivered).
  Future<void> updateJobStatus(String jobId, JobStatus newStatus, {String? clientSignatureBase64}) async {
    _isLoading = true;
    notifyListeners();

    String statusStr = 'confirmed';
    final updates = <String, dynamic>{};

    switch (newStatus) {
      case JobStatus.assigned:
        statusStr = 'assigned';
        break;
      case JobStatus.confirmed:
        statusStr = 'confirmed';
        break;
      case JobStatus.pickedUp:
        statusStr = 'pickedUp';
        break;
      case JobStatus.inTransit:
        statusStr = 'inTransit';
        break;
      case JobStatus.completed:
        statusStr = 'delivered';
        if (clientSignatureBase64 != null) {
          updates['clientSignatureBase64'] = clientSignatureBase64;
        }
        break;
      case JobStatus.cancelled:
        statusStr = 'cancelled';
        break;
    }

    updates['status'] = statusStr;

    try {
      await ApiClient.instance.post('/api/driver/jobs/$jobId/status', updates);
    } catch (e) {
      debugPrint('API updateJobStatus error: $e');
    }

    final idx = _allJobs.indexWhere((j) => j.id == jobId);
    if (idx != -1) {
      _allJobs[idx] = _allJobs[idx].copyWith(
        status: newStatus,
        pickedUpAt: newStatus == JobStatus.pickedUp ? DateTime.now() : _allJobs[idx].pickedUpAt,
        completedAt: newStatus == JobStatus.completed ? DateTime.now() : _allJobs[idx].completedAt,
        clientSignatureBase64: clientSignatureBase64 ?? _allJobs[idx].clientSignatureBase64,
        clientAcknowledgedAt: clientSignatureBase64 != null ? DateTime.now() : _allJobs[idx].clientAcknowledgedAt,
      );
    }

    final ended = newStatus == JobStatus.completed || newStatus == JobStatus.cancelled;
    if (ended && NavigationService.instance.jobId == jobId) {
      // Guidance led to this job's stop; other jobs keep their own
      NavigationService.instance.stop();
    }
    // The driver may still be carrying other vehicles
    if (hasActiveDelivery) {
      _startLocationTracking();
    } else {
      _stopLocationTracking();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Keeps GPS alive once the driver leaves the app: a foreground service on
  /// Android, background location updates on iOS.
  ///
  /// No timeLimit on any platform — it makes the stream throw a TimeoutException
  /// whenever a fix takes longer than the window (tunnels, underground car
  /// parks), which would kill location updates for the rest of the job.
  /// Minimum movement in metres before a new position is sent to the client.
  static const _locationDistanceFilterMeters = 2;

  LocationSettings _buildLocationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: _locationDistanceFilterMeters,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Delivery in progress',
          notificationText: 'Sharing your location with the client.',
          enableWakeLock: true,
        ),
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: _locationDistanceFilterMeters,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
        pauseLocationUpdatesAutomatically: false,
        activityType: ActivityType.automotiveNavigation,
      );
    }

    return LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: _locationDistanceFilterMeters,
    );
  }

  Future<void> _startLocationTracking() async {
    // fetchJobs runs every few seconds; don't open a second stream mid-start
    if (_positionStream != null || _startingTracking) return;
    // Guidance is already sending road-snapped positions
    if (NavigationService.instance.guiding.value) return;
    _startingTracking = true;

    try {
      final access = await DriverLocationAccess.check();
      if (access != _locationAccess) {
        _locationAccess = access;
        notifyListeners();
      }
      if (access != LocationAccess.granted) {
        debugPrint('Location unavailable ($access); client cannot track this job.');
        return;
      }

      _positionStream = Geolocator.getPositionStream(
        locationSettings: _buildLocationSettings(),
      ).listen(
        (Position? position) {
          if (position != null) {
            driverPosition.value = position;
            _postLocation(
              lat: position.latitude,
              lng: position.longitude,
              // Heading is only meaningful while moving; phones report 0 or -1 when still
              heading: position.speed > 0.5 && position.heading >= 0 ? position.heading : null,
              speed: position.speed,
            );
          }
        },
        onError: (Object e) => debugPrint('Location stream error: $e'),
        cancelOnError: false,
      );
    } finally {
      _startingTracking = false;
    }
  }

  /// Sends the driver's position for every active job: each of those clients
  /// is tracking the same truck.
  Future<void> _postLocation({
    required double lat,
    required double lng,
    double? heading,
    double? speed,
    String? navJobId,
    double? etaS,
    double? remainingM,
  }) async {
    final jobIds = activeJobs.map((j) => j.id).toList();
    if (jobIds.isEmpty) return;
    try {
      await ApiClient.instance.post('/api/driver/location', {
        'jobIds': jobIds,
        // The ETA below belongs to this job only
        'navJobId': ?navJobId,
        'lat': lat,
        'lng': lng,
        'heading': ?heading,
        'speed': ?speed,
        // From turn-by-turn navigation, so the client sees the real ETA
        'eta_s': ?etaS,
        'remaining_m': ?remainingM,
      });
    } catch (e) {
      debugPrint('API _postLocation error: $e');
    }
  }

  void _stopLocationTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }
}
