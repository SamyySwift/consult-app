import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/booking_provider.dart';
import '../widgets/address_search_field.dart';
import '../../../../core/services/geocoding_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/map_utils.dart';
import '../../../../core/widgets/custom_button.dart';

class Step2Locations extends StatefulWidget {
  final VoidCallback onNext;
  const Step2Locations({super.key, required this.onNext});

  @override
  State<Step2Locations> createState() => _Step2LocationsState();
}

class _Step2LocationsState extends State<Step2Locations> {
  final _formKey = GlobalKey<FormState>();
  final _pickupCtrl = TextEditingController();
  final _dropoffCtrl = TextEditingController();
  DateTime? _pickupDate;
  TimeOfDay? _pickupTime;
  PlaceResult? _pickup;
  PlaceResult? _dropoff;

  @override
  void initState() {
    super.initState();
    final draft = context.read<BookingProvider>().draft;
    _pickupCtrl.text = draft.pickupAddress ?? '';
    _dropoffCtrl.text = draft.dropoffAddress ?? '';
    if (draft.pickupAddress != null && draft.pickupLat != null && draft.pickupLng != null) {
      _pickup = PlaceResult(name: draft.pickupAddress!, lat: draft.pickupLat!, lng: draft.pickupLng!);
    }
    if (draft.dropoffAddress != null && draft.dropoffLat != null && draft.dropoffLng != null) {
      _dropoff = PlaceResult(name: draft.dropoffAddress!, lat: draft.dropoffLat!, lng: draft.dropoffLng!);
    }
    if (draft.pickupDateTime != null) {
      _pickupDate = draft.pickupDateTime;
      _pickupTime = TimeOfDay.fromDateTime(draft.pickupDateTime!);
    }
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _dropoffCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: context.colors.accent,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _pickupDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: context.colors.accent,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (time != null) setState(() => _pickupTime = time);
  }

  String get _dateDisplay {
    if (_pickupDate == null) return 'Select pickup date';
    return DateFormat('EEE, MMM d, yyyy').format(_pickupDate!);
  }

