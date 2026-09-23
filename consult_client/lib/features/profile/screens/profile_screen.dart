import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../auth/providers/auth_provider.dart';
import '../../booking/providers/booking_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, BookingProvider>(
      builder: (context, auth, bookingProv, _) {
        final user = auth.user;
        return Scaffold(
          backgroundColor: context.colors.background,
          body: CustomScrollView(
            slivers: [
              // ── Tesla-style profile header: flat black, no gradient ────
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 20, 24, 28),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: context.colors.accent.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(color: context.colors.accent.withValues(alpha: 0.4), width: 2),
                          ),
                          child: Center(
                            child: Text(
                              user?.initials ?? 'U',
                              style: TextStyle(
                                color: context.colors.accent,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),

                        SizedBox(height: 14),

                        Text(
                          user?.fullName ?? 'User',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                        ).animate(delay: 100.ms).fadeIn(),

                        SizedBox(height: 4),

                        Text(
                          user?.email ?? '',
                          style: TextStyle(fontSize: 13, color: context.colors.textLight),
                        ).animate(delay: 150.ms).fadeIn(),

                        SizedBox(height: 2),

                        Text(
                          user?.phone ?? '',
                          style: TextStyle(fontSize: 13, color: context.colors.textLight),
                        ).animate(delay: 200.ms).fadeIn(),

                        SizedBox(height: 24),

                        // Stats row — Tesla flat style
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              _StatTile(
                                value: '${bookingProv.bookings.length}',
                                label: 'Bookings',
                              ),
                              Container(width: 1, height: 32, color: context.colors.divider),
                              _StatTile(
                                value: '${bookingProv.completedBookings.length}',
                                label: 'Completed',
                              ),
                              Container(width: 1, height: 32, color: context.colors.divider),
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
              ),

              // Sections
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _MenuSection(
                        title: 'Account',
                        items: [
                          _MenuItem(Icons.person_outline_rounded, 'Edit Profile', 'Update your personal info', onTap: () => _showEditProfile(context, auth)),
                          _MenuItem(Icons.notifications_outlined, 'Notifications', 'Manage notification preferences', onTap: () => context.push(AppConstants.routeNotifications)),
                          _MenuItem(Icons.security_rounded, 'Security', 'Password and security settings', onTap: () {}),
                        ],
                      ),

                      SizedBox(height: 10),

                      _MenuSection(
                        title: 'My Activity',
                        items: [
                          _MenuItem(Icons.list_alt_rounded, 'My Bookings', 'View all your bookings', onTap: () => context.go(AppConstants.routeBookings)),
                          _MenuItem(Icons.credit_card_rounded, 'Payment History', 'View all transactions', onTap: () => context.go(AppConstants.routePayments)),
                          _MenuItem(Icons.directions_car_filled_rounded, 'Vehicle Garage & Records', 'View vehicle profiles & official transport documents', onTap: () => context.push(AppConstants.routeGarage)),
                          _MenuItem(Icons.upload_file_rounded, 'My Documents', 'Manage your uploaded documents', onTap: () {}),
                        ],
                      ),

                      SizedBox(height: 10),

                      _MenuSection(
                        title: 'Support',
                        items: [
                          _MenuItem(Icons.help_outline_rounded, 'Help & FAQ', 'Frequently asked questions', onTap: () {}),
                          _MenuItem(Icons.support_agent_rounded, 'Contact Support', 'Chat with our team', onTap: () {}),
                          _MenuItem(Icons.star_outline_rounded, 'Rate the App', 'Leave us a review', onTap: () {}),
                        ],
                      ),

                      SizedBox(height: 10),

                      _MenuSection(
                        title: 'Legal',
                        items: [
                          _MenuItem(Icons.description_outlined, 'Terms of Service', '', onTap: () {}),
                          _MenuItem(Icons.privacy_tip_outlined, 'Privacy Policy', '', onTap: () {}),
                          _MenuItem(Icons.info_outline_rounded, 'About Carpital Consult v1.0.0', '', onTap: () {}),
                        ],
                      ),

                      SizedBox(height: 20),

                      // Logout — clean text button, no outlined box
                      GestureDetector(
                        onTap: () => _confirmLogout(context, auth),
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout_rounded, size: 18, color: context.colors.error),
                              SizedBox(width: 8),
                              Text(
                                'Sign Out',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.colors.error),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 32),
                    ],
                  ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
                ),
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
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: context.colors.divider, borderRadius: BorderRadius.circular(2))),
            SizedBox(height: 24),
            Text('Sign Out?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
            SizedBox(height: 8),
            Text('Are you sure you want to sign out?', style: TextStyle(fontSize: 14, color: context.colors.textSecondary)),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(color: context.colors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text('Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.colors.textPrimary))),
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
                      height: 50,
                      decoration: BoxDecoration(color: context.colors.error, borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text('Sign Out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))),
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

  void _showEditProfile(BuildContext context, AuthProvider auth) {
    final firstCtrl = TextEditingController(text: auth.user?.firstName ?? '');
    final lastCtrl = TextEditingController(text: auth.user?.lastName ?? '');
    final phoneCtrl = TextEditingController(text: auth.user?.phone ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: context.colors.divider, borderRadius: BorderRadius.circular(2)))),
              SizedBox(height: 20),
              Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: firstCtrl, decoration: InputDecoration(labelText: 'First Name'))),
                  SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: lastCtrl, decoration: InputDecoration(labelText: 'Last Name'))),
                ],
              ),
              SizedBox(height: 12),
              TextFormField(controller: phoneCtrl, decoration: InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await auth.updateProfile(
                      firstName: firstCtrl.text.trim(),
                      lastName: lastCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text('Save Changes'),
                ),
              ),
              SizedBox(height: 8),
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
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
          SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: context.colors.textLight)),
        ],
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
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.colors.textLight, letterSpacing: 1),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  ListTile(
                    leading: Icon(item.icon, size: 20, color: context.colors.textSecondary),
                    title: Text(item.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.colors.textPrimary)),
                    subtitle: item.subtitle.isEmpty ? null : Text(item.subtitle, style: TextStyle(fontSize: 12, color: context.colors.textLight)),
                    trailing: Icon(Icons.chevron_right_rounded, color: context.colors.textLight, size: 20),
                    onTap: item.onTap,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  if (i < items.length - 1)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Container(height: 1, color: context.colors.divider),
                    ),
                ],
              );
            }).toList(),
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
