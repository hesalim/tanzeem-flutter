import 'package:flutter/material.dart';

import '../auth/auth_session.dart';
import '../models/service.dart';
import 'business_profile_screen.dart';
import 'login_screen.dart';
import 'my_profile_screen.dart';
import 'services_screen.dart';
import 'staff_screen.dart';

class MoreScreen extends StatelessWidget {
  final List<Service> services;

  const MoreScreen({super.key, required this.services});

  static const Color tanzeemGreen = Color(0xFF0B5F4A);
  static const Color tanzeemMint = Color(0xFFE4F5EF);
  static const Color tanzeemBackground = Color(0xFFF7F9F8);
  static const Color tanzeemText = Color(0xFF18221F);
  static const Color tanzeemMuted = Color(0xFF6F7D77);
  static const Color danger = Color(0xFFC53B3B);

  bool get isOwner => AuthSession.role == 'OWNER';

  Widget buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = tanzeemGreen,
    Color iconBackground = tanzeemMint,
    Color titleColor = tanzeemText,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8ECEA)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: tanzeemMuted),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right_rounded, color: tanzeemMuted),
          ],
        ),
      ),
    );
  }

  Future<void> logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log out'),
          content: const Text('Are you sure you want to log out of Tanzeem?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Log out', style: TextStyle(color: danger)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await AuthSession.clear();

    if (!context.mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tanzeemBackground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          children: [
            const Text(
              'More',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w700,
                color: tanzeemText,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              isOwner
                  ? 'Manage your business and account'
                  : 'Manage your account',
              style: const TextStyle(fontSize: 13, color: tanzeemMuted),
            ),

            if (isOwner) ...[
              const SizedBox(height: 24),

              const Text(
                'Business',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: tanzeemText,
                ),
              ),

              const SizedBox(height: 10),

              buildMenuItem(
                icon: Icons.design_services_outlined,
                title: 'Services',
                subtitle: 'Manage services, pricing and duration',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServicesScreen(services: services),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              buildMenuItem(
                icon: Icons.storefront_outlined,
                title: 'Business Profile',
                subtitle: 'Business name, contact and details',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BusinessProfileScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              buildMenuItem(
                icon: Icons.groups_2_outlined,
                title: 'Team',
                subtitle: 'Manage staff and team members',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StaffScreen(),
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 24),

            const Text(
              'Account',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: tanzeemText,
              ),
            ),

            const SizedBox(height: 10),

            buildMenuItem(
              icon: Icons.person_outline_rounded,
              title: 'My Profile',
              subtitle: 'Personal information and account details',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyProfileScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            buildMenuItem(
              icon: Icons.logout_rounded,
              title: 'Log out',
              subtitle: 'Sign out of your Tanzeem account',
              iconColor: danger,
              iconBackground: const Color(0xFFFDE8E8),
              titleColor: danger,
              onTap: () {
                logout(context);
              },
            ),

            const SizedBox(height: 24),

            const Text(
              'Tanzeem',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: tanzeemText,
              ),
            ),

            const SizedBox(height: 10),

            buildMenuItem(
              icon: Icons.help_outline_rounded,
              title: 'Help & Support',
              subtitle: 'Get help using Tanzeem',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Help & Support coming later')),
                );
              },
            ),

            const SizedBox(height: 28),

            Center(
              child: Text(
                AuthSession.role == 'STAFF' ? 'Tanzeem • Staff' : 'Tanzeem',
                style: TextStyle(
                  color: tanzeemMuted.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
