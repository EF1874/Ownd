import 'package:intl/intl.dart';

class FormatUtils {
  static final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'en_US');

  static String formatCurrency(double value) {
    return _currencyFormat.format(value);
  }
}
