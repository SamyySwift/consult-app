import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';

/// Opens [uri] outside the app (phone, mail, browser), or explains why it
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
    final target = switch (uri.scheme) {
      'tel' || 'mailto' => uri.path,
      _ => uri.host,
    };
    messenger.showSnackBar(SnackBar(content: Text('Unable to open $target')));
  }
}

/// Starts an email to dispatch support, optionally with a subject.
Future<void> emailSupport(BuildContext context, {String? subject}) => openLink(
  context,
  Uri(
    scheme: 'mailto',
    path: AppConstants.supportEmail,
    query: subject == null ? null : 'subject=${Uri.encodeComponent(subject)}',
  ),
);