  String get _timeDisplay {
    if (_pickupTime == null) return 'Select pickup time';
    final h = _pickupTime!.hourOfPeriod;
    final m = _pickupTime!.minute.toString().padLeft(2, '0');
    final period = _pickupTime!.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || _pickup == null || _dropoff == null) return;
    if (_pickupDate == null || _pickupTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a pickup date and time')),
      );
      return;
    }

    final pickupDateTime = DateTime(
      _pickupDate!.year,
      _pickupDate!.month,
      _pickupDate!.day,
      _pickupTime!.hour,
      _pickupTime!.minute,
    );

    context.read<BookingProvider>()
      ..updatePickup(
        address: _pickupCtrl.text.trim(),
        lat: _pickup!.lat,
        lng: _pickup!.lng,
        dateTime: pickupDateTime,
      )
      ..updateDropoff(
        address: _dropoffCtrl.text.trim(),
        lat: _dropoff!.lat,
        lng: _dropoff!.lng,
      );

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              icon: Icons.location_on_rounded,
              title: 'Pickup & Delivery',
              subtitle: 'Set your vehicle pickup and drop-off locations',
            ),

            SizedBox(height: 28),

            AddressSearchField(
              label: 'Pickup Address *',
              hint: 'Start typing, e.g. Admiralty Way, Lekki',
              mapTitle: 'Pickup Location',
              fieldName: 'Pickup address',
              controller: _pickupCtrl,
              selected: _pickup,
              onSelected: (p) => setState(() => _pickup = p),
            ),

            SizedBox(height: 8),

            AddressSearchField(
              label: 'Delivery Address *',
              hint: 'Start typing the delivery address',
              mapTitle: 'Delivery Location',
              fieldName: 'Delivery address',
              controller: _dropoffCtrl,
              selected: _dropoff,
              onSelected: (p) => setState(() => _dropoff = p),
            ),

            if (_pickup != null || _dropoff != null) ...[
              SizedBox(height: 12),
              _RoutePreviewMap(pickup: _pickup, dropoff: _dropoff),
            ],

            SizedBox(height: 24),

            Text(
              'Preferred Pickup Date & Time *',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.textPrimary),
            ),

            SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: _DateTimeChip(
                      icon: Icons.calendar_today_rounded,
                      label: _dateDisplay,
                      isSelected: _pickupDate != null,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: _pickTime,
                    child: _DateTimeChip(
                      icon: Icons.access_time_rounded,
                      label: _timeDisplay,
                      isSelected: _pickupTime != null,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.infoLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: context.colors.info, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Our driver will contact you 30 minutes before pickup',
                      style: TextStyle(fontSize: 12, color: context.colors.info),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32),

            CustomButton(label: 'Continue', onPressed: _submit),

            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Static preview of the chosen points so the client can see they're right.
class _RoutePreviewMap extends StatefulWidget {
  final PlaceResult? pickup;
  final PlaceResult? dropoff;

  const _RoutePreviewMap({this.pickup, this.dropoff});

  @override
  State<_RoutePreviewMap> createState() => _RoutePreviewMapState();
}

class _RoutePreviewMapState extends State<_RoutePreviewMap> {
  GoogleMapController? _controller;
  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _dropoffIcon;

  LatLng? get _pickup => widget.pickup == null ? null : LatLng(widget.pickup!.lat, widget.pickup!.lng);
  LatLng? get _dropoff => widget.dropoff == null ? null : LatLng(widget.dropoff!.lat, widget.dropoff!.lng);
  List<LatLng> get _points => [?_pickup, ?_dropoff];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadIcons();
  }

  @override
  void didUpdateWidget(covariant _RoutePreviewMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controller = _controller;
    if (controller != null) fitPoints(controller, _points, edge: 36);
  }

  Future<void> _loadIcons() async {
    Future<BitmapDescriptor> pin(Color color, IconData icon) => MarkerIcons.circle(
          size: 28,
          pixelRatio: MediaQuery.devicePixelRatioOf(context),
          color: color,
          borderColor: Colors.white,
          borderWidth: 2,
          icon: icon,
          iconSize: 14,
        );
    final icons = await Future.wait([
      pin(context.colors.success, Icons.radio_button_checked),
      pin(context.colors.error, Icons.location_on),
    ]);
    if (!mounted) return;
    setState(() {
      _pickupIcon = icons[0];
      _dropoffIcon = icons[1];
    });
  }

  @override
  Widget build(BuildContext context) {
    final points = _points;
    final pickup = _pickup;
    final dropoff = _dropoff;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 180,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: points.first, zoom: 15),
          onMapCreated: (controller) {
            _controller = controller;
            fitPoints(controller, points, edge: 36, animate: false);
          },
          // Android draws a static snapshot, which is cheaper inside a scrolling form
          liteModeEnabled: true,
          scrollGesturesEnabled: false,
          zoomGesturesEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
          polylines: {
            if (points.length > 1)
              Polyline(
                polylineId: const PolylineId('route'),
                points: points,
                color: context.colors.accent,
                width: 3,
              ),
          },
          markers: {
            if (pickup != null && _pickupIcon != null)
              Marker(
                markerId: const MarkerId('pickup'),
                position: pickup,
                icon: _pickupIcon!,
                anchor: const Offset(0.5, 0.5),
              ),
            if (dropoff != null && _dropoffIcon != null)
              Marker(
                markerId: const MarkerId('dropoff'),
                position: dropoff,
                icon: _dropoffIcon!,
                anchor: const Offset(0.5, 0.5),
              ),
          },
        ),
      ),
    );
  }
}

class _DateTimeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;

  const _DateTimeChip({required this.icon, required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isSelected ? context.colors.accent.withValues(alpha: 0.08) : context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? context.colors.accent : context.colors.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isSelected ? context.colors.accent : context.colors.textLight),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? context.colors.accent : context.colors.textLight,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: context.colors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: context.colors.accent, size: 24),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
              Text(subtitle, style: TextStyle(fontSize: 13, color: context.colors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
