import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [uri] outside the app (browser, mail app), or explains why it
/// couldn't.
Future<void> openLink(BuildContext context, Uri uri) async {
  final messenger = ScaffoldMessenger.of(context);
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    opened = false;
  }
  if (!opened) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Unable to open ${uri.scheme == 'mailto' ? uri.path : uri.host}',
        ),
      ),
    );
  }
}
