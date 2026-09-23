import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import '../models/job_model.dart';

class JobProvider extends ChangeNotifier {
  List<JobModel> _allJobs = generateMockJobs();
  bool _isLoading = false;
  RealtimeChannel? _realtimeChannel;
  StreamSubscription<Position>? _positionStream;

  List<JobModel> get allJobs => List.unmodifiable(_allJobs);
  bool get isLoading => _isLoading;

  SupabaseClient get _supabase => Supabase.instance.client;

  JobProvider() {
    fetchJobs();
    _subscribeToLiveJobs();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _stopLocationTracking();
    super.dispose();
  }

  /// Subscribe to real-time changes on the bookings table
  void _subscribeToLiveJobs() {
    try {
      _realtimeChannel = _supabase
          .channel('public:bookings:driver_channel')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'bookings',
            callback: (payload) {
              debugPrint('Realtime driver bookings event received: ${payload.eventType}');
              fetchJobs();
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Error subscribing to driver bookings realtime: $e');
    }
  }

  /// Fetch jobs from Supabase
  Future<void> fetchJobs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      var query = _supabase
          .from('bookings')
          .select('*, profiles:user_id(full_name, phone)');

      // If driver is authenticated, show only their assigned jobs
      if (currentUserId != null) {
        query = query.eq('driver_id', currentUserId);
      }

      final response = await query.order('created_at', ascending: false);
      final List<dynamic> data = response as List<dynamic>;
      
      final List<JobModel> remoteJobs = data
          .map((item) => JobModel.fromSupabaseMap(item as Map<String, dynamic>))
          .toList();
      _allJobs = remoteJobs;
      
      // Check if we need to resume location tracking
      if (hasActiveDelivery && activeJob?.status == JobStatus.inTransit) {
        _startLocationTracking(activeJob!.id);
      } else {
        _stopLocationTracking();
      }
    } catch (e) {
      debugPrint('Error fetching jobs from Supabase: $e');
      if (_allJobs.isEmpty) {
        _allJobs = generateMockJobs();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Jobs newly assigned by admin that the driver hasn't confirmed yet.
  List<JobModel> get assignedJobs =>
      _allJobs.where((j) => j.status == JobStatus.assigned).toList();

  /// Jobs the driver has confirmed and is actively working on.
  List<JobModel> get activeJobs => _allJobs.where((j) => j.isActive).toList();

  /// The single current active job (there should only be one at a time).
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
      await _supabase.from('bookings').update({
        'status': 'confirmed',
        'confirmed_at': DateTime.now().toIso8601String(),
      }).eq('id', jobId);
    } catch (e) {
      debugPrint('Supabase confirmJob error: $e');
    }

    final idx = _allJobs.indexWhere((j) => j.id == jobId);
    if (idx != -1) {
      _allJobs[idx] = _allJobs[idx].copyWith(
        status: JobStatus.confirmed,
        confirmedAt: DateTime.now(),
      );
    }

    _isLoading = false;
    notifyListeners();
    return true;
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

      // Convert images to base64 data URIs (stored directly in DB)
      for (int i = 0; i < imageFiles.length; i++) {
        try {
          final file = imageFiles[i];
          final bytes = await file.readAsBytes();
          final base64Str = base64Encode(bytes);
          final ext = file.path.split('.').last.toLowerCase();
          final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
          imageDataUris.add('data:$mime;base64,$base64Str');
        } catch (e) {
          debugPrint('Image encode $i failed (continuing): $e');
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
          debugPrint('Audio encode failed (continuing): $e');
        }
      }

      // Update the DB — this is the critical part
      await _supabase.from('bookings').update({
        'status': 'pickedUp',
        'picked_up_at': DateTime.now().toIso8601String(),
        'pickup_condition_desc': description,
        if (imageDataUris.isNotEmpty) 'pickup_condition_images': imageDataUris,
        if (audioDataUri != null) 'pickup_condition_audio': audioDataUri,
      }).eq('id', jobId);

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
    } catch (e) {
      debugPrint('Supabase submitPickupCondition error: $e');
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
        updates['confirmed_at'] = DateTime.now().toIso8601String();
        break;
      case JobStatus.pickedUp:
        statusStr = 'pickedUp';
        updates['picked_up_at'] = DateTime.now().toIso8601String();
        break;
      case JobStatus.inTransit:
        statusStr = 'inTransit';
        _startLocationTracking(jobId);
        break;
      case JobStatus.completed:
        statusStr = 'delivered';
        updates['completed_at'] = DateTime.now().toIso8601String();
        if (clientSignatureBase64 != null) {
          updates['client_signature_url'] = clientSignatureBase64;
        }
        _stopLocationTracking();
        break;
      case JobStatus.cancelled:
        statusStr = 'cancelled';
        _stopLocationTracking();
        break;
    }

    updates['status'] = statusStr;

    try {
      await _supabase.from('bookings').update(updates).eq('id', jobId);
    } catch (e) {
      debugPrint('Supabase updateJobStatus error: $e');
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

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _startLocationTracking(String jobId) async {
    if (_positionStream != null) return; // Already tracking

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50, // update every 50 meters
      timeLimit: Duration(seconds: 10), // update every 10 seconds
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position? position) {
        if (position != null) {
          _updateDriverLocationInSupabase(jobId, position.latitude, position.longitude);
        }
      },
    );
  }

  Future<void> _updateDriverLocationInSupabase(String jobId, double lat, double lng) async {
    try {
      await _supabase.from('bookings').update({
        'driver_lat': lat,
        'driver_lng': lng,
      }).eq('id', jobId);
      debugPrint('Updated driver location: $lat, $lng');
    } catch (e) {
      debugPrint('Supabase _updateDriverLocationInSupabase error: $e');
    }
  }

  void _stopLocationTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }
}
