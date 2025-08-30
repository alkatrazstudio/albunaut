// SPDX-License-Identifier: AGPL-3.0-only

import 'package:intl/intl.dart';

final _dateDisplayFormat = DateFormat.yMMMd();
final _timeDisplayFormat = DateFormat.jm();

abstract final class DateUtil {
  static String formatDate(DateTime dt) => _dateDisplayFormat.format(dt);
  static String formatTime(DateTime dt) => _timeDisplayFormat.format(dt);
  static String formatDateFromTimestamp(int secs) => formatDate(DateTime.fromMillisecondsSinceEpoch(secs * 1000));
  static String formatTimeFromTimestamp(int secs) => formatTime(DateTime.fromMillisecondsSinceEpoch(secs * 1000));
}
