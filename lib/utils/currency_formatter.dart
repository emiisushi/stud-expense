import 'package:intl/intl.dart';

final NumberFormat phpCurrencyFormatter = NumberFormat.currency(
  locale: 'en_PH',
  symbol: '₱',
  decimalDigits: 2,
);
