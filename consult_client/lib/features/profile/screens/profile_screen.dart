import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../auth/providers/auth_provider.dart';
import '../../booking/providers/booking_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/glass.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, BookingProvider>(
      builder: (context, auth, bookingProv, _) {
        final user = auth.user;
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              const Positioned.fill(child: AuroraBackground()),
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: GlassPageHeader(title: 'Profile')),

                  // ── Identity ─────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, 28, 24, 28),
                      child: Column(
                        children: [
                          GlassContainer(
                            width: 96,
                            height: 96,
                            radius: 48,
                            glow: true,
                            tint: context.colors.accent,
                            child: Center(
                              child: Text(
                                user?.initials ?? 'U',
                                style: TextStyle(
                                  color: context.colors.accentLight,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ).animate().scale(
                            duration: 400.ms,
                            curve: Curves.elasticOut,
                          ),

                          SizedBox(height: 16),

                          Text(
                            user?.fullName ?? 'User',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ).animate(delay: 100.ms).fadeIn(),

                          SizedBox(height: 4),

                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ).animate(delay: 150.ms).fadeIn(),

                          SizedBox(height: 2),

                          Text(
                            user?.phone ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ).animate(delay: 200.ms).fadeIn(),

                          SizedBox(height: 24),

                          GlassContainer(
                            radius: 24,
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Row(
                              children: [
                                _StatTile(
                                  value: '${bookingProv.bookings.length}',
                                  label: 'Bookings',
                                ),
                                Container(
                                  width: 1,
                                  height: 32,
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                                _StatTile(
                                  value:
                                      '${bookingProv.completedBookings.length}',
                                  label: 'Completed',
                                ),
                                Container(
                                  width: 1,
                                  height: 32,
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                                _StatTile(
                                  value: '${bookingProv.activeBookings.length}',
                                  label: 'Active',
                                ),
                              ],
                            ),
                          ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
                        ],
                      ),
                    ),
                  ),

                  // ── Menu ─────────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          _MenuSection(
                            title: 'Account',
                            items: [
                              _MenuItem(
                                Icons.person_outline_rounded,
                                'Edit Profile',
                                'Update your personal info',
                                onTap: () => _showEditProfile(context, auth),
                              ),
                              _MenuItem(
                                Icons.notifications_outlined,
                                'Notifications',
                                'Manage notification preferences',
                                onTap: () => context.push(
                                  AppConstants.routeNotifications,
                                ),
                              ),
                              _MenuItem(
                                Icons.security_rounded,
                                'Security',
                                'Password and security settings',
                                onTap: () {},
                              ),
                            ],
                          ),

                          SizedBox(height: 22),

                          _MenuSection(
                            title: 'My Activity',
                            items: [
                              _MenuItem(
                                Icons.list_alt_rounded,
                                'My Bookings',
                                'View all your bookings',
                                onTap: () =>
                                    context.go(AppConstants.routeBookings),
                              ),
                              _MenuItem(
                                Icons.credit_card_rounded,
                                'Payment History',
                                'View all transactions',
                                onTap: () =>
                                    context.go(AppConstants.routePayments),
                              ),
                              _MenuItem(
                                Icons.directions_car_filled_rounded,
                                'Vehicle Garage & Records',
                                'View vehicle profiles & official transport documents',
                                onTap: () =>
                                    context.push(AppConstants.routeGarage),
                              ),
                              _MenuItem(
                                Icons.upload_file_rounded,
                                'My Documents',
                                'Manage your uploaded documents',
                                onTap: () {},
                              ),
                            ],
                          ),

                          SizedBox(height: 22),

                          _MenuSection(
                            title: 'Support',
                            items: [
                              _MenuItem(
                                Icons.help_outline_rounded,
                                'Help & FAQ',
                                'Frequently asked questions',
                                onTap: () {},
                              ),
                              _MenuItem(
                                Icons.support_agent_rounded,
                                'Contact Support',
                                'Chat with our team',
                                onTap: () {},
                              ),
                              _MenuItem(
                                Icons.star_outline_rounded,
                                'Rate the App',
                                'Leave us a review',
                                onTap: () {},
                              ),
                            ],
                          ),

                          SizedBox(height: 22),

                          _MenuSection(
                            title: 'Legal',
                            items: [
                              _MenuItem(
                                Icons.description_outlined,
                                'Terms of Service',
                                '',
                                onTap: () {},
                              ),
                              _MenuItem(
                                Icons.privacy_tip_outlined,
                                'Privacy Policy',
                                '',
                                onTap: () {},
                              ),
                              _MenuItem(
                                Icons.info_outline_rounded,
                                'About Carpital Consult v1.0.0',
                                '',
                                onTap: () {},
                              ),
                            ],
                          ),

                          SizedBox(height: 28),

                          Semantics(
                            button: true,
                            child: GestureDetector(
                              onTap: () => _confirmLogout(context, auth),
                              child: GlassPill(
                                tint: context.colors.error,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.logout_rounded,
                                      size: 18,
                                      color: context.colors.error,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Sign Out',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: context.colors.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Clear the floating nav bar.
                          SizedBox(
                            height: MediaQuery.paddingOf(context).bottom + 24,
                          ),
                        ],
                      ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GlassSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Sign Out?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Are you sure you want to sign out?',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: GlassPill(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(ctx);
                      await auth.logout();
                      if (context.mounted) context.go(AppConstants.routeLogin);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: context.colors.error,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: context.colors.error.withValues(alpha: 0.35),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Sign Out',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfile(BuildContext context, AuthProvider auth) {
    final firstCtrl = TextEditingController(text: auth.user?.firstName ?? '');
    final lastCtrl = TextEditingController(text: auth.user?.lastName ?? '');
    final phoneCtrl = TextEditingController(text: auth.user?.phone ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _GlassSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: firstCtrl,
                      decoration: InputDecoration(labelText: 'First Name'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: lastCtrl,
                      decoration: InputDecoration(labelText: 'Last Name'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: phoneCtrl,
                decoration: InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 20),
              CustomButton(
                label: 'Save Changes',
                borderRadius: 30,
                onPressed: () async {
                  await auth.updateProfile(
                    firstName: firstCtrl.text.trim(),
                    lastName: lastCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;

  const _StatTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dark frosted bottom sheet floating just above the screen edge.
class _GlassSheet extends StatelessWidget {
  final Widget child;
  const _GlassSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: GlassContainer(
          radius: 32,
          blur: true,
          child: Container(
            padding: EdgeInsets.fromLTRB(24, 14, 24, 24),
            decoration: BoxDecoration(
              color: Color(0xE6101010),
              borderRadius: BorderRadius.circular(32),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 6, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.45),
              letterSpacing: 1.2,
            ),
          ),
        ),
        GlassContainer(
          radius: 24,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                ListTile(
                  leading: GlassContainer(
                    width: 36,
                    height: 36,
                    radius: 12,
                    child: Icon(
                      items[i].icon,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  title: Text(
                    items[i].title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: items[i].subtitle.isEmpty
                      ? null
                      : Text(
                          items[i].subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.35),
                    size: 20,
                  ),
                  onTap: items[i].onTap,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                if (i < items.length - 1)
                  Padding(
                    padding: EdgeInsets.only(left: 68, right: 16),
                    child: Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _MenuItem(this.icon, this.title, this.subtitle, {required this.onTap});
}
