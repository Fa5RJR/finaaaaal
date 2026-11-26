import 'package:supabase_flutter/supabase_flutter.dart';

/// الشاشات لا تتحدث مع Supabase مباشرة، بل تستدعي [AuthService.instance].
/// الدوال ترجع **مفاتيح ترجمة** (النص العربي نفسه) وليست رسائل جاهزة،
/// حتى تتولى الشاشة استدعاء `.tr()` وتظهر الرسالة باللغة الحالية.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  SupabaseClient get _auth => Supabase.instance.client;

  User? get currentUser => _auth.auth.currentUser;

  Session? get currentSession => _auth.auth.currentSession;

  // إنشاء الحساب
  //    Supabase تبعت كود من 6 أرقام على البريد (لو Confirm email مفعّل).
  //    في هذه الحالة res.session تبقى null — وده سلوك طبيعي مش خطأ.
  //    ترجع AuthResponse عشان الشاشة تعتمد على res.session
  //    (سيشن الحساب الجديد فقط) مش على currentSession.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
  }) async {
    // امسح أي سيشن قديمة (مثلاً أدمن) قبل إنشاء حساب جديد
    if (_auth.auth.currentSession != null) {
      await _auth.auth.signOut(scope: SignOutScope.local);
    }

    final res = await _auth.auth.signUp(
      email: email.trim(),
      password: password,
      // بيانات إضافية يستهلكها trigger في قاعدة البيانات لإنشاء صف المستخدم.
      // لا تحذف هذه الخريطة.
      data: {
        'name': name.trim(),
        'phone': phone.trim(),
        'address': address.trim(),
      },
    );

    final user = res.user;
    if (user == null) {
      throw const AuthException('تعذّر إنشاء الحساب، حاول مرة أخرى');
    }

    // Supabase لا ترجع خطأ لو البريد مستخدم (حماية من تسريب البيانات)،
    // لكن ترجع قائمة identities فارغة.
    if (user.identities != null && user.identities!.isEmpty) {
      throw const AuthException('هذا البريد الإلكتروني مسجل بالفعل');
    }

    return res;
  }

  //  التحقق من الكود — يرجع جلسة، أي أن المستخدم صار مسجلًا للدخول.
  Future<AuthResponse> verifySignupOtp({
    required String email,
    required String code,
  }) async {
    final cleanCode = code.trim();
    if (cleanCode.length < 6) {
      throw const AuthException('من فضلك أدخل الكود كاملاً');
    }

    final res = await _auth.auth.verifyOTP(
      type: OtpType.signup,
      email: email.trim(),
      token: cleanCode,
    );

    if (res.session == null) {
      throw const AuthException('الكود غير صحيح أو انتهت صلاحيته');
    }
    return res;
  }

  //  إعادة إرسال الكود
  Future<void> resendSignupOtp({required String email}) async {
    await _auth.auth.resend(type: OtpType.signup, email: email.trim());
  }

  //  تسجيل الدخول والخروج

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _auth.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _auth.auth.signOut();

  // هل المستخدم الحالي أدمن؟ (rpc is_admin في Supabase)
  //    لو فشل الفحص لأي سبب نعتبره مستخدم عادي.
  Future<bool> isAdmin() async {
    try {
      return (await _auth.rpc('is_admin')) == true;
    } catch (_) {
      return false;
    }
  }

  // تحويل أي خطأ إلى مفتاح ترجمة عربي (غير مترجم)
  static String errorKey(Object e) {
    const fallback = 'حدث خطأ، حاول مرة أخرى';
    if (e is! AuthException) return fallback;

    final msg = e.message.toLowerCase();
    final code = (e.code ?? '').toLowerCase();

    if (e.statusCode == '429' ||
        code.contains('rate_limit') ||
        msg.contains('rate limit') ||
        code.contains('over_email_send')) {
      return 'لقد أرسلت طلبات كثيرة، انتظر دقيقة ثم حاول مرة أخرى';
    }
    if (code.contains('email_address_not_authorized')) {
      return 'إعدادات البريد الإلكتروني غير صحيحة، تواصل مع الدعم';
    }
    // لازم يبقى قبل شرط invalid العام
    if (msg.contains('invalid login credentials')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    }
    if (msg.contains('expired') || msg.contains('invalid')) {
      return 'الكود غير صحيح أو انتهت صلاحيته';
    }
    if (msg.contains('already registered') || msg.contains('already exists')) {
      return 'هذا البريد الإلكتروني مسجل بالفعل';
    }
    if (msg.contains('email not confirmed')) {
      return 'من فضلك أكد بريدك الإلكتروني أولاً';
    }
    if (msg.contains('weak')) {
      return 'كلمة المرور ضعيفة، استخدم كلمة مرور أقوى';
    }
    return fallback;
  }
}