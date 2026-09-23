import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/driver_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final driver = auth.driver;

    if (driver == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: DriverColors.accent)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Driver Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // Header Profile Info (Carbon card)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF222222)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      shape: BoxShape.circle,
                      border: Border.all(color: DriverColors.accent, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      driver.initials,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: DriverColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    driver.fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    driver.email,
                    style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF191919),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF262626)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${driver.rating} Rating  •  ${driver.totalJobs} Completed Missions',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.05),
            
            const SizedBox(height: 20),

            // Vehicle Credentials
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Vehicle & Logistics Credentials',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF888888)),
              ),
            ),
            const SizedBox(height: 10),
            _buildInfoCard([
              _InfoRow(
                icon: Icons.badge_outlined,
                label: 'Driver License',
                value: driver.licenseNumber ?? 'Verified #UK-48910',
              ),
              const Divider(height: 1, color: Color(0xFF1E1E1E)),
              _InfoRow(
                icon: Icons.directions_car_outlined,
                label: 'Transport Rig Plate',
                value: driver.vehiclePlate ?? 'GB72 AUT',
              ),
            ]).animate(delay: 50.ms).fadeIn(),
            
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Account & System',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF888888)),
              ),
            ),
            const SizedBox(height: 10),
            
            _buildInfoCard([
              _SettingsTile(icon: Icons.notifications_none_rounded, title: 'Push Dispatch Alerts', onTap: () {}),
              const Divider(height: 1, color: Color(0xFF1E1E1E)),
              _SettingsTile(icon: Icons.security_rounded, title: 'Security & Access', onTap: () {}),
              const Divider(height: 1, color: Color(0xFF1E1E1E)),
              _SettingsTile(icon: Icons.help_outline_rounded, title: 'Dispatch Operations Support', onTap: () {}),
              const Divider(height: 1, color: Color(0xFF1E1E1E)),
              _SettingsTile(
                icon: Icons.logout_rounded,
                title: 'Sign Out',
                textColor: const Color(0xFFFF5252),
                iconColor: const Color(0xFFFF5252),
                onTap: () async {
                  await auth.logout();
                  if (context.mounted) context.go(AppRoutes.login);
                },
              ),
            ]).animate(delay: 100.ms).fadeIn(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: DriverColors.accent, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 13)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor ?? DriverColors.accent, size: 20),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: textColor ?? Colors.white,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF444444), size: 18),
    );
  }
}
