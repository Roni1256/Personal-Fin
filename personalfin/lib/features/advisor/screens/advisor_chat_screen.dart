import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/fin_orb.dart';

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
      content:
          'Hi Roni! I’m Fin, your personal AI financial advisor. I’m grounded in your ₹60,000 October plan, your 78/100 health score, and your Moderate risk profile.\n\nAsk me anything like "Can I afford a ₹60k laptop?", "Should I prepay my home loan?", or "Explain my SIP allocation".',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  static const List<String> _quickChips = [
    'Can I afford a ₹60,000 phone?',
    'Should I prepay home loan or SIP?',
    'How do I reach 6 months emergency fund?',
    'Explain my investment split',
  ];

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

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

    // AI Response simulation grounded in user's profile and plan
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;

      String reply = '';
      String? assumption;

      if (text.toLowerCase().contains('phone') || text.toLowerCase().contains('laptop') || text.toLowerCase().contains('afford')) {
        reply =
            '✦ Affordability Assessment:\n\nBuying a ₹60,000 phone with your monthly income of ₹60,000 requires careful planning. If bought outright, it consumes 100% of one month’s salary and would deplete 65% of your current liquid reserve (₹92k).\n\nRecommendation:\n1. If taking a 6-month No-Cost EMI (₹10,000/mo), your fixed obligations will rise to ₹24,000, bringing your DTI ratio to 40% (exceeding the 35% safe ceiling).\n2. Instead, allocate ₹5,000/month into a short-term Goal over the next 12 months, or wait until your Emergency Fund reaches 4 months.';
        assumption = 'Assumes no other bonus income; preserves your ₹6,000/mo emergency fund allocation.';
      } else if (text.toLowerCase().contains('prepay') || text.toLowerCase().contains('loan')) {
        reply =
            '✦ Prepay vs Invest Analysis:\n\nYour Home Loan interest rate is approximately 8.65% (tax-deductible under Sec 24b). With a Moderate risk profile, your diversified equity index SIPs target a long-term CAGR of ~11-12%.\n\nMathematical Trade-Off:\n• Over a 10-year horizon, continuing your ₹5,000/mo SIP typically creates a higher net terminal corpus compared to early prepayment.\n• However, if peace of mind from zero debt is your priority, allocating 50% of any annual bonuses towards principal prepayment is the optimal hybrid strategy.';
        assumption = 'Home loan rate: 8.65% p.a. | Expected Nifty index CAGR: 12% (non-guaranteed).';
      } else {
        reply =
            '✦ Analysis based on your profile:\n\nBased on your ₹60,000 monthly cash flow and Family Balanced plan, your essentials take 36.7%, loan EMI takes 23.3%, and you have an impressive 35% savings rate.\n\nYour top priority this quarter remains building your emergency fund from 2.8 months to the 6.0 months benchmark (₹1,32,000 target). All investments are mapped to SEBI asset-allocation principles.';
        assumption = 'Based on October 2026 active plan version 1.0.';
      }

      setState(() {
        _isFinThinking = false;
        _messages.add(
          ChatMessageItem(
            id: 'f_${DateTime.now().millisecondsSinceEpoch}',
            role: 'fin',
            content: reply,
            timestamp: DateTime.now(),
            assumption: assumption,
          ),
        );
      });
      _scrollToBottom();
    });
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
                'PersonalFin provides educational financial planning. Does not guarantee returns. Consult a SEBI-registered advisor for execution.',
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
