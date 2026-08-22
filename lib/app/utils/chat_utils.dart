import 'package:intl/intl.dart';

DateTime? parseIsoDate(String? isoString) {
  if (isoString == null) return null;
  try {
    return DateTime.parse(isoString);
  } catch (e) {
    return null;
  }
}

String formatTime(DateTime? time) {
  if (time == null) return '';
  final now = DateTime.now();
  final isToday =
      now.day == time.day && now.month == time.month && now.year == time.year;

  if (isToday) {
    return DateFormat.jm().format(time);
  } else {
    return DateFormat('dd/MM/yyyy, h:mm a').format(time);
  }
}
