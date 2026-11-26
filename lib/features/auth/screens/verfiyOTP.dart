import 'dart:async';
import 'package:al_sharif/core/routes/app_routes.dart';
import 'package:al_sharif/features/auth/data/authService.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key, required this.email});

  final String email;

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  static const Color _teal = Color(0xFF20A6A0);
  static const int _cooldownSeconds = 60;

  final TextEditingController _pinCtrl = TextEditingController();
  final FocusNode _pinFocus = FocusNode();

  bool _loading = false;
  String? _errorKey;
  int _secondsLeft = _cooldownSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
    // تركيز تلقائي على أول خانة بعد بناء الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pinFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinCtrl.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  // ── عدّاد إعادة الإرسال ───────────────────────────────────────
  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _cooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  // ── التحقق من الكود ───────────────────────────────────────────
  Future<void> _verify(String code) async {
    if (_loading || code.trim().length < 6) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _errorKey = null;
    });

    try {
      final res = await AuthService.instance.verifySignupOtp(
        email: widget.email,
        code: code,
      );

      final userId = res.user?.id;
      if (userId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user_id', userId);
      }

      // هل الحساب أدمن؟ (لو فشل الفحص يكمل كمستخدم عادي)
      final isAdmin = await AuthService.instance.isAdmin();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تأكيد حسابك بنجاح'.tr()),
          backgroundColor: Colors.teal,
        ),
      );

      Navigator.of(context).pushNamedAndRemoveUntil(
        isAdmin ? AppRoutes.adminDashboard : AppRoutes.home,
            (route) => false,
        arguments: userId,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorKey = AuthService.errorKey(e));
      _pinCtrl.clear();
      _pinFocus.requestFocus();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── إعادة الإرسال ─────────────────────────────────────────────
  Future<void> _resend() async {
    if (_loading || _secondsLeft > 0) return;

    setState(() {
      _loading = true;
      _errorKey = null;
    });

    try {
      await AuthService.instance.resendSignupOtp(email: widget.email);
      if (!mounted) return;

      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إرسال كود جديد'.tr()),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorKey = AuthService.errorKey(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.locale; // إعادة البناء عند تغيير اللغة

    final baseTheme = PinTheme(
      width: 48,
      height: 58,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Color(0xFF0E1C4C),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF05857F), Color(0xFF0E1C4C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Card(
                elevation: 10,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.teal,
                        child: Icon(
                          Icons.mark_email_read_outlined,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'تأكيد الحساب'.tr(),
                        style: TextStyle(
                          fontSize: 26,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'أرسلنا إليك كودًا من 6 أرقام على بريدك الإلكتروني'
                            .tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          widget.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.teal.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),

                      // الأرقام تُكتب من اليسار لليمين داخل تطبيق RTL
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Pinput(
                          length: 6,
                          controller: _pinCtrl,
                          focusNode: _pinFocus,
                          keyboardType: TextInputType.number,
                          defaultPinTheme: baseTheme,
                          focusedPinTheme: baseTheme.copyDecorationWith(
                            border: Border.all(color: _teal, width: 2),
                          ),
                          errorPinTheme: baseTheme.copyDecorationWith(
                            border: Border.all(color: Colors.red.shade400),
                          ),
                          forceErrorState: _errorKey != null,
                          onCompleted: _verify,
                        ),
                      ),

                      if (_errorKey != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          _errorKey!.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed:
                          _loading ? null : () => _verify(_pinCtrl.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                            Colors.teal.withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
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
                            'تأكيد'.tr(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed:
                        (_secondsLeft == 0 && !_loading) ? _resend : null,
                        child: Text(
                          _secondsLeft > 0
                              ? 'إعادة إرسال الكود بعد {n} ثانية'
                              .tr(namedArgs: {'n': '$_secondsLeft'})
                              : 'إعادة إرسال الكود'.tr(),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      TextButton(
                        onPressed:
                        _loading ? null : () => Navigator.of(context).pop(),
                        child: Text(
                          'هل البريد الإلكتروني خاطئ؟ عدّله'.tr(),
                          style: const TextStyle(
                              fontSize: 14, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}