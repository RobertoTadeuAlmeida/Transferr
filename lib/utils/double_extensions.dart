import 'package:intl/intl.dart';

extension DoubleExtensions on double {
  String toCurrency() {
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return formatter.format(this);
  }
}
