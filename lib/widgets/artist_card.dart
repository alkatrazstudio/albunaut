// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../db/database.dart';
import '../pages/artist_page.dart';
import '../util/manager.dart';
import '../widgets/id_for_copy.dart';
import '../widgets/section_card.dart';

class ArtistCard extends StatelessWidget {
  const ArtistCard({
    required this.artist,
    this.showLink = false
  });

  final Artist artist;
  final bool showLink;

  @override
  Widget build(context) {
    return SectionCard(
      header: 'Artist',
      child: Column(
        children: [
          Text(artist.name, style: Theme.of(context).textTheme.headlineSmall),
          StreamBuilder(
            stream: appDb.getArtist(artist.id).watchSingleOrNull(),
            builder: (context, snapshot) {
              if(!snapshot.hasData)
                return const CircularProgressIndicator();
              var artist = snapshot.data;
              if(artist == null)
                return const Text('Load error.');
              var artistFilterList = FilterList.values.firstWhereOrNull((v) => v.abbr == artist.filterListAbbr) ?? FilterList.none;
              return StatefulBuilder(builder: (context, setState) {
                return SegmentedButton(
                  segments: const [
                    ButtonSegment(value: FilterList.none, label: Text('not in list')),
                    ButtonSegment(value: FilterList.whitelist, label: Text('whitelist')),
                    ButtonSegment(value: FilterList.blacklist, label: Text('blacklist')),
                  ],
                  selected: {artistFilterList},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      artistFilterList = newSelection.first;
                      appDb.setArtistFilterList(artistFilterList.abbr, artist.id);
                    });
                  },
                  showSelectedIcon: false,
                );
              });
            },
          ),
          IdForCopy(id: artist.id),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if(showLink)
                TextButton(
                  onPressed: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute(builder: (context) => ArtistPage(title: artist.name, artistId: artist.id))
                    );
                  },
                  child: const Text('details')
                ),

              TextButton(
                onPressed: () {
                  var url = 'https://musicbrainz.org/artist/${artist.id}';
                  launchUrlString(url, mode: LaunchMode.externalApplication);
                },
                child: const Text('MusicBrainz'),
              ),
            ],
          )
        ],
      )
    );
  }
}
