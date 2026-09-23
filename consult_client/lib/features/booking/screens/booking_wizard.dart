import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../steps/step_1_vehicle_details.dart';
import '../steps/step_2_locations.dart';
import '../steps/step_3_service_type.dart';
import '../steps/step_4_insurance.dart';
import '../steps/step_5_documents.dart';
import '../steps/step_6_review_pay.dart';
import '../steps/step_7_confirmation.dart';

const _stepTitles = [
  'Vehicle Details',
  'Pickup & Delivery',
  'Service Type',
  'Insurance',
  'Documents',
  'Review & Pay',
  'Confirmation',
];


class BookingWizard extends StatefulWidget {
  const BookingWizard({super.key});

  @override
  State<BookingWizard> createState() => _BookingWizardState();
}

class _BookingWizardState extends State<BookingWizard> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _animateToPage(int page) {
    setState(() => _currentPage = page);
    _pageController.animateToPage(
      page,
      duration: Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, bookingProv, _) {
        final step = _currentPage;
        final isLastStep = step == 6;

        return LoadingOverlay(
          isLoading: bookingProv.isSubmitting,
          message: 'Confirming your booking...',
          child: Scaffold(
            backgroundColor: context.colors.background,
            appBar: step == 6
                ? null
                : AppBar(
                    leading: IconButton(
                      icon: Icon(Icons.close_rounded),
                      onPressed: () {
                        _showExitDialog(context, bookingProv);
                      },
                    ),
                    title: Text(_stepTitles[step]),
                    actions: [
                      if (step > 0)
                        TextButton(
                          onPressed: () {
                            bookingProv.previousStep();
                            _animateToPage(bookingProv.currentStep);
                          },
                          child: Text('Back'),
                        ),
                    ],
                  ),
            body: Column(
              children: [
                // Step progress bar
                if (!isLastStep) _StepProgressBar(currentStep: step, totalSteps: 6),

                // Page content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                      Step1VehicleDetails(onNext: () => _goNext(bookingProv)),
                      Step2Locations(onNext: () => _goNext(bookingProv)),
                      Step3ServiceType(onNext: () => _goNext(bookingProv)),
                      Step4Insurance(onNext: () => _goNext(bookingProv)),
                      Step5Documents(onNext: () => _goNext(bookingProv)),
                      Step6ReviewPay(onNext: () => _submitBooking(bookingProv)),
                      Step7Confirmation(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _goNext(BookingProvider prov) {
    prov.nextStep();
    _animateToPage(prov.currentStep);
  }

  Future<void> _submitBooking(BookingProvider prov) async {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id ??
        Supabase.instance.client.auth.currentUser?.id ??
        'b0000000-0000-0000-0000-000000000001';

    final booking = await prov.submitBooking(userId);
    if (!mounted) return;

    if (booking != null) {
      _animateToPage(6);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prov.errorMessage ?? 'Failed to submit booking. Please check connection.'),
          backgroundColor: context.colors.error,
        ),
      );
    }
  }

  void _showExitDialog(BuildContext context, BookingProvider prov) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: context.colors.divider, borderRadius: BorderRadius.circular(2))),
            SizedBox(height: 24),
            Text('Cancel Booking?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
            SizedBox(height: 8),
            Text('All progress will be lost.', style: TextStyle(fontSize: 14, color: context.colors.textSecondary)),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(color: context.colors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text('Continue', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.colors.textPrimary))),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      prov.resetDraft();
                      context.go('/home');
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(color: context.colors.error, borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text('Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepProgressBar({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: Column(
        children: [
          // Progress bar — Tesla-style thin green line
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (currentStep + 1) / (totalSteps + 1),
              backgroundColor: context.colors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(context.colors.accent),
              minHeight: 4,
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${currentStep + 1} of ${totalSteps + 1}',
                style: TextStyle(fontSize: 12, color: context.colors.textLight),
              ),
              Text(
                '${((currentStep + 1) / (totalSteps + 1) * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.colors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
