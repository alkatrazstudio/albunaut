// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:drift/drift.dart' hide Column;

import '../db/database.dart';
import '../pages/artist_page.dart';
import '../pages/release_group_page.dart';
import '../util/config.dart';
import '../util/filter.dart';
import '../util/manager.dart';
import '../widgets/current_filter_widget.dart';
import '../widgets/dismiss_background.dart';
import '../widgets/filter_presets_selector.dart';
import '../widgets/listened_badge.dart';
import '../widgets/released_badge.dart';

class AlbumsListController {
  void setSearch(String search) {
    _onSearchSet?.call(search);
  }

  void reload() {
    _onReload?.call();
  }

  void Function(String)? _onSearchSet;
  void Function()? _onReload;
}

class AlbumsList extends StatefulWidget {
  const AlbumsList({
    required this.controller
  });

  final AlbumsListController controller;

  @override
  State<AlbumsList> createState() => _AlbumsListState();
}

class _AlbumsListState extends State<AlbumsList> {
  static const pageSize = 100;

  final results = <dynamic>[];
  bool canLoadMore = true;
  Future<List<dynamic>>? future;
  var controller = ScrollController();
  FilterPreset filter = DbDefaults.filterPreset().copyWith(id: -1);
  var detailsShown = ValueNotifier(false);
  var search = '';

  void loadMore(bool firstPage) async {
    if(filter.id == -1) // TODO: HACK
      return;
    var newFuture = switch(filter.entryType) {
      EntryType.releaseGroup => fetchAlbums(pageSize, firstPage ? 0 : results.length),
      EntryType.artist => fetchArtists(pageSize, firstPage ? 0 : results.length),
    };
    setState(() {
      future = newFuture;
    });
    newFuture.then((newResults) {
      setState(() {
        if(future != newFuture)
          return;
        if(firstPage)
          results.clear();
        results.addAll(newResults);
        canLoadMore = newResults.length == pageSize;
      });
    });
  }

  void reload() {
    var newFuture = switch(filter.entryType) {
      EntryType.releaseGroup => fetchAlbums(results.length, 0),
      EntryType.artist => fetchArtists(results.length, 0),
    };
    setState(() {
      future = newFuture;
    });
    newFuture.then((newResults) {
      setState(() {
        if(future != newFuture)
          return;
        results.clear();
        results.addAll(newResults);
        canLoadMore = newResults.length == pageSize;
      });
    });
  }

  void reset() {
    canLoadMore = true;
    future = null;
    loadMore(true);
  }

  Expression<bool> conditionFunc(
    Artists artists,
    ReleaseGroups releaseGroups,
    ReleaseGroupStats releaseGroupStats
  ) {
    var expressions = <Expression<bool>>[];
    var listFilterExpr = switch(filter.artistListFilter) {
      ArtistListFilter.none => null,
      ArtistListFilter.inWhitelist => artists.filterListAbbr.isValue(FilterList.whitelist.abbr),
      ArtistListFilter.inBlacklist => artists.filterListAbbr.isValue(FilterList.blacklist.abbr),
      ArtistListFilter.notInWhitelist => artists.filterListAbbr.isNotValue(FilterList.whitelist.abbr),
      ArtistListFilter.notInBlacklist => artists.filterListAbbr.isNotValue(FilterList.blacklist.abbr),
      ArtistListFilter.inList => artists.filterListAbbr.isNotValue(FilterList.none.abbr),
      ArtistListFilter.notInList => artists.filterListAbbr.isValue(FilterList.none.abbr),
    };
    if(listFilterExpr != null)
      expressions.add(listFilterExpr);
    switch(filter.ignoredInclusion) {
      case IgnoredInclusion.exclude:
        expressions.add(releaseGroups.isIgnored.isValue(false));
        break;
      case IgnoredInclusion.includeOnly:
        expressions.add(releaseGroups.isIgnored.isValue(true));
        break;
      default:
    }
    switch(filter.listenedCriteria) {
      case ListenedCriteria.listened:
        expressions.add(releaseGroupStats.releaseGroupId.isNotNull());
        break;
      case ListenedCriteria.notListened:
        expressions.add(releaseGroupStats.releaseGroupId.isNull());
        break;
      default:
    }
    return Expression.and(expressions);
  }

  String searchFunc() {
    var s = search.trim().isEmpty ? '%' : '%${search.replaceAllMapped(RegExp(r'[%_\\]'), (m) => '\\${m[0]}')}%';
    return s;
  }

  Future<List<ReleaseGroupsListResult>> fetchAlbums(int limit, int offset) async {
    var result = await appDb.getReleaseGroups(
      (a, g, gs, as) => conditionFunc(a, g, gs),
      searchFunc(),
      (artists, releaseGroups, releaseGroupStats, artistStats) {
        var useArtistStats = filter.listenedCriteria == ListenedCriteria.notListened;
        var expression = switch(filter.listSortParam) {
          ListSortParam.name => releaseGroups.name,
          ListSortParam.releaseDate => releaseGroups.date,
          ListSortParam.latestListenDate => useArtistStats ? artistStats.listenLatest : releaseGroupStats.listenLatest,
          ListSortParam.listensTotal => useArtistStats ? artistStats.listensTotal : releaseGroupStats.listensTotal,
          ListSortParam.listensWeek => useArtistStats ? artistStats.listensWeek : releaseGroupStats.listensWeek,
          ListSortParam.listensMonth => useArtistStats ? artistStats.listensMonth : releaseGroupStats.listensMonth,
          ListSortParam.listensYear => useArtistStats ? artistStats.listensYear : releaseGroupStats.listensYear
        };
        var mode = filter.isAscending ? OrderingMode.asc : OrderingMode.desc;
        return OrderingTerm(expression: expression, mode: mode);
      },
      limit,
      offset,
    ).get();
    return result;
  }

