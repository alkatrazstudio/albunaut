// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/material.dart';

import '../db/database.dart';
import '../util/filter.dart';

class CurrentFilterWidget extends StatelessWidget {
  const CurrentFilterWidget({
    required this.filter,
    required this.onChanged
  });

  final FilterPreset filter;
  final void Function(FilterPreset newFilter) onChanged;

  @override
  Widget build(context) {
    return Column(
      children: [
        SegmentedButton(
          segments: const [
            ButtonSegment(value: ListenedCriteria.all, label: Text('all')),
            ButtonSegment(value: ListenedCriteria.listened, label: Text('listened')),
            ButtonSegment(value: ListenedCriteria.notListened, label: Text('not listened')),
          ],
          selected: {filter.listenedCriteria},
          onSelectionChanged: (newSelection) {
            onChanged(filter.copyWith(listenedCriteria: newSelection.first));
          },
          showSelectedIcon: false,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            SegmentedButton(
              segments: const [
                ButtonSegment(value: EntryType.releaseGroup, label: Text('albums')),
                ButtonSegment(value: EntryType.artist, label: Text('artists')),
              ],
              selected: {filter.entryType},
              onSelectionChanged: (newSelection) {
                onChanged(filter.copyWith(entryType: newSelection.first));
              },
              showSelectedIcon: false,
            ),
            DropdownButton(
              value: filter.artistListFilter,
              onChanged: (value) {
                onChanged(filter.copyWith(artistListFilter: value ?? ArtistListFilter.none));
              },
              items: const [
                DropdownMenuItem(value: ArtistListFilter.none, child: Text('any artist')),
                DropdownMenuItem(value: ArtistListFilter.inWhitelist, child: Text('whitelisted')),
                DropdownMenuItem(value: ArtistListFilter.inBlacklist, child: Text('blacklisted')),
                DropdownMenuItem(value: ArtistListFilter.notInWhitelist, child: Text('not whitelisted')),
                DropdownMenuItem(value: ArtistListFilter.notInBlacklist, child: Text('not blacklisted')),
                DropdownMenuItem(value: ArtistListFilter.inList, child: Text('in any list')),
                DropdownMenuItem(value: ArtistListFilter.notInList, child: Text('not in any list')),
              ],
            )
          ]
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            SegmentedButton(
              segments: const [
                ButtonSegment(value: true, label: Text('asc')),
                ButtonSegment(value: false, label: Text('desc')),
              ],
              selected: {filter.isAscending},
              onSelectionChanged: (newSelection) {
                onChanged(filter.copyWith(isAscending: newSelection.first));
              },
              showSelectedIcon: false,
            ),
            const Text('by'),
            DropdownButton(
              value: filter.listSortParam,
              onChanged: (value) {
                onChanged(filter.copyWith(listSortParam: value ?? ListSortParam.releaseDate));
              },
              items: const [
                DropdownMenuItem(value: ListSortParam.name, child: Text('name')),
                DropdownMenuItem(value: ListSortParam.releaseDate, child: Text('album date')),
                DropdownMenuItem(value: ListSortParam.latestListenDate, child: Text('listen date')),
                DropdownMenuItem(value: ListSortParam.listensTotal, child: Text('total listens')),
                DropdownMenuItem(value: ListSortParam.listensWeek, child: Text('weekly listens')),
                DropdownMenuItem(value: ListSortParam.listensMonth, child: Text('monthly listens')),
                DropdownMenuItem(value: ListSortParam.listensYear, child: Text('yearly listens')),
              ],
            )
          ],
        ),
        SegmentedButton(
          segments: const [
            ButtonSegment(value: IgnoredInclusion.include, label: Text('with ignored')),
            ButtonSegment(value: IgnoredInclusion.exclude, label: Text('no ignored')),
            ButtonSegment(value: IgnoredInclusion.includeOnly, label: Text('only ignored')),
          ],
          selected: {filter.ignoredInclusion},
          onSelectionChanged: (newSelection) {
            onChanged(filter.copyWith(ignoredInclusion: newSelection.first));
          },
          showSelectedIcon: false,
        ),
      ],
    );
  }
}
