String timeFormatter(DateTime time, [int minuteInterval = 1]) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = (time.minute - (time.minute % minuteInterval)).toString().padLeft(2, '0');
  final period = time.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

String dateFormatter(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final year = date.year;
  return '$year-$month-$day';
}

String phoneNumberFormatter(String input) {
  String digitsOnly = input.replaceAll(RegExp(r'\D'), '');
  String formatted = '';
  for (int i = 0; i < digitsOnly.length && i < 10; i++) {
    if (i == 0) formatted += '(';
    if (i == 3) formatted += ') ';
    if (i == 6) formatted += '-';
    formatted += digitsOnly[i];
  }
  return formatted;
}
