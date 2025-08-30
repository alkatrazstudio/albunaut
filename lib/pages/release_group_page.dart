// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../db/database.dart';
import '../widgets/artist_card.dart';
import '../widgets/id_for_copy.dart';
import '../widgets/listen_stats_card.dart';
import '../widgets/page_loader.dart';
import '../widgets/section_card.dart';

class ReleaseGroupPage extends StatelessWidget {
  const ReleaseGroupPage({
    required this.title,
    required this.releaseGroupId
  });

  final String title;
  final String releaseGroupId;

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: PageLoader(
        future: appDb.getFullReleaseGroup(releaseGroupId).getSingle(),
        builder: (context, page) {
          var mainTypeName = page.type.name;
          var secTypes = page.secondaryTypes.map((t) => t.name).sortedBy((name) => name).join(', ');

          return SingleChildScrollView(
            child: Column(
              children: [
                SectionCard(
                  header: '$mainTypeName${secTypes.isNotEmpty ? (' ($secTypes)') : ''}',
                  child: Column(
                    children: [
                      Text(page.releaseGroup.name, style: Theme.of(context).textTheme.headlineSmall),
                      StreamBuilder(
                        stream: appDb.getReleaseGroup(page.releaseGroup.id).watchSingleOrNull(),
                        builder: (context, snapshot) {
                          if(!snapshot.hasData)
                            return const CircularProgressIndicator();
                          var releaseGroup = snapshot.data;
                          if(releaseGroup == null)
                            return const Text('Load error');
                          var groupIsIgnored = releaseGroup.isIgnored;
                          return StatefulBuilder(builder: (context, setState) {
                            return CheckboxListTile(
                              title: const Text('Ignore'),
                              value: groupIsIgnored,
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (value) {
                                setState(() {
                                  groupIsIgnored = value ?? false;
                                  appDb.setReleaseGroupIsIgnored(groupIsIgnored, releaseGroup.id);
                                });
                              },
                            );
                          });
                        },
                      ),
                      IdForCopy(id: releaseGroupId),
                      TextButton(
                        onPressed: () async {
                          var releaseId = page.releaseGroup.coverReleaseId;
                          if(releaseId.isEmpty) {
                            var release = await appDb.getReleaseByGroup(releaseGroupId).getSingleOrNull();
                            if(release == null) {
                              var url = 'https://musicbrainz.org/release-group/$releaseGroupId';
                              launchUrlString(url, mode: LaunchMode.externalApplication);
                              return;
                            }
                            releaseId = release.id;
                          }
                          var url = 'https://musicbrainz.org/release/$releaseId';
                          launchUrlString(url, mode: LaunchMode.externalApplication);
                        },
                        child: const Text('MusicBrainz')
                      )
                    ],
                  )
                ),
                ListenStatsCard(
                  header: '${page.type.name} listens',
                  releaseGroupStats: page.stats,
                ),
                ArtistCard(artist: page.artist, showLink: true),
                ListenStatsCard(
                  header: 'Artist\'s listens',
                  artistStats: page.artistStats,
                ),
              ],
            )
          );
        },
      )
    );
  }
}
