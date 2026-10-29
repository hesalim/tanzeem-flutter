class CurrencyFormatter {
  static String usd(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }
}
