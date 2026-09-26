import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import '../../../core/services/geocoding_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import 'map_location_picker.dart';

/// Address input that suggests matching places as the user types and lets them
/// pick the exact spot on a map. [selected] is only set once a real location is
/// chosen; editing the text afterwards clears it.
class AddressSearchField extends StatefulWidget {
  final String label;
  final String hint;
  final String mapTitle;
  final String fieldName;
  final TextEditingController controller;
  final PlaceResult? selected;
  final ValueChanged<PlaceResult?> onSelected;

  const AddressSearchField({
    super.key,
    required this.label,
    required this.hint,
    required this.mapTitle,
    required this.fieldName,
    required this.controller,
    required this.selected,
    required this.onSelected,
  });

  @override
  State<AddressSearchField> createState() => _AddressSearchFieldState();
}

class _AddressSearchFieldState extends State<AddressSearchField> {
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<PlaceResult> _results = [];
  bool _searching = false;
  bool _searched = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) setState(() => _results = []);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    if (widget.selected != null) widget.onSelected(null);

    _debounce?.cancel();
    if (text.trim().length < 3) {
      setState(() {
        _results = [];
        _searching = false;
        _searched = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(text));
  }

  Future<void> _search(String text) async {
    final id = ++_requestId;
    final results = await GeocodingService.instance.search(text);
    // Results for an older query can arrive after a newer one
    if (!mounted || id != _requestId) return;
    setState(() {
      _results = results;
      _searching = false;
      _searched = true;
    });
  }

  void _select(PlaceResult place) {
    widget.controller.text = place.fullAddress;
    widget.onSelected(place);
    _debounce?.cancel();
    _requestId++;
    setState(() {
      _results = [];
      _searching = false;
      _searched = false;
    });
    _focusNode.unfocus();
  }

  Future<void> _pickOnMap() async {
    _focusNode.unfocus();
    final current = widget.selected;
    final place = await MapLocationPicker.open(
      context,
      title: widget.mapTitle,
      initial: current != null ? LatLng(current.lat, current.lng) : null,
    );
    if (place != null && mounted) _select(place);
  }

  @override
  Widget build(BuildContext context) {
    final showPanel = _focusNode.hasFocus && (_searching || _searched);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: widget.label,
          hint: widget.hint,
          controller: widget.controller,
          focusNode: _focusNode,
          maxLines: 2,
          onChanged: _onChanged,
          suffixIcon: widget.selected != null
              ? Icon(Icons.check_circle_rounded, color: context.colors.success, size: 20)
              : null,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return '${widget.fieldName} is required';
            if (widget.selected == null) return 'Choose a suggestion or pick the spot on the map';
            return null;
          },
        ),
        if (showPanel)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: context.colors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colors.border),
            ),
            child: _searching
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
                  )
                : _results.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          'No matching places. Try another spelling or pick it on the map.',
                          style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                        ),
                      )
                    : Column(
                        children: [
                          for (final place in _results)
                            InkWell(
                              onTap: () => _select(place),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.place_outlined, size: 18, color: context.colors.accent),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            place.name,
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.textPrimary),
                                          ),
                                          if (place.details != null)
                                            Text(
                                              place.details!,
                                              style: TextStyle(fontSize: 11, color: context.colors.textSecondary),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _pickOnMap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
            ),
            icon: Icon(Icons.map_outlined, size: 16, color: context.colors.accent),
            label: Text('Pick on map', style: TextStyle(fontSize: 12, color: context.colors.accent)),
          ),
        ),
      ],
    );
  }
}
