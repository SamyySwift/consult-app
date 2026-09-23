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
import '../../../core/widgets/status_badge.dart';

class VehicleGarageScreen extends StatelessWidget {
  const VehicleGarageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        title: Text(
          'Vehicle Garage & Documents',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Consumer<BookingProvider>(
        builder: (context, prov, _) {
          final records = VehicleRecord.extractFromBookings(prov.bookings);

          if (records.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car_filled_rounded, size: 56, color: context.colors.textLight),
          const SizedBox(height: 16),
          Text(
            'Garage is Empty',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Your registered vehicles and transport\ndocuments will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.textLight, fontSize: 14),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.surfaceVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.surfaceVariant.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.colors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(record.iconData, color: context.colors.accent, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.displayName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'VIN: ${record.vin.isNotEmpty ? record.vin : 'Not Specified'}',
                            style: TextStyle(fontSize: 12, color: context.colors.textLight, fontFamily: 'monospace'),
                          ),
                          const SizedBox(width: 8),
                          if (record.isCurrentlyInTransit)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: context.colors.accent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'IN TRANSIT',
                                style: TextStyle(color: context.colors.accent, fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                            )
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Details section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _InfoChip(label: 'Type', value: record.typeLabel),
                    _InfoChip(label: 'Color', value: record.color),
                    _InfoChip(label: 'Transports', value: '${record.totalTransports}'),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'TRANSPORT HISTORY & DOCUMENTS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: context.colors.textSecondary),
                ),
                const SizedBox(height: 12),
                
                // History List
                ...record.bookingHistory.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.colors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('MMM dd, yyyy').format(b.createdAt),
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            StatusBadge(status: b.status),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => OrderRequestDocumentView(
                                      document: OrderRequestDocument.fromBooking(b),
                                    ),
                                  ));
                                },
                                icon: const Icon(Icons.description_outlined, size: 16),
                                label: const Text('Order Waybill', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: context.colors.textPrimary,
                                  side: BorderSide(color: context.colors.surfaceVariant),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => ProofOfHandoverDocumentView(
                                      document: ProofOfHandoverDocument.fromBooking(b, signatureBase64: b.clientSignatureUrl),
                                    ),
                                  ));
                                },
                                icon: const Icon(Icons.verified_outlined, size: 16),
                                label: const Text('Handover POD', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: context.colors.accent,
                                  side: BorderSide(color: context.colors.accent.withValues(alpha: 0.5)),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 50)).fadeIn().slideY(begin: 0.05);
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
      ],
    );
  }
}
