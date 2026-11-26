import 'package:al_sharif/core/routes/app_routes.dart';
import 'package:al_sharif/features/auth/data/authService.dart';
import 'package:al_sharif/features/auth/screens/verfiyOTP.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _navy = Color(0xFF123653);
  static const Color _teal = Color(0xFF20A6A0);
  static const Color _tealDark = Color(0xFF0F7F7A);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // حفظ الـ ID محلياً (اختياري: Supabase بيحفظ الـ session لوحده)
  Future<void> _saveCurrentUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', userId);
  }

  // تسجيل الدخول عن طريق Supabase Auth (التحقق من الباسورد بيتم في السيرفر)
  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final res = await AuthService.instance.signIn(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      final userId = res.user!.id;
      await _saveCurrentUserId(userId);

      // هل الحساب أدمن؟ (لو فشل الفحص لأي سبب يكمل كمستخدم عادي)
      final isAdmin = await AuthService.instance.isAdmin();
      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed(
        isAdmin ? AppRoutes.adminDashboard : AppRoutes.home,
        arguments: userId,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      final unconfirmed = e.code == 'email_not_confirmed' ||
          e.message.toLowerCase().contains('email not confirmed');
      if (unconfirmed) {
        await _goToVerify();
      } else {
        _showMessage(AuthService.errorKey(e).tr());
      }
    } catch (e) {
      if (mounted) _showMessage('${'حصل خطأ، حاول تاني'.tr()}: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // حساب موجود بس الإيميل مش مؤكد: نبعت كود جديد ونفتح شاشة الكود
  Future<void> _goToVerify() async {
    final email = _emailCtrl.text.trim();
    try {
      await AuthService.instance.resendSignupOtp(email: email);
    } catch (_) {
      // لو الإرسال فشل (مثلاً rate limit) نفتح الشاشة برضه،
      // وفيها زر إعادة الإرسال
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VerifyOtpScreen(email: email)),
    );
  }

  InputDecoration _fieldDecoration(
      BuildContext context, {
        required IconData icon,
        Widget? suffix,
        String? hint,
      }) {
    final theme = Theme.of(context);
    OutlineInputBorder border(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: theme.colorScheme.onSurface, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: theme.cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: border(theme.dividerColor),
      focusedBorder: border(_tealDark, 2),
      errorBorder: border(Colors.red.shade700),
      focusedErrorBorder: border(Colors.red.shade700, 2),
    );
  }

  Widget _label(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // دوايـر الخلفية
        PositionedDirectional(
          start: -110,
          top: -90,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _teal.withValues(alpha: 0.14),
            ),
          ),
        ),
        PositionedDirectional(
          start: -60,
          top: -40,
          child: Container(
            width: 208,
            height: 208,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _teal.withValues(alpha: 0.14),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 44),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'مركز الشريف للأطراف الصناعية'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Text(
                  'أهلاً بعودتك'.tr(),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    'سجّل دخولك لمتابعة مواعيدك وتقدير تكلفة طرفك الصناعي.'
                        .tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFFC9DCEA),
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label(context, 'البريد الإلكتروني'.tr()),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: _fieldDecoration(
                context,
                icon: Icons.mail_outline,
                hint: 'name@example.com',
              ),
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.isEmpty) return 'ادخل البريد الإلكتروني'.tr();
                final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
                if (!ok) return 'البريد الإلكتروني غير صحيح'.tr();
                return null;
              },
            ),
            const SizedBox(height: 22),
            _label(context, 'كلمة المرور'.tr()),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _loading ? null : _onSubmit(),
              decoration: _fieldDecoration(
                context,
                icon: Icons.lock_outline,
                suffix: IconButton(
                  tooltip: _obscure
                      ? 'إظهار كلمة المرور'.tr()
                      : 'إخفاء كلمة المرور'.tr(),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: cs.onSurface,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'ادخل كلمة المرور'.tr();
                }
                if (value.length < 6) return 'كلمة المرور قصيرة'.tr();
                return null;
              },
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _tealDark,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _tealDark.withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
                    : Text(
                  'دخول'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ليس لديك حساب؟'.tr(),
                  style: TextStyle(
                    fontSize: 15,
                    color: cs.onSurface.withValues(alpha: 0.75),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.signup),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    foregroundColor: _tealDark,
                  ),
                  child: Text(
                    'إنشاء حساب'.tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
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

  @override
  Widget build(BuildContext context) {
    context.locale; // عشان الشاشة تتبني من جديد لما اللغة تتغير

    return Scaffold(
      backgroundColor: _navy,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    _buildHeader(context),
                    Expanded(child: _buildForm(context)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}