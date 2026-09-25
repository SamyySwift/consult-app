import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../booking/providers/booking_provider.dart';
import '../models/vehicle_model.dart';
import '../models/vehicle_document_model.dart';
import '../widgets/order_request_document_view.dart';
import '../widgets/proof_of_handover_document_view.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/status_badge.dart';

class VehicleGarageScreen extends StatelessWidget {
  const VehicleGarageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const Positioned.fill(child: AuroraBackground()),
          Column(
            children: [
              const GlassPageHeader(
                title: 'Vehicle Garage & Documents',
                showBack: true,
              ),
              Expanded(
                child: Consumer<BookingProvider>(
                  builder: (context, prov, _) {
                    final records = VehicleRecord.extractFromBookings(
                      prov.bookings,
                    );

                    if (records.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: GlassEmptyState(
                            icon: Icons.directions_car_filled_rounded,
                            title: 'Garage is Empty',
                            subtitle:
                                'Your registered vehicles and transport\ndocuments will appear here.',
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        20,
                        16,
                        MediaQuery.paddingOf(context).bottom + 16,
                      ),
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        return _VehicleRecordCard(
                          record: records[index],
                          index: index,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VehicleRecordCard extends StatelessWidget {
  final VehicleRecord record;
  final int index;

  const _VehicleRecordCard({required this.record, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        radius: 28,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                GlassContainer(
                  width: 50,
                  height: 50,
                  radius: 17,
                  tint: context.colors.accent,
                  child: Icon(
                    record.iconData,
                    color: context.colors.accentLight,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'VIN: ${record.vin.isNotEmpty ? record.vin : 'Not Specified'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.45),
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          if (record.isCurrentlyInTransit) ...[
                            const SizedBox(width: 8),
                            GlassPill(
                              tint: context.colors.accent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              child: Text(
                                'IN TRANSIT',
                                style: TextStyle(
                                  color: context.colors.accentLight,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                _InfoChip(label: 'Type', value: record.typeLabel),
                const SizedBox(width: 8),
                _InfoChip(label: 'Color', value: record.color),
                const SizedBox(width: 8),
                _InfoChip(
                  label: 'Transports',
                  value: '${record.totalTransports}',
                ),
              ],
            ),

            const SizedBox(height: 22),
            Text(
              'TRANSPORT HISTORY & DOCUMENTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 12),

            // History list
            ...record.bookingHistory.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('MMM dd, yyyy').format(b.createdAt),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          StatusBadge(status: b.status, compact: true),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _DocButton(
                              icon: Icons.description_outlined,
                              label: 'Order Waybill',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OrderRequestDocumentView(
                                      document:
                                          OrderRequestDocument.fromBooking(b),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _DocButton(
                              icon: Icons.verified_outlined,
                              label: 'Handover POD',
                              color: context.colors.accent,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProofOfHandoverDocumentView(
                                      document:
                                          ProofOfHandoverDocument.fromBooking(
                                            b,
                                            signatureBase64:
                                                b.clientSignatureUrl,
                                          ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 50)).fadeIn().slideY(begin: 0.05);
  }
}

class _DocButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DocButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fg = color ?? Colors.white;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: GlassPill(
          tint: color,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassContainer(
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
