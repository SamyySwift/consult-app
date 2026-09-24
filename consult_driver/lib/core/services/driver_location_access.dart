import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/driver_colors.dart';

enum LocationAccess { granted, serviceDisabled, denied, deniedForever }

/// Clients track deliveries through the driver's location, so the driver app
/// requires it before going online or working a job.
class DriverLocationAccess {
  DriverLocationAccess._();

  /// Current state; with [request] it shows the OS permission prompt if the
  /// driver hasn't answered it yet.
  static Future<LocationAccess> check({bool request = false}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAccess.serviceDisabled;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && request) {
      permission = await Geolocator.requestPermission();
    }

    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationAccess.granted;
      case LocationPermission.deniedForever:
        return LocationAccess.deniedForever;
      default:
        return LocationAccess.denied;
    }
  }

  /// Asks for location if needed. When it's still unavailable, explains why
  /// it's required and offers the fix. Returns true once location is usable.
  static Future<bool> ensure(BuildContext context, {required String reason}) async {
    final access = await check(request: true);
    if (access == LocationAccess.granted) return true;
    if (!context.mounted) return false;

    final granted = await showDialog<bool>(
      context: context,
      builder: (ctx) => _LocationRequiredDialog(access: access, reason: reason),
    );
    return granted ?? false;
  }
}

class _LocationRequiredDialog extends StatelessWidget {
  final LocationAccess access;
  final String reason;

  const _LocationRequiredDialog({required this.access, required this.reason});

  @override
  Widget build(BuildContext context) {
    final String title;
    final String instruction;
    final String action;
    switch (access) {
      case LocationAccess.serviceDisabled:
        title = 'Turn on location';
        instruction = 'Location services are off on this phone.';
        action = 'Open Settings';
        break;
      case LocationAccess.deniedForever:
        title = 'Allow location access';
        instruction = 'Location is blocked for this app. Allow it in Settings, then come back.';
        action = 'Open Settings';
        break;
      default:
        title = 'Allow location access';
        instruction = 'Location permission was not granted.';
        action = 'Allow';
    }

    return AlertDialog(
      backgroundColor: DriverColors.surface,
      icon: const Icon(Icons.location_off_rounded, color: DriverColors.error, size: 32),
      title: Text(title, style: const TextStyle(color: DriverColors.textPrimary, fontSize: 18)),
      content: Text(
        '$reason\n\n$instruction',
        style: const TextStyle(color: DriverColors.textSecondary, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Not now', style: TextStyle(color: DriverColors.textSecondary)),
        ),
        TextButton(
          onPressed: () async {
            if (access == LocationAccess.serviceDisabled) {
              await Geolocator.openLocationSettings();
            } else if (access == LocationAccess.deniedForever) {
              await Geolocator.openAppSettings();
            } else {
              final retry = await DriverLocationAccess.check(request: true);
              if (context.mounted) Navigator.of(context).pop(retry == LocationAccess.granted);
              return;
            }
            // Settings open outside the app; the driver retries after returning
            if (context.mounted) Navigator.of(context).pop(false);
          },
          child: Text(action, style: const TextStyle(color: DriverColors.accent, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
