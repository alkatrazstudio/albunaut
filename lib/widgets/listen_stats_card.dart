// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/material.dart';

import 'package:pad5/pad5.dart';

import '../db/database.dart';
import '../util/config.dart';
import '../util/date_util.dart';
import '../widgets/section_card.dart';

class ListenStatsCard extends StatelessWidget {
  const ListenStatsCard({
    required this.header,
    this.artistStats,
    this.releaseGroupStats
  });

  final String header;
  final ArtistStat? artistStats;
  final ReleaseGroupStat? releaseGroupStats;

  @override
  Widget build(context) {
    var listensTotal = artistStats?.listensTotal ?? releaseGroupStats?.listensTotal ?? 0;
    var listensWeek = artistStats?.listensWeek ?? releaseGroupStats?.listensWeek ?? 0;
    var listensMonth = artistStats?.listensMonth ?? releaseGroupStats?.listensMonth ?? 0;
    var listensYear = artistStats?.listensYear ?? releaseGroupStats?.listensYear ?? 0;
    var listenLatest = artistStats?.listenLatest ?? releaseGroupStats?.listenLatest ?? 0;
    var listenFirst = artistStats?.listenFirst ?? releaseGroupStats?.listenFirst ?? 0;

    var statsUpdatedAt = appConfig.showLastUpdateDates && appConfig.statsUpdatedAt != 0
        ? DateUtil.formatDateFromTimestamp(appConfig.statsUpdatedAt)
        : null;

    return SectionCard(
      header: statsUpdatedAt != null ? '$header (as of $statsUpdatedAt)' : header,
      child: listensTotal == 0
        ? const Text('- no stats -')
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'total: '),
                    TextSpan(text: '$listensTotal\n', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'week: '),
                    TextSpan(text: '$listensWeek\n', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'month: '),
                    TextSpan(text: '$listensMonth\n', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'year: '),
                    TextSpan(text: '$listensYear', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]
                )
              ),
              Pad.horizontalSpace,
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'latest:\n'),
                    TextSpan(text: DateUtil.formatDateFromTimestamp(listenLatest), style: const TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: '\nfirst:\n'),
                    TextSpan(text: DateUtil.formatDateFromTimestamp(listenFirst), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]
                )
              )
            ],
          )
    );
  }
}
