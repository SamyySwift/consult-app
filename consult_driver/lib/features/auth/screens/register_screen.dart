import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/motion.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/driver_colors.dart';
import '../../../core/widgets/tap_target.dart';
import '../../../core/widgets/driver_button.dart';
import '../../../core/widgets/driver_text_field.dart';
import '../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_sheet_layout.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  // 0: name, email, phone; 1: company and password
  int _step = 0;

  // Partner companies a driver can drive for, managed in the admin dashboard
  List<({String id, String name})>? _partners;
  bool _partnersLoading = true;
  bool _partnersFailed = false;
  String? _partnerId;

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  Future<void> _loadPartners() async {
    setState(() {
      _partnersLoading = true;
      _partnersFailed = false;
    });
    final res = await ApiClient.instance.get('/api/driver/partners');
    if (!mounted) return;
    setState(() {
      _partnersLoading = false;
      if (res.isSuccess && res.data is List) {
        _partners = [
          for (final p in res.data as List)
            if (p is Map && p['id'] != null && p['name'] != null)
              (id: p['id'].toString(), name: p['name'].toString()),
        ];
        // Drop a selection that's no longer offered
        if (_partners!.every((p) => p.id != _partnerId)) _partnerId = null;
      } else {
        _partnersFailed = true;
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      partnerId: _partnerId!,
    );

    if (!mounted) return;

    if (!success && (auth.errorMessage ?? '').contains('no longer available')) {
      // The admin deactivated the chosen company while the form was open
      _loadPartners();
    }

    if (success) {
      if (auth.needsOtp) {
        final email = _emailController.text.trim();
        context.go('${AppRoutes.otp}?email=${Uri.encodeComponent(email)}');
      } else {
        context.go(AppRoutes.dashboard);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1E1E1E),
          content: Text(auth.errorMessage ?? 'Registration failed', style: const TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  /// Validates the details on step 1, then moves on to company and password.
  void _goToAccountStep() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _step = 1);
  }

  void _handleBack() {
    if (_step == 1) {
      FocusScope.of(context).unfocus();
      setState(() => _step = 0);
    } else {
      context.go(AppRoutes.login);
    }
  }

  Future<void> _pickCompany() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DriverColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _CompanySheet(partners: _partners!, selectedId: _partnerId),
    );
    if (picked != null) setState(() => _partnerId = picked);
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      );

  Widget _buildCompanyPicker() {
    Widget field;
    if (_partnersLoading) {
      field = const InputDecorator(
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.business_outlined, color: DriverColors.textSecondary, size: 20),
        ),
        child: Row(
          children: [
            SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 10),
            Text('Loading companies…', style: TextStyle(color: DriverColors.textLight, fontSize: 14)),
          ],
        ),
      );
    } else if (_partnersFailed) {
      field = _PickerNotice(
        text: "Couldn't load companies. Check your connection.",
        actionLabel: 'Retry',
        onAction: _loadPartners,
      );
    } else if (_partners!.isEmpty) {
      field = const _PickerNotice(
        text: 'No partner companies are available yet, so sign-up is closed. Please contact support.',
      );
    } else {
      // A field styled like the text inputs that opens a bottom sheet list,
      // rather than a dropdown whose menu doesn't match the rounded fields.
      field = FormField<String>(
        key: ValueKey(_partnerId),
        initialValue: _partnerId,
        validator: (id) => id == null ? 'Please select the company you drive for' : null,
        builder: (state) {
          final selected = _partners!.where((p) => p.id == _partnerId).firstOrNull;
          return Semantics(
            button: true,
            label: 'Company you drive for',
            value: selected?.name,
            child: TapTarget(
              onTap: _pickCompany,
              child: InputDecorator(
                isEmpty: selected == null,
                decoration: InputDecoration(
                  hintText: 'Select your company',
                  errorText: state.errorText,
                  prefixIcon: const Icon(Icons.business_outlined, color: DriverColors.textSecondary, size: 20),
                  suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, color: DriverColors.textSecondary),
                ),
                child: Text(
                  selected?.name ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 15, color: DriverColors.textPrimary, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_fieldLabel('Company You Drive For'), const SizedBox(height: 8), field],
    );
  }

  Widget _buildStepIndicator() {
    const titles = ['Your details', 'Your account'];
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 2; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= _step ? DriverColors.accent : Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Step ${_step + 1} of 2 · ${titles[_step]}',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      key: const ValueKey('details'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DriverTextField(
                label: 'First Name',
                hint: 'John',
                controller: _firstNameController,
                validator: (v) => AppValidators.validateRequired(v, field: 'First name'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DriverTextField(
                label: 'Last Name',
                hint: 'Doe',
                controller: _lastNameController,
                validator: (v) => AppValidators.validateRequired(v, field: 'Last name'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        DriverTextField(
          label: 'Email Address',
          hint: 'driver@consultlogistics.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          controller: _emailController,
          validator: AppValidators.validateEmail,
        ),
        const SizedBox(height: 20),
        DriverTextField(
          label: 'Phone Number',
          hint: '0801 234 5678',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          controller: _phoneController,
          validator: AppValidators.validatePhone,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 32),
        DriverButton(label: 'Continue', onPressed: _goToAccountStep),
      ],
    );
  }

  Widget _buildAccountStep(AuthProvider auth) {
    // Sign-up needs a company, so it's blocked until one can be chosen
    final canSubmit = _partners != null && _partners!.isNotEmpty;

    return Column(
      key: const ValueKey('account'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCompanyPicker(),
        const SizedBox(height: 20),
        DriverTextField(
          label: 'Security Password',
          hint: 'Create a password',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: _obscurePassword,
          controller: _passwordController,
          validator: AppValidators.validatePassword,
          textInputAction: TextInputAction.done,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: const Color(0xFF777777),
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 32),
        DriverButton(
          label: 'Submit Application',
          onPressed: canSubmit ? _handleRegister : null,
          isLoading: auth.isLoading,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AuthSheetLayout(
      sheetHeight: 0.8,
      onBack: _handleBack,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text.rich(
              const TextSpan(
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.6),
                children: [
                  TextSpan(text: 'Driver '),
                  TextSpan(text: 'Application', style: TextStyle(color: DriverColors.accent)),
                ],
              ),
              textAlign: TextAlign.center,
            ).motionAware(context).fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 6),

            Text(
              'Join our logistics network. Approved within 24 hours.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), height: 1.4, fontSize: 14),
            ).motionAware(context).fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 20),

            _buildStepIndicator(),

            const SizedBox(height: 24),

            AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0.04, 0), end: Offset.zero).animate(animation),
                  child: child,
                ),
              ),
              child: _step == 0 ? _buildDetailsStep() : _buildAccountStep(auth),
            ),

            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already a driver? ', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
                TapTarget(
                  onTap: () => context.go(AppRoutes.login),
                  child: const Text(
                    'Sign in',
                    style: TextStyle(color: DriverColors.accent, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet listing partner companies, with search once the list is long.
class _CompanySheet extends StatefulWidget {
  final List<({String id, String name})> partners;
  final String? selectedId;

  const _CompanySheet({required this.partners, this.selectedId});

  @override
  State<_CompanySheet> createState() => _CompanySheetState();
}

class _CompanySheetState extends State<_CompanySheet> {
  static const _searchThreshold = 8;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final shown = q.isEmpty
        ? widget.partners
        : widget.partners.where((p) => p.name.toLowerCase().contains(q)).toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 18, 24, 12),
                child: Text(
                  'Company you drive for',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              if (widget.partners.length > _searchThreshold)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: TextField(
                    autofocus: false,
                    onChanged: (v) => setState(() => _query = v),
                    style: const TextStyle(color: DriverColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Search companies',
                      prefixIcon: Icon(Icons.search_rounded, color: DriverColors.textSecondary, size: 20),
                    ),
                  ),
                ),
              Flexible(
                child: shown.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No companies match your search.', style: TextStyle(color: DriverColors.textSecondary)),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        itemCount: shown.length,
                        itemBuilder: (context, i) {
                          final p = shown[i];
                          final selected = p.id == widget.selectedId;
                          return ListTile(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            leading: Icon(
                              Icons.business_outlined,
                              color: selected ? DriverColors.accent : DriverColors.textSecondary,
                            ),
                            title: Text(
                              p.name,
                              style: TextStyle(
                                color: DriverColors.textPrimary,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                            trailing: selected
                                ? const Icon(Icons.check_circle_rounded, color: DriverColors.accent)
                                : null,
                            selected: selected,
                            selectedTileColor: DriverColors.accent.withValues(alpha: 0.08),
                            onTap: () => Navigator.of(context).pop(p.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stands in for the company dropdown when there's nothing to choose from.
class _PickerNotice extends StatelessWidget {
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _PickerNotice({required this.text, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: DriverColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DriverColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: DriverColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(color: DriverColors.textPrimary, fontSize: 13, height: 1.35)),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!, style: const TextStyle(color: DriverColors.accent, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}
