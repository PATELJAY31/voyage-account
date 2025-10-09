import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _inrFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static String formatINR(double amount) {
    return _inrFormatter.format(amount);
  }

  static String formatCurrency(double amount, {String symbol = '₹'}) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: symbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  static String formatNumber(double number) {
    final formatter = NumberFormat('#,##0.00', 'en_IN');
    return formatter.format(number);
  }

  static double parseAmount(String amountString) {
    // Remove currency symbols and commas
    final cleanString = amountString
        .replaceAll('₹', '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();
    
    return double.tryParse(cleanString) ?? 0.0;
  }

  static String formatCompact(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return formatINR(amount);
    }
  }
}
