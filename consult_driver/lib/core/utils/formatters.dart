import 'package:intl/intl.dart';

final _thousands = NumberFormat('#,##0', 'en_US');

/// Whole-naira amount with thousands separators, e.g. `₦1,500,000`.
String formatNaira(num amount) => '₦${_thousands.format(amount.round())}';

/// Short, readable booking reference: the first block of a UUID, uppercased
/// (`ac20d396-0831-…` → `AC20D396`). Non-UUID ids are returned uppercased.
String shortRef(String id) => id.split('-').first.toUpperCase();
