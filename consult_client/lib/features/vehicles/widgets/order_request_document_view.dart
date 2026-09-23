import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/vehicle_document_model.dart';

class OrderRequestDocumentView extends StatelessWidget {
  final OrderRequestDocument document;

  const OrderRequestDocumentView({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // Dark background behind paper
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Order Request Document', style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              // Share logic (e.g., generate PDF or image)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preparing document for sharing...')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: InteractiveViewer(
        boundaryMargin: const EdgeInsets.all(20),
        minScale: 0.5,
        maxScale: 3.0,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: 800, // Fixed width for A4 aspect ratio feel
              constraints: const BoxConstraints(maxWidth: 800),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CARPITAL CONSULT INC.',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'OFFICIAL TRANSPORT MANIFEST & WAYBILL',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _InfoLabel('DOCUMENT NO.', document.documentNumber),
                          const SizedBox(height: 8),
                          _InfoLabel('ISSUED DATE', document.formattedIssuedDate),
                        ],
                      ),
                      QrImageView(
                        data: document.documentNumber,
                        version: QrVersions.auto,
                        size: 90.0,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Colors.black87,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  const Divider(color: Colors.black12, thickness: 2),
                  const SizedBox(height: 24),

                  // Section 1: Client Information
                  const _SectionHeader('CLIENT INFORMATION'),
                  Row(
                    children: [
                      Expanded(child: _InfoLabel('CLIENT NAME', document.clientName)),
                      Expanded(child: _InfoLabel('PHONE NUMBER', document.clientPhone)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section 2: Vehicle Specifications
                  const _SectionHeader('VEHICLE SPECIFICATIONS'),
                  Row(
                    children: [
                      Expanded(child: _InfoLabel('VEHICLE', '${document.vehicleYear} ${document.vehicleMake} ${document.vehicleModel}')),
                      Expanded(child: _InfoLabel('COLOR', document.vehicleColor)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _InfoLabel('VIN / CHASSIS NO.', document.vehicleVin)),
                      Expanded(child: _InfoLabel('VEHICLE TYPE', document.vehicleType)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section 3: Logistics & Routing
                  const _SectionHeader('LOGISTICS & ROUTING'),
                  _InfoLabel('PICKUP ADDRESS', document.pickupAddress),
                  const SizedBox(height: 12),
                  _InfoLabel('DROPOFF ADDRESS', document.dropoffAddress),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _InfoLabel('SERVICE TIER', document.serviceType)),
                      Expanded(child: _InfoLabel('TRANSPORT MODE', document.transportMode)),
                      Expanded(child: _InfoLabel('INSURANCE', document.hasInsurance ? 'Covered' : 'None')),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Divider(color: Colors.black12, thickness: 2),
                  const SizedBox(height: 24),

                  // Section 4: Financial Breakdown
                  const _SectionHeader('FINANCIAL BREAKDOWN'),
                  _PriceRow('Base Transport Fare', '₦${_formatMoney(document.basePrice)}'),
                  if (document.insuranceFee > 0)
                    _PriceRow('Security & Insurance Fee', '₦${_formatMoney(document.insuranceFee)}'),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.black12, thickness: 1),
                  const SizedBox(height: 12),
                  _PriceRow('TOTAL AMOUNT', document.formattedTotalAmount, isTotal: true),
                  const SizedBox(height: 16),
                  _InfoLabel('PAYMENT REFERENCE', document.paymentReference),
                  
                  const SizedBox(height: 48),

                  // Footer
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green.shade700, width: 2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ORDER CONFIRMED',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Carpital Consult Inc. applies comprehensive transit policies governed by national logistics laws.\nThis document serves as an official electronic waybill.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black38,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatMoney(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{3})(?=\d)'),
          (m) => '${m[1]},',
        );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _InfoLabel extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLabel(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black45,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String amount;
  final bool isTotal;

  const _PriceRow(this.label, this.amount, {this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.black : Colors.black87,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: Colors.black,
              fontSize: isTotal ? 20 : 14,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
