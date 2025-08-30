// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:pad5/pad5.dart';

import '../util/date_util.dart';

class ReleasedBadge extends StatelessWidget {
  const ReleasedBadge(this.date);

  final String date;

  static final releasedAtFormat = DateFormat('yyyy-MM-dd');

  @override
  Widget build(context) {
    var releasedAt = releasedAtFormat.tryParse(date);
    if(releasedAt == null)
      return const SizedBox.shrink();
    return Row(
      children: [
        const Icon(Icons.new_releases, size: 16),
        Pad.horizontalSpace,
        Text(
          DateUtil.formatDate(releasedAt),
          style: Theme.of(context).textTheme.labelSmall
        )
      ]
    );
  }
}
