// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/material.dart';

import 'package:collection/collection.dart';

import '../db/database.dart';
import '../pages/release_group_page.dart';
import '../util/config.dart';
import '../util/date_util.dart';
import '../widgets/artist_card.dart';
import '../widgets/listen_stats_card.dart';
import '../widgets/listened_badge.dart';
import '../widgets/page_loader.dart';
import '../widgets/released_badge.dart';
import '../widgets/section_card.dart';

class ArtistPage extends StatelessWidget {
  const ArtistPage({
    required this.title,
    required this.artistId,
  });

  final String title;
  final String artistId;

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: PageLoader(
        future: appDb.getFullArtist(artistId).getSingle(),
        builder: (context, page) {
          return Column(
            children: [
              ArtistCard(artist: page.artist),
              ListenStatsCard(
                header: 'Listens',
                artistStats: page.stats,
              ),
              Expanded(
                child: SectionCard(
                  header: appConfig.showLastUpdateDates
                    ? 'Albums (as of ${DateUtil.formatDateFromTimestamp(page.artist.lastUpdatedAt)})'
                    : 'Albums',
                  childIsExpanded: true,
                  child: StreamBuilder(
                    stream: appDb.getArtistReleaseGroups(page.artist.id).watch(),
                    builder: (context, snapshot) {
                      if(!snapshot.hasData)
                        return const CircularProgressIndicator();
                      var groups = snapshot.data;
                      if(groups == null)
                        return const Text('Load error.');
                      return ListView.separated(
                        itemBuilder: (context, index) {
                          var group = groups[index];
                          var isIgnored = group.releaseGroup.isIgnored;
                          var typeName = group.releaseGroupType?.name ?? '';
                          var secondaryTypeNames = group.secondaryTypeNames?.split(',').sortedBy((type) => type) ?? [];
                          return ListTile(
                            enabled: !group.releaseGroup.hasHiddenType,
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(group.releaseGroup.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                StatefulBuilder(builder: (context, setState) {
                                  return Switch(
                                    value: !isIgnored,
                                    thumbIcon: WidgetStateProperty.resolveWith((states) => Icon(states.contains(WidgetState.selected) ? Icons.check : Icons.cancel)),
                                    onChanged: (value) {
                                      setState(() {
                                        isIgnored = !value;
                                      });
                                      appDb.setReleaseGroupIsIgnored(!value, group.releaseGroup.id);
                                    },
                                  );
                                })
                              ],
                            ),
                            subtitle: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    ReleasedBadge(group.releaseGroup.date),
                                    if(group.stats?.listenLatest != null)
                                      ListenedBadge(group.stats!.listenLatest)
                                  ],
                                ),
                                Text(
                                  '$typeName${secondaryTypeNames.isNotEmpty ? ' (${secondaryTypeNames.join(', ')})' : ''}',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).hintColor),
                                )
                              ],
                            ),
                            onTap: () {
                              Navigator.push<void>(
                                context,
                                MaterialPageRoute(builder: (context) => ReleaseGroupPage(
                                  title: group.releaseGroup.name,
                                  releaseGroupId: group.releaseGroup.id
                                ))
                              );
                            },
                          );
                        },
                        separatorBuilder: (context, index) => const Divider(),
                        itemCount: groups.length
                      );
                    },
                  )
                )
              )
            ]
          );
        },
      )
    );
  }
}
