// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/material.dart';

import 'package:pad5/pad5.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../db/database.dart';
import '../pages/artist_page.dart';
import '../pages/release_group_page.dart';
import '../util/date_util.dart';

class ListensList extends StatelessWidget {
  const ListensList({
    required this.items,
    required this.loadMoreBuilder
  });

  final List<GetListensResult> items;
  final FutureBuilder? loadMoreBuilder;

  @override
  Widget build(context) {
    return ListView.separated(
      itemBuilder: (context, index) {
        if(index >= items.length)
          return loadMoreBuilder;
        var item = items[index];
        return ListTile(
          title: Text(
            item.recording?.name ?? item.listen.trackName ?? 'N/A',
            style: Theme.of(context).textTheme.titleLarge
          ).padBottom * 3,
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Pad.pad,
                children: [
                  const Icon(Icons.person),
                  Expanded(
                    child: Text(
                      item.artist?.name ?? item.listen.artistName ?? 'N/A',
                      style: Theme.of(context).textTheme.titleMedium
                    )
                  )
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Pad.pad,
                children: [
                  const Icon(Icons.album),
                  Expanded(
                    child: Text(
                      item.releaseGroup?.name ?? item.listen.releaseName ?? 'N/A',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  )
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Pad.pad,
                children: [
                  const Icon(Icons.calendar_month),
                  Expanded(
                    child: Text(
                      DateUtil.formatDateFromTimestamp(item.listen.listenedAt),
                      style: TextStyle(
                        color: Theme.of(context).dividerColor
                      )
                    ),
                  )
                ],
              )
            ],
          ),
          trailing: MenuAnchor(
            menuChildren: [
              MenuItemButton(
                onPressed: item.artist == null ? null : () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute(builder: (context) => ArtistPage(title: item.artist!.name, artistId: item.artist!.id))
                  );
                },
                leadingIcon: const Icon(Icons.person),
                child: const Text('Artist'),
              ),
              MenuItemButton(
                onPressed: item.releaseGroup == null ? null : () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute(builder: (context) => ReleaseGroupPage(title: item.releaseGroup!.name, releaseGroupId: item.releaseGroup!.id))
                  );
                },
                leadingIcon: const Icon(Icons.album),
                child: const Text('Album'),
              ),
              MenuItemButton(
                onPressed: item.recording == null ? null : () {
                  var url = 'https://musicbrainz.org/recording/${item.recording!.id}';
                  launchUrlString(url, mode: LaunchMode.externalApplication);
                },
                leadingIcon: const Icon(Icons.open_in_browser),
                child: const Text('MusicBrainz'),
              ),
            ],
            builder: (context, controller, child) {
              return IconButton(
                onPressed: () {
                  if (controller.isOpen)
                    controller.close();
                  else
                    controller.open();
                },
                icon: const Icon(Icons.more_vert),
              );
            },
          ),
        );
      },
      separatorBuilder: (context, index) {
        return const Divider();
      },
      itemCount: items.length + (loadMoreBuilder != null ? 1 : 0),
    );
  }
}
