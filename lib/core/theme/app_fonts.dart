import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// التحكم في حجم الخط: 0 = عادي (الافتراضي)، 1 = كبير، 2 = كبير جداً
class FontScaleController {
  static const String _prefKey = 'font_scale_index';

  /// معاملات التكبير لكل مقاس
  static const List<double> scales = [1.0, 1.2, 1.4];

  /// المقاس الحالي. أي ويدجت بتسمع عليه بتتحدث لحظياً
  static final ValueNotifier<int> index = ValueNotifier<int>(0);

  /// نادِها مرة واحدة في main() قبل runApp
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_prefKey) ?? 0;
    index.value = saved.clamp(0, scales.length - 1);
  }

  /// بتغيّر المقاس وتحفظه
  static Future<void> set(int i) async {
    final v = i.clamp(0, scales.length - 1);
    index.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, v);
  }

  static double get scale => scales[index.value];
}

/// بتلف التطبيق كله وتطبّق حجم الخط. استخدمها في MaterialApp.builder
Widget applyFontScale(BuildContext context, Widget? child) {
  return ValueListenableBuilder<int>(
    valueListenable: FontScaleController.index,
    builder: (context, i, _) {
      final mq = MediaQuery.of(context);
      return MediaQuery(
        data: mq.copyWith(
          textScaler: TextScaler.linear(FontScaleController.scales[i]),
        ),
        child: child ?? const SizedBox.shrink(),
      );
    },
  );
}

/// كارت اختيار حجم الخط. حطه في صفحة الإعدادات
class FontSizeSelector extends StatelessWidget {
  const FontSizeSelector({super.key});

  static const Color _teal = Color(0xFF20A6A0);

  @override
  Widget build(BuildContext context) {
    context.locale;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: ValueListenableBuilder<int>(
        valueListenable: FontScaleController.index,
        builder: (context, selected, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.text_fields, color: _teal),
                  const SizedBox(width: 8),
                  Text(
                    'حجم الخط'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: 0, label: Text('عادي'.tr())),
                    ButtonSegment(value: 1, label: Text('كبير'.tr())),
                    ButtonSegment(value: 2, label: Text('كبير جداً'.tr())),
                  ],
                  selected: {selected},
                  onSelectionChanged: (s) => FontScaleController.set(s.first),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      return states.contains(WidgetState.selected)
                          ? _teal
                          : null;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      return states.contains(WidgetState.selected)
                          ? Colors.white
                          : null;
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'هذا مثال لحجم الخط المختار'.tr(),
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}