  Future<List<ArtistsListResult>> fetchArtists(int limit, int offset) async {
    var result = await appDb.getArtists(
      (a, g, gs, as) => conditionFunc(a, g, gs),
      searchFunc(),
      (artists, releaseGroups, releaseGroupStats, artistStats) {
        Expression expression = switch(filter.listSortParam) {
          ListSortParam.name => artists.name,
          ListSortParam.releaseDate => releaseGroups.date.max(),
          ListSortParam.latestListenDate => artistStats.listenLatest,
          ListSortParam.listensTotal => artistStats.listensTotal,
          ListSortParam.listensWeek => artistStats.listensWeek,
          ListSortParam.listensMonth => artistStats.listensMonth,
          ListSortParam.listensYear => artistStats.listensYear,
        };
        var mode = filter.isAscending ? OrderingMode.asc : OrderingMode.desc;
        return OrderingTerm(expression: expression, mode: mode);
      },
      limit,
      offset,
    ).get();
    return result;
  }

  @override
  void initState() {
    super.initState();
    widget.controller._onSearchSet = (newSearch) {
      setState(() {
        search = newSearch;
        reset();
      });
    };
    widget.controller._onReload = () {
      setState(() {
        reset();
      });
    };
    loadMore(true);
  }

  Widget listTileForAlbum(ReleaseGroupsListResult result) {
    return Dismissible(
      key: ValueKey(result),
      background: const DismissBackground(true, 'UN-IGNORE'),
      secondaryBackground: const DismissBackground(false, 'IGNORE'),
      direction: result.releaseGroup.isIgnored ? DismissDirection.startToEnd : DismissDirection.endToStart,
      onDismissed: (direction) {
        setState(() {
          results.remove(result);
        });
        if(direction == DismissDirection.startToEnd)
          appDb.setReleaseGroupIsIgnored(false, result.releaseGroup.id);
        else if(direction == DismissDirection.endToStart)
          appDb.setReleaseGroupIsIgnored(true, result.releaseGroup.id);
      },
      child: ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: Text(result.releaseGroup.name)),
            ReleasedBadge(result.releaseGroup.date)
          ]
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: Text(result.artist.name, style: const TextStyle(fontWeight: FontWeight.bold))),
            if(result.releaseGroupStats?.listenLatest != null)
              ListenedBadge(result.releaseGroupStats!.listenLatest)
          ]
        ),
        onTap: () async {
          await Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (context) => ReleaseGroupPage(
              title: result.releaseGroup.name,
              releaseGroupId: result.releaseGroup.id
            ))
          );
          reload();
        }
      )
    );
  }

  Widget listTileForArtist(ArtistsListResult result) {
    var canWhitelist = result.artist.filterListAbbr != FilterList.whitelist.abbr;
    var canBlacklist = result.artist.filterListAbbr != FilterList.blacklist.abbr;
    DismissDirection direction;
    if(canWhitelist && canBlacklist)
      direction = DismissDirection.horizontal;
    else if(canWhitelist)
      direction = DismissDirection.startToEnd;
    else if(canBlacklist)
      direction = DismissDirection.endToStart;
    else
      direction = DismissDirection.none;

    return Dismissible(
      key: ValueKey(result),
      background: const DismissBackground(true, 'WHITELIST'),
      secondaryBackground: const DismissBackground(false, 'BLACKLIST'),
      direction: direction,
      onDismissed: (direction) {
        setState(() {
          results.remove(result);
        });
        if(direction == DismissDirection.startToEnd)
          appDb.setArtistFilterList(FilterList.whitelist.abbr, result.artist.id);
        else if(direction == DismissDirection.endToStart)
          appDb.setArtistFilterList(FilterList.blacklist.abbr, result.artist.id);
      },
      child: ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: Text(result.artist.name)),
            ReleasedBadge(result.lastReleaseGroupDate ?? '')
          ]
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            if(result.artistStats?.listenLatest != null)
              ListenedBadge(result.artistStats!.listenLatest)
          ]
        ),
        onTap: () async {
          await Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (context) => ArtistPage(title: result.artist.name, artistId: result.artist.id))
          );
          reload();
        },
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ValueListenableBuilder(
          valueListenable: detailsShown,
          builder: (context, value, child) {
            return Column(
              children: [
                FilterPresetsSelector(
                  currentPreset: filter,
                  onCurrentChanged: (newPreset) {
                    setState(() {
                      filter = newPreset;
                      if(filter.id != 0 && appConfig.filterId != filter.id)
                        appConfig.filterId = filter.id;
                      reset();
                    });
                  },
                  detailsShown: detailsShown
                ),
                if(value)
                  CurrentFilterWidget(
                    filter: filter,
                    onChanged: (newFilter) {
                      setState(() {
                        filter = newFilter;
                        reset();
                      });
                    }
                  ),
              ],
            );
          }
        ),
        Expanded(
          child: ListView.separated(
            controller: controller,
            itemCount: results.length + (canLoadMore ? 1 : 0),
            itemBuilder: (context, index) {
              if(index == results.length) {
                return ElevatedButton(
                  onPressed: () {
                    loadMore(false);
                  },
                  child: FutureBuilder(
                    future: future,
                    builder: (context, snapshot) {
                      if(snapshot.hasData)
                        return const Text('Load more');
                      return const CircularProgressIndicator();
                    },
                  )
                );
              }
              var result = results[index];
              if(result is ReleaseGroupsListResult)
                return listTileForAlbum(result);
              return listTileForArtist(result);
            },
            separatorBuilder: (context, index) {
              return const Divider();
            },
          ),
        )
      ],
    );
  }
}
