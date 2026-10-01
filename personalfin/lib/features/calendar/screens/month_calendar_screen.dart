import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/providers/finance_provider.dart';
import '../../../core/models/app_models.dart';

class MonthCalendarScreen extends ConsumerStatefulWidget {
  const MonthCalendarScreen({super.key});

  @override
  ConsumerState<MonthCalendarScreen> createState() => _MonthCalendarScreenState();
}

class _MonthCalendarScreenState extends ConsumerState<MonthCalendarScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(monthlyPlanProvider);
    final txns = ref.watch(transactionsProvider);
    final events = ref.watch(calendarEventsProvider);
    final totalSpent = ref.watch(totalSpentProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final remaining = (plan.totalIncome - totalSpent).clamp(0.0, double.infinity);
    final daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    final firstWeekday = DateTime(_selectedDate.year, _selectedDate.month, 1).weekday % 7; // Sunday = 0

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spend Heatmap & Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/add-expense'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Month Navigation Header ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () {
                      setState(() {
                        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
                      });
                    },
                  ),
                  Text(
                    DateFormatter.monthYear(_selectedDate),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () {
                      setState(() {
                        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ── Planned vs Spent Summary Bar ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.violet200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('Planned', CurrencyFormatter.format(plan.totalIncome), AppColors.ink),
                    _buildSummaryItem('Spent', CurrencyFormatter.format(totalSpent), AppColors.danger),
                    _buildSummaryItem('Remaining', CurrencyFormatter.format(remaining), AppColors.success),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Calendar Heatmap Grid ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.violet200),
                ),
                child: Column(
                  children: [
                    // Day of week headers
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: const ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
                        return SizedBox(
                          width: 36,
                          child: Center(
                            child: Text(
                              day,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),

                    // Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 42, // 6 weeks * 7 days
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemBuilder: (context, index) {
                        final dayNumber = index - firstWeekday + 1;
                        if (dayNumber < 1 || dayNumber > daysInMonth) {
                          return const SizedBox();
                        }

                        // Determine daily spend
                        final dayTxns = txns.where((t) => t.date.day == dayNumber && t.type == 'expense').toList();
                        final daySpend = dayTxns.fold<double>(0.0, (sum, t) => sum + t.amount);

                        // Heatmap color level (0 - 4)
                        Color cellColor = isDark ? const Color(0xFF1E1436) : AppColors.violet50;
                        if (daySpend > 5000) {
                          cellColor = AppColors.heatmapLevels[4];
                        } else if (daySpend > 2000) {
                          cellColor = AppColors.heatmapLevels[3];
                        } else if (daySpend > 800) {
                          cellColor = AppColors.heatmapLevels[2];
                        } else if (daySpend > 0) {
                          cellColor = AppColors.heatmapLevels[1];
                        }

                        // Has event marker
                        final hasEvent = events.any((e) => e.date.day == dayNumber);

                        final isToday = dayNumber == DateTime.now().day &&
                            _selectedDate.month == DateTime.now().month &&
                            _selectedDate.year == DateTime.now().year;

                        return GestureDetector(
                          onTap: () => _showDayDetail(context, dayNumber, dayTxns, events.where((e) => e.date.day == dayNumber).toList()),
                          child: Container(
                            decoration: BoxDecoration(
                              color: cellColor,
                              borderRadius: BorderRadius.circular(10),
                              border: isToday
                                  ? Border.all(color: AppColors.violet600, width: 2)
                                  : null,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  '$dayNumber',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                                    color: (daySpend > 2000)
                                        ? Colors.white
                                        : (isDark ? AppColors.darkText : AppColors.ink),
                                  ),
                                ),
                                if (hasEvent)
                                  Positioned(
                                    bottom: 4,
                                    child: Container(
                                      width: 4,
                                      height: 4,
                                      decoration: const BoxDecoration(
                                        color: AppColors.warning,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Heatmap Legend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Less spend', style: TextStyle(fontSize: 10, color: AppColors.slate)),
                        const SizedBox(width: 6),
                        ...AppColors.heatmapLevels.map(
                          (c) => Container(
                            width: 14,
                            height: 14,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('Heavy spend', style: TextStyle(fontSize: 10, color: AppColors.slate)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Upcoming Events List ──
              const Text(
                'Month Schedule & Dues',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...events.map((e) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.violet100,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _eventColor(e.type).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_eventIcon(e.type), color: _eventColor(e.type), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(
                              '${DateFormatter.dayMonth(e.date)} · ${e.type.toUpperCase()}',
                              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(e.amount),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showDayDetail(
    BuildContext context,
    int day,
    List<TransactionModel> dayTxns,
    List<CalendarEventItem> dayEvents,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Activity for $day October 2026',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (dayTxns.isEmpty && dayEvents.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('No transactions or dues recorded on this day.'),
                    ),
                  )
                else ...[
                  ...dayEvents.map(
                    (e) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(_eventIcon(e.type), color: _eventColor(e.type)),
                      title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(e.type.toUpperCase()),
                      trailing: Text(CurrencyFormatter.format(e.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  ...dayTxns.map(
                    (t) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.receipt_rounded, color: AppColors.violet600),
                      title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(t.paymentMode),
                      trailing: Text('-${CurrencyFormatter.format(t.amount)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger)),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/add-expense');
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Expense for this Day'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.slate)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  IconData _eventIcon(String type) {
    switch (type) {
      case 'emi':
        return Icons.account_balance_rounded;
      case 'sip':
        return Icons.trending_up_rounded;
      case 'bill':
        return Icons.receipt_long_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  Color _eventColor(String type) {
    switch (type) {
      case 'emi':
        return AppColors.danger;
      case 'sip':
        return AppColors.success;
      case 'bill':
        return AppColors.warning;
      default:
        return AppColors.violet600;
    }
  }
}
