import 'package:al_sharif/features/auth/screens/signin_screen.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:al_sharif/features/settings/settings_screen.dart';
import 'package:al_sharif/features/contact_us/contact_us_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color primaryTeal = Color(0xFF20A6A0);

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('تسجيل الخروج'.tr()),
        content: Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('تسجيل الخروج'.tr(),
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await Supabase.instance.client.auth.signOut();

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Supabase.instance.client.auth.currentUser;

    final email = user?.email ?? '';
    final meta = user?.userMetadata;
    final name = (meta?['full_name'] ??
        meta?['name'] ??
        meta?['username'] ??
        (email.contains('@') ? email.split('@').first : ''))
        .toString();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // ===== الأفاتار =====
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: primaryTeal.withAlpha(90), width: 2),
              ),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: primaryTeal.withAlpha(30),
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: primaryTeal,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withAlpha(140),
              ),
            ),

            const SizedBox(height: 36),

            // ===== القائمة =====
            _MenuTile(
              icon: Icons.settings_outlined,
              title: 'الإعدادات'.tr(),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _MenuTile(
              icon: Icons.support_agent_outlined,
              title: 'تواصل معنا'.tr(),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ContactUsScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _MenuTile(
              icon: Icons.logout,
              title: 'تسجيل الخروج'.tr(),
              color: Colors.red,
              showArrow: false,
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;
  final bool showArrow;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color = ProfileScreen.primaryTeal,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.onSurface.withAlpha(10),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(28),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color == Colors.red ? color : null,
                  ),
                ),
              ),
              if (showArrow)
                Icon(Icons.arrow_forward_ios,
                    size: 15,
                    color: theme.colorScheme.onSurface.withAlpha(100)),
            ],
          ),
        ),
      ),
    );
  }
}