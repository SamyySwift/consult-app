import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/vehicle_document_model.dart';

class ProofOfHandoverDocumentView extends StatelessWidget {
  final ProofOfHandoverDocument document;

  const ProofOfHandoverDocumentView({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // Dark background behind paper
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Proof of Handover (POD)', style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preparing certificate for sharing...')),
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
                            'AUTOMOVE INC.',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'PROOF OF HANDOVER / DELIVERY CERTIFICATE',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _InfoLabel('CERTIFICATE NO.', document.certificateNumber),
                          const SizedBox(height: 8),
                          _InfoLabel('HANDOVER DATE', document.formattedHandoverDate),
                        ],
                      ),
                      QrImageView(
                        data: document.certificateNumber,
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

                  // Section 1: Vehicle Assessed
                  const _SectionHeader('VEHICLE DETAILS'),
                  Row(
                    children: [
                      Expanded(child: _InfoLabel('VEHICLE NAME', document.vehicleName)),
                      Expanded(child: _InfoLabel('COLOR', document.vehicleColor)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoLabel('VIN / CHASSIS NO.', document.vehicleVin),
                  const SizedBox(height: 24),

                  // Section 2: Logistics / Handover Detail
                  const _SectionHeader('DELIVERY INFORMATION'),
                  _InfoLabel('HANDOVER ADDRESS', document.deliveryAddress),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _InfoLabel('LOGISTICS CAPTAIN', document.driverName)),
                      Expanded(child: _InfoLabel('DRIVER PHONE', document.driverPhone)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Divider(color: Colors.black12, thickness: 2),
                  const SizedBox(height: 24),

                  // Section 3: Inspection Checklist
                  const _SectionHeader('HANDOVER CHECKLIST'),
                  _CheckItem('Vehicle exterior inspected and damage recorded (if any)', document.isInspectionCompleted),
                  _CheckItem('Vehicle interior and accessories inspected', document.isInspectionCompleted),
                  _CheckItem('Keys handed over to designated recipient', document.isGoodConditionAcknowledged),
                  _CheckItem('Vehicle accepted in good overall condition', document.isGoodConditionAcknowledged),
                  const SizedBox(height: 32),

                  // Section 4: Signature
                  const _SectionHeader('CLIENT ACKNOWLEDGEMENT'),
                  if (document.clientSignatureBase64 != null && document.clientSignatureBase64!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Image.memory(
                            base64Decode(document.clientSignatureBase64!.split(',').last),
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Digitally Signed upon delivery',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black12, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade50,
                      ),
                      child: const Center(
                        child: Text(
                          'PENDING CLIENT SIGNATURE',
                          style: TextStyle(
                            color: Colors.black38,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 48),

                  // Footer Stamp
                  Center(
                    child: Column(
                      children: [
                        if (document.isDelivered)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue.shade800, width: 2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'HANDOVER COMPLETED',
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        const Text(
                          'AutoMove Inc. digital handover certificate.\nThis document verifies the transfer of possession and condition acknowledgement.',
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

class _CheckItem extends StatelessWidget {
  final String text;
  final bool isChecked;

  const _CheckItem(this.text, this.isChecked);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
            color: isChecked ? Colors.green.shade700 : Colors.black26,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isChecked ? Colors.black : Colors.black54,
                fontSize: 14,
                fontWeight: isChecked ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
