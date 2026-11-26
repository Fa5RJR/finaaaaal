import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:al_sharif/core/theme/app_fonts.dart';
import 'package:al_sharif/core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color primaryTeal = Color(0xFF20A6A0);

  Future<void> _changeTheme(BuildContext switcherContext, bool goingDark) async {
    ThemeSwitcher.of(switcherContext).changeTheme(
      theme: goingDark ? AppThemes.dark : AppThemes.light,
      isReversed: !goingDark, // الرجوع للأبيض: الدايرة تنكمش
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', goingDark);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إعدادات التطبيق'.tr(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white), // سهم الرجوع
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.language, color: primaryTeal),
                title: Text('تغيير اللغة (Language)'.tr()),
                trailing: Text(
                  context.locale.languageCode == 'ar' ? 'العربية' : 'English',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryTeal,
                  ),
                ),
                onTap: () async {
                  if (context.locale.languageCode == 'ar') {
                    await context.setLocale(const Locale('en'));
                  } else {
                    await context.setLocale(const Locale('ar'));
                  }
                  if (mounted) setState(() {});
                },
              ),

              // خيار الوضع الليلي
              ListTile(
                leading: const Icon(Icons.brightness_6, color: primaryTeal),
                title: Text('الوضع الليلي (Dark Mode)'.tr()),
                // ThemeSwitcher حوالين الـ Switch بس، عشان الدايرة تطلع من مكانه
                trailing: ThemeSwitcher(
                  clipper: const ThemeSwitcherCircleClipper(),
                  builder: (switcherContext) {
                    return Switch(
                      value: isDarkMode,
                      activeColor: primaryTeal,
                      onChanged: (value) => _changeTheme(switcherContext, value),
                    );
                  },
                ),
              ),

              const Divider(height: 15),

              const SizedBox(height: 8),
              const FontSizeSelector(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}