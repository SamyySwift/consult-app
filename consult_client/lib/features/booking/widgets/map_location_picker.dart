import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';

/// Full-screen map where the user drags the map under a fixed centre pin.
/// Pops with the chosen [PlaceResult], or null if dismissed.
class MapLocationPicker extends StatefulWidget {
  final String title;
  final LatLng? initial;

  const MapLocationPicker({super.key, required this.title, this.initial});

  static Future<PlaceResult?> open(BuildContext context, {required String title, LatLng? initial}) {
    return Navigator.of(context).push<PlaceResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MapLocationPicker(title: title, initial: initial),
      ),
    );
  }

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  static const _lagos = LatLng(6.5244, 3.3792);

  final _mapController = MapController();
  Timer? _debounce;
  late LatLng _center;
  PlaceResult? _place;
  bool _resolving = false;
  bool _locating = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _center = widget.initial ?? _lagos;
    _resolveAddress();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onMapMoved(MapCamera camera, bool hasGesture) {
    _center = camera.center;
    setState(() => _resolving = true);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _resolveAddress);
  }

  Future<void> _resolveAddress() async {
    final id = ++_requestId;
    final point = _center;
    setState(() => _resolving = true);

    final place = await GeocodingService.instance.reverse(point.latitude, point.longitude);
    // A newer map move has started a newer lookup; drop this stale one
    if (!mounted || id != _requestId) return;

    setState(() {
      _resolving = false;
      // Keep the exact pin position; the geocoder snaps to the nearest named feature
      _place = PlaceResult(
        name: place?.name ?? 'Dropped pin',
        details: place?.details,
        lat: point.latitude,
        lng: point.longitude,
      );
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _showMessage('Turn on location services to use your current location');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _showMessage('Location permission is needed to use your current location');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 15));
      if (!mounted) return;

      final here = LatLng(pos.latitude, pos.longitude);
      _mapController.move(here, 17);
      _center = here;
      _resolveAddress();
    } catch (e) {
      _showMessage('Could not get your location. Please try again.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        backgroundColor: context.colors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: widget.initial != null ? 16 : 11,
              onPositionChanged: _onMapMoved,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.carpitalconsult.app',
              ),
            ],
          ),

          // Fixed centre pin; its tip marks the chosen point
          IgnorePointer(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 44),
                child: Icon(Icons.location_on, size: 48, color: context.colors.error),
              ),
            ),
          ),

          Positioned(
            right: 16,
            bottom: 200,
            child: FloatingActionButton.small(
              heroTag: 'my-location',
              onPressed: _locating ? null : _useCurrentLocation,
              backgroundColor: context.colors.surface,
              child: _locating
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.my_location_rounded, color: context.colors.accent),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Move the map to place the pin',
                    style: TextStyle(fontSize: 12, color: context.colors.textLight),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: context.colors.accent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _resolving || _place == null
                            ? Text('Finding address…', style: TextStyle(fontSize: 14, color: context.colors.textSecondary))
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _place!.name,
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.colors.textPrimary),
                                  ),
                                  if (_place!.details != null)
                                    Text(
                                      _place!.details!,
                                      style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                                    ),
                                ],
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    label: 'Confirm Location',
                    onPressed: _resolving || _place == null ? null : () => Navigator.of(context).pop(_place),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
