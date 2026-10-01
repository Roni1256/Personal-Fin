import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personalfin/features/home/screens/home_screen.dart';
import 'package:personalfin/features/planner/screens/plan_review_screen.dart';
import 'package:personalfin/features/calendar/screens/month_calendar_screen.dart';
import 'package:personalfin/features/goals/screens/goals_screen.dart';
import 'package:personalfin/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('PersonalFin HomeScreen renders net worth and widgets cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('NET WORTH'), findsOneWidget);
    expect(find.text('Safe to spend today'), findsOneWidget);
    expect(find.text('Plan vs Spent'), findsOneWidget);
    expect(find.text('Upcoming Dues'), findsOneWidget);
    expect(find.text('Recent Activity'), findsOneWidget);
  });

  testWidgets('PlanReviewScreen displays allocation buckets and approve CTA', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PlanReviewScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Planned Income'), findsOneWidget);
    expect(find.text('Approve & Lock Budget ✓'), findsOneWidget);
  });

  testWidgets('MonthCalendarScreen renders heatmap and schedule list', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MonthCalendarScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Spend Heatmap & Calendar'), findsOneWidget);
    expect(find.text('Month Schedule & Dues'), findsOneWidget);
    expect(find.text('Planned'), findsOneWidget);
    expect(find.text('Spent'), findsOneWidget);
  });

  testWidgets('GoalsScreen renders financial targets and SIP calculation', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const GoalsScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Financial Goals ✦'), findsOneWidget);
    expect(find.text('Total Goals Target'), findsOneWidget);
    expect(find.text('Emergency Fund (6 Months)'), findsOneWidget);
  });
}
