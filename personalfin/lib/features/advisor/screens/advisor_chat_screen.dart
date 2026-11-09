import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/fin_orb.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';

class ChatMessageItem {
  final String id;
  final String role; // 'user' or 'fin'
  final String content;
  final DateTime timestamp;
  final String? assumption;

  const ChatMessageItem({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.assumption,
  });
}

class AdvisorChatScreen extends ConsumerStatefulWidget {
  const AdvisorChatScreen({super.key});

  @override
  ConsumerState<AdvisorChatScreen> createState() => _AdvisorChatScreenState();
}

class _AdvisorChatScreenState extends ConsumerState<AdvisorChatScreen> {
  final _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isFinThinking = false;

  final List<ChatMessageItem> _messages = [
    ChatMessageItem(
      id: 'm1',
      role: 'fin',
      content: 'Hi, I’m Fin. Ask me a question about budgeting, saving, or your financial plan.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  static const List<String> _quickChips = [
    'Can I afford a ₹60,000 phone?',
    'Should I prepay home loan or SIP?',
    'How do I reach 6 months emergency fund?',
    'Explain my investment split',
  ];

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isFinThinking) return;

    final userMsg = ChatMessageItem(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isFinThinking = true;
    });
    _textController.clear();
    _scrollToBottom();

    String reply;
    try {
      final accessToken = ref.read(authProvider).accessToken;
      if (accessToken == null || accessToken.isEmpty) {
        throw StateError('Sign in to use Fin AI.');
      }
      final result = await ref.read(apiServiceProvider).sendAdvisorMessage(
        accessToken: accessToken,
        messages: _messages.map((message) => {
          'role': message.role == 'user' ? 'user' : 'model',
          'content': message.content,
        }).toList().reversed.take(20).toList().reversed.toList(),
      );
      reply = result['reply'] as String? ?? 'Fin returned an empty response. Please try again.';
    } catch (error) {
      if (error is DioException) {
        final responseData = error.response?.data;
        if (responseData is Map && responseData['detail'] is String) {
          reply = responseData['detail'] as String;
        } else {
          reply = 'Fin could not connect to Gemini. Check your connection and try again.';
        }
      } else if (error is StateError) {
        reply = error.message;
      } else {
        reply = 'Fin could not respond right now. Please try again.';
      }
    }

    if (!mounted) return;
    setState(() {
      _isFinThinking = false;
      _messages.add(ChatMessageItem(
        id: 'f_${DateTime.now().millisecondsSinceEpoch}',
        role: 'fin',
        content: reply,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            FinOrb(size: 30, isThinking: _isFinThinking),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fin AI Advisor ✦', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  'Grounded in your financial profile',
                  style: TextStyle(fontSize: 11, color: AppColors.slate),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Disclaimer Banner (Compliance requirement)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: isDark ? AppColors.darkCard : AppColors.violet100,
              child: const Text(
                'Chat context is processed by Google Gemini. For educational planning only; returns are not guaranteed. Consult a SEBI-registered advisor for execution.',
                style: TextStyle(fontSize: 10, color: AppColors.slate, height: 1.2),
                textAlign: TextAlign.center,
              ),
            ),

            // Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isFin = msg.role == 'fin';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: isFin ? MainAxisAlignment.start : MainAxisAlignment.end,
                      children: [
                        if (isFin) ...[
                          const FinOrb(size: 28),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isFin
                                  ? (isDark ? AppColors.darkCard : AppColors.white)
                                  : AppColors.violet600,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(20),
                                topRight: const Radius.circular(20),
                                bottomLeft: Radius.circular(isFin ? 4 : 20),
                                bottomRight: Radius.circular(isFin ? 20 : 4),
                              ),
                              border: isFin
                                  ? Border.all(color: isDark ? AppColors.darkBorder : AppColors.violet200)
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.content,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.45,
                                    color: isFin
                                        ? (isDark ? AppColors.darkText : AppColors.ink)
                                        : Colors.white,
                                  ),
                                ),
                                if (msg.assumption != null) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.black26 : AppColors.violet50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Assumptions: ${msg.assumption}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.slate),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            if (_isFinThinking)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: const [
                    FinOrb(size: 20, isThinking: true),
                    SizedBox(width: 10),
                    Text(
                      'Fin is computing affordability & SEBI guidelines...',
                      style: TextStyle(fontSize: 12, color: AppColors.slate),
                    ),
                  ],
                ),
              ),

            // Quick suggestion chips
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _quickChips.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ActionChip(
                    label: Text(_quickChips[index], style: const TextStyle(fontSize: 12)),
                    onPressed: () => _sendMessage(_quickChips[index]),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Ask Fin about your money...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppColors.violet600),
                    onPressed: () => _sendMessage(_textController.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
