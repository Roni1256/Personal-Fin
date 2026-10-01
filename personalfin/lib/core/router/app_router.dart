import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/onboarding/screens/health_score_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/planner/screens/new_month_screen.dart';
import '../../features/planner/screens/plan_review_screen.dart';
import '../../features/calendar/screens/month_calendar_screen.dart';
import '../../features/expenses/screens/add_expense_screen.dart';
import '../../features/expenses/screens/expenses_list_screen.dart';
import '../../features/expenses/screens/budget_tracker_screen.dart';
import '../../features/goals/screens/goals_screen.dart';
import '../../features/goals/screens/add_goal_screen.dart';
import '../../features/advisor/screens/advisor_chat_screen.dart';
import '../../features/insights/screens/insights_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../widgets/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      // ── Pre-auth routes ──
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return OtpScreen(phoneNumber: phone);
        },
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/health-score',
        builder: (context, state) => const HealthScoreScreen(),
      ),

      // ── Main app with bottom nav shell ──
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/planner',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NewMonthScreen(),
            ),
            routes: [
              GoRoute(
                path: 'review',
                builder: (context, state) => const PlanReviewScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/calendar',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MonthCalendarScreen(),
            ),
          ),
          GoRoute(
            path: '/advisor',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AdvisorChatScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),

      // ── Standalone routes (outside shell) ──
      GoRoute(
        path: '/add-expense',
        builder: (context, state) => const AddExpenseScreen(),
      ),
      GoRoute(
        path: '/expenses',
        builder: (context, state) => const ExpensesListScreen(),
      ),
      GoRoute(
        path: '/budget-tracker',
        builder: (context, state) => const BudgetTrackerScreen(),
      ),
      GoRoute(
        path: '/goals',
        builder: (context, state) => const GoalsScreen(),
      ),
      GoRoute(
        path: '/add-goal',
        builder: (context, state) => const AddGoalScreen(),
      ),
      GoRoute(
        path: '/insights',
        builder: (context, state) => const InsightsScreen(),
      ),
    ],
  );
});

