import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:al_sharif/core/routes/app_routes.dart';
import 'package:al_sharif/core/theme/app_theme.dart';
import 'package:al_sharif/core/theme/app_fonts.dart';
import 'package:al_sharif/features/splash/splash_screen.dart';


Future<void> main() async {
  // التأكد من تهيئة نظام فلاتر الأساسي قبل تنفيذ أي أوامر برمجية تالية
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة حزمة الترجمة واللغات لتعمل بشكل صحيح قبل تشغيل الواجهات
  await EasyLocalization.ensureInitialized();

  // تهيئة الاتصال بقاعدة بيانات Supabase باستخدام رابط المشروع والمفتاح الخاص به
  await Supabase.initialize(
    url: 'https://dzaxbrfnzijrmcdwnxvz.supabase.co',
    publishableKey: 'sb_publishable_ryltILM76W3XZS1jrjvhWQ_oad2Yb_V',
  );

  // أخذ نسخة من التخزين المحلي (SharedPreferences) لقراءة تفضيلات المستخدم المحفوظة مسبقاً
  final prefs = await SharedPreferences.getInstance();

  // التحقق هل كان المستخدم مفعلًا للوضع الداكن (Dark Mode) سابقاً؟ (لو لم توجد قيمة مسجلة، افترض أنه false أي وضع فاتح)
  final isDark = prefs.getBool('isDark') ?? false;

  // تحميل إعدادات مقياس الخطوط المحفوظة للمستخدم
  await FontScaleController.load();

  // تشغيل التطبيق وتغليفه بحزمة الترجمة واللغات
  runApp(
    EasyLocalization(
      // تحديد اللغات التي يدعمها التطبيق (العربية والإنجليزية هنا)
      supportedLocales: const [Locale('ar'), Locale('en')],

      // مسار المجلد الذي يحتوي على ملفات الترجمة (JSON)
      path: 'assets/translations',

      // اللغة الاحتياطية في حال حدث خطأ أو لم تتوفر ترجمة لكلمة ما
      fallbackLocale: const Locale('ar'),

      // اللغة التي سيفتح بها التطبيق افتراضياً
      startLocale: const Locale('ar'),

      // استدعاء التطبيق الأساسي MyApp وتمرير الثيم المناسب له (داكن أم فاتح) بناءً على قيمة isDark
      child: MyApp(initTheme: isDark ? AppThemes.dark : AppThemes.light),
    ),
  );
}
// تعريف واجهة MyApp كـ StatelessWidget لأن حالتها الداخلية لا تتغير (تعتمد على القيم الممررة لها)
class MyApp extends StatelessWidget {
  // متغير لتخزين الثيم الأولي الذي تم تحديده في دالة main
  final ThemeData initTheme;

  // المُنشئ (Constructor) ويشترط فيه استقبال الثيم الأولي
  const MyApp({super.key, required this.initTheme});

  @override
  Widget build(BuildContext context) {
    // استخدام ThemeProvider لتوفير وإدارة الثيم القابل للتبديل بسلاسة داخل التطبيق
    return ThemeProvider(
      initTheme: initTheme,
      builder: (context, theme) {
        // بناء تطبيق Material القياسي
        return MaterialApp(
          // إخفاء شريط الـ Debug الأحمر المزعج من زاوية الشاشة العلوية
          debugShowCheckedModeBanner: false,

          // تفعيل وفود ومندوبي الترجمة المستخرجة من سياق التطبيق
          localizationsDelegates: context.localizationDelegates,

          // تفعيل اللغات المدعومة
          supportedLocales: context.supportedLocales,

          // تحديد اللغة الحالية للتطبيق
          locale: context.locale,

          // تطبيق الثيم القادم من الـ ThemeProvider (سواء كان ليلي أو فاتح)
          theme: theme,


          builder: (context, child) => ThemeSwitchingArea(
            child: applyFontScale(context, child),
          ),

          // تحديد أول شاشة تظهر للمستخدم بمجرد فتح التطبيق (شاشة السبلاش / الترحيب)
          home: const SplashScreen(),

          // ربط مسارات التنقل (Routes) الخاصة بصفحات التطبيق لتسهيل الانتقال بينها
          routes: AppRoutes.routes,
        );
      },
    );
  }
}