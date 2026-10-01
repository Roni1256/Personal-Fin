import 'package:intl/intl.dart';

/// INR currency formatter using Indian lakh/crore grouping
class CurrencyFormatter {
  CurrencyFormatter._();

  static final _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final _inrFormatWithDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Format as ₹ 1,23,456
  static String format(double amount, {bool showDecimals = false}) {
    if (showDecimals) {
      return _inrFormatWithDecimals.format(amount);
    }
    return _inrFormat.format(amount);
  }

  /// Format compact: ₹1.2L, ₹4.5Cr
  static String formatCompact(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  /// Format as percentage
  static String formatPercent(double value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  /// Format as +3.2% or -1.5%
  static String formatPercentChange(double value) {
    final sign = value >= 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(1)}%';
  }
}

/// Date formatting helpers
class DateFormatter {
  DateFormatter._();

  static String monthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  static String shortMonthYear(DateTime date) {
    return DateFormat('MMM yyyy').format(date);
  }

  static String dayMonth(DateTime date) {
    return DateFormat('d MMM').format(date);
  }

  static String fullDate(DateTime date) {
    return DateFormat('d MMMM yyyy').format(date);
  }

  static String yearMonth(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return dayMonth(date);
  }
}

