import 'dart:async';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SmartAssistantScreen extends StatefulWidget {
  const SmartAssistantScreen({super.key});

  @override
  State<SmartAssistantScreen> createState() => _SmartAssistantScreenState();
}

class _SmartAssistantScreenState extends State<SmartAssistantScreen> {
  static const Color primaryNavy = Color(0xFF123653);
  static const Color primaryTeal = Color(0xFF20A6A0);

  static const String _apiKey =
      'csk-vf8f3fyfyjdhwjwkm8xxh26w6np6c5tn64jwh8xkhm2nej94';
  static const String _apiUrl = 'https://api.cerebras.ai/v1/chat/completions';
  // Verify this model name exists in your Cerebras account.
  static const String _model = 'qwen-3.8-27b';

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'isWelcome': true,
      'text':
      'مرحباً بك! أنا المساعد الذكي لمراكز الشريف للأطراف الصناعية. كيف يمكنني مساعدتك اليوم؟',
    },
  ];

  final List<String> _quickQuestionsAr = [
    'فين العنوان ومواعيد العمل؟',
    'إيه ميزة الأسعار عندكم؟',
    'إيه الفرق بين الحجز المنزلي والمركز؟',
    'إزاي أختار أفضل طرف مناسب لحالتي؟',
  ];

  final List<String> _quickQuestionsEn = [
    'Where is the center and what are the working hours?',
    'Why are your prices more affordable?',
    'What is the difference between home and center booking?',
    'How do I choose the best prosthetic for my case?',
  ];

  bool _isTyping = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _buildSystemPrompt(bool isEnglish) {
    if (isEnglish) {
      return '''
You are the official smart assistant for Al-Sharif Prosthetics Centers in Egypt.
Respond clearly, empathetically, and practically in English.

Verified Center Knowledge:
- Name: Al-Sharif Prosthetics Centers.
- Key Advantage: The center has its own factory, allowing competitive, direct factory pricing without middlemen.
- Address: Imbaba, Giza, Egypt.
- Google Maps link (Imbaba area): https://www.google.com/maps/search/?api=1&query=Imbaba%2C+Giza%2C+Egypt
- Working Hours: from 10:00 AM to 4:00 PM (working days are not specified; if asked about specific days, advise confirming through support).
- Booking Options: In-center appointment or home visit booking.
- App Features: Approximate price calculator, psychological & rehabilitation support videos, OTP email verification, and direct technical/support channels.

Response Rules:
1. If asked about address, working hours, home booking, or pricing: answer directly and specifically using the verified info above. When asked about the address or location, say the center is in Imbaba and always include the Google Maps link exactly as written, without modifying it.
2. If asked about the "best prosthetic": first ask 2-3 brief clarifying questions (upper or lower limb? activity level? recent or old amputation?), offer a helpful preliminary overview of common options, and guide the user to book an assessment (in-center or at home) instead of giving a vague dismissal.
3. If the user sounds anxious or worried: reassure them warmly and recommend the psychological support videos section in the app.
4. If exact data is missing: state clearly that it is not currently available and direct them to support or booking.
''';
    }

    return '''
أنت المساعد الذكي الرسمي لمراكز الشريف للأطراف الصناعية في مصر.
أجب بوضوح، تعاطف، وأسلوب عملي ومباشر باللغة العربية.

معلومات المركز المعتمدة:
- الاسم: مراكز الشريف للأطراف الصناعية.
- الميزة التنافسية: يمتلك المركز مصنعاً خاصاً، مما يوفر أسعاراً اقتصادية ومباشرة من المصنع مقارنة بالسوق دون وسطاء.
- العنوان: إمبابة، الجيزة، مصر.
- رابط جوجل مابس (منطقة إمبابة): https://www.google.com/maps/search/?api=1&query=%D8%A5%D9%85%D8%A8%D8%A7%D8%A8%D8%A9%2C+%D8%A7%D9%84%D8%AC%D9%8A%D8%B2%D8%A9%2C+%D9%85%D8%B5%D8%B1
- مواعيد العمل: من الساعة 10 صباحاً حتى 4 عصراً (أيام العمل غير محددة؛ إذا سأل المستخدم عن أيام بعينها فانصحه بالتأكيد عبر الدعم الفني).
- أنواع الحجز: حجز موعد داخل المركز، أو حجز زيارة منزلية.
- مميزات التطبيق: حاسبة أسعار تقريبية، فيديوهات دعم نفسي وتأهيل، تحقق من البريد بالـ OTP، وصفحات وأرقام دعم فني.

قواعد الإجابة:
1. إذا سأل المستخدم عن العنوان أو المواعيد أو الحجز المنزلي أو الأسعار: أجب مباشرة وبوضوح من المعلومات المعتمدة أعلاه دون غموض. وعند السؤال عن العنوان أو الموقع: اذكر أن المركز في إمبابة، وأرسل رابط جوجل مابس دائماً كما هو بالضبط دون أي تعديل عليه.
2. إذا سأل عن "أفضل طرف مناسب": اسأله أولاً عن (طرف علوي أم سفلي؟ مستوى النشاط والحركة؟ بتر حديث أم سابق؟)، وقدّم فكرة مبدئية عن الفئات الشائعة، ثم وجّهه لحجز تقييم قياس في المركز أو زيارة منزلية بدلاً من الاكتفاء بعبارة مبهمة.
3. إذا شعر المستخدم بقلق أو توتر: طمئنه بلطف ورشّح له قسم فيديوهات الدعم النفسي داخل التطبيق.
4. إذا لم تتوفر معلومة دقيقة في بياناتك: قل بوضوح إنها غير متوفرة حالياً ووجّهه للدعم الفني أو الحجز للاستفسار المباشر.
''';
  }

  List<Map<String, String>> _buildConversationPayload(String systemPrompt) {
    final List<Map<String, String>> formattedMessages = [
      {'role': 'system', 'content': systemPrompt},
    ];

    // Skip the welcome message and error messages.
    final historySlice = _messages
        .where((m) => m['isWelcome'] != true && m['isError'] != true)
        .toList();
    final recentSlice = historySlice.length > 8
        ? historySlice.sublist(historySlice.length - 8)
        : historySlice;

    for (final msg in recentSlice) {
      formattedMessages.add({
        'role': msg['isUser'] == true ? 'user' : 'assistant',
        'content': (msg['text'] as String).trim(),
      });
    }

    return formattedMessages;
  }

  String _cleanAiText(String raw) {
    // Qwen models may include reasoning inside <think>...</think>.
    return raw
        .replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '')
        .trim();
  }

  void _addAiMessage(String text, {bool isError = false}) {
    setState(() {
      _messages.add({
        'isUser': false,
        'isError': isError,
        'text': text,
      });
    });
    _scrollToBottom();
  }

  Future<void> _callCerebrasAPI() async {
    if (_apiKey.isEmpty) {
      _addAiMessage('خدمة المساعد غير مفعّلة حالياً.'.tr(), isError: true);
      return;
    }

    final isEnglish = context.locale.languageCode == 'en';
    final messagesPayload =
    _buildConversationPayload(_buildSystemPrompt(isEnglish));

    setState(() => _isTyping = true);

    try {
      final response = await http
          .post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messagesPayload,
          'max_completion_tokens': 1024,
          'temperature': 0.2,
          'top_p': 1,
          'stream': false,
        }),
      )
          .timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final rawContent =
            (data['choices'][0]['message']['content'] as String?) ?? '';
        final aiResponse = _cleanAiText(rawContent);

        if (aiResponse.isEmpty) {
          _addAiMessage('لم أتمكن من توليد رد، حاول مرة أخرى.'.tr(),
              isError: true);
        } else {
          _addAiMessage(aiResponse);
        }
      } else {
        debugPrint('Cerebras Error Response: ${response.body}');
        _addAiMessage(
          'عذراً، حدث خطأ من الخادم ({}).'
              .tr(args: [response.statusCode.toString()]),
          isError: true,
        );
      }
    } on TimeoutException {
      if (!mounted) return;
      _addAiMessage('انتهت مهلة الاتصال، حاول مرة أخرى.'.tr(), isError: true);
    } catch (e) {
      debugPrint('Cerebras Exception: $e');
      if (!mounted) return;
      _addAiMessage(
        'تأكد من اتصالك بالإنترنت أو قيود المتصفح (CORS).'.tr(),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isTyping = false);
      }
    }
  }

  void _sendMessage(String text) {
    final cleanText = text.trim();
    if (cleanText.isEmpty || _isTyping) return;

    setState(() {
      _messages.add({
        'isUser': true,
        'text': cleanText,
      });
    });
    _messageController.clear();
    _scrollToBottom();

    _callCerebrasAPI();
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = context.locale.languageCode == 'en';
    final quickQuestions = isEnglish ? _quickQuestionsEn : _quickQuestionsAr;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'المساعد الذكي'.tr(),
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: primaryTeal.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.psychology_outlined, color: primaryTeal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'اسأل المساعد الذكي عن الأطراف الصناعية والتكاليف.'.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) =>
                  _buildMessageBubble(_messages[index]),
            ),
          ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryTeal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'جاري كتابة الرد...'.tr(),
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: quickQuestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final question = quickQuestions[index];
                return ActionChip(
                  label: Text(
                    question,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: _isTyping ? null : () => _sendMessage(question),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: 'اكتب استفسارك هنا...'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        fillColor: cs.surfaceContainerHighest,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: primaryTeal,
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _isTyping
                          ? null
                          : () => _sendMessage(_messageController.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final bool isUser = msg['isUser'] == true;
    final cs = Theme.of(context).colorScheme;

    final String text = msg['isWelcome'] == true
        ? (msg['text'] as String).tr()
        : msg['text'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 18,
              backgroundColor: primaryNavy,
              child: Icon(
                Icons.smart_toy_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isUser ? primaryTeal : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 18),
                ),
              ),
              child: SelectableText(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : cs.onSurface,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}