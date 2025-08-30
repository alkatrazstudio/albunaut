// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/material.dart';

import 'package:pad5/pad5.dart';

import '../util/date_util.dart';

class ListenedBadge extends StatelessWidget {
  const ListenedBadge(this.listenedAt);

  final int listenedAt;

  @override
  Widget build(context) {
    if(listenedAt == 0)
      return const SizedBox.shrink();
    return Row(
      children: [
        const Icon(Icons.music_note, size: 16),
        Pad.horizontalSpace,
        Text(
          DateUtil.formatDateFromTimestamp(listenedAt),
          style: Theme.of(context).textTheme.labelSmall
        )
      ]
    );
  }
}
