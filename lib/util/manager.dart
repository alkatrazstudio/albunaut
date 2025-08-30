// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';

import '../db/database.dart';
import '../util/config.dart';
import '../util/listenbrainz.dart';

enum FilterList {
  none(''),
  whitelist('w'),
  blacklist('b');

  final String abbr;
  const FilterList(this.abbr);
}

class Manager {
  static final isLoading = ValueNotifier(false);

  static Future<void> downloadAllNewListens() async {
    if(isLoading.value)
      return;
    Object? lastErr;
    isLoading.value = true;
    try {
      var startFromTS = await appDb.getMaxListenedAt().getSingle() ?? 0;
      if(startFromTS == 0)
        startFromTS = await listenBrainz.getOldestListenTS();
      if(startFromTS == 0)
        return;
      startFromTS--;
      do {
        startFromTS = await downloadNewListens(startFromTS - 1);
      } while(startFromTS != 0);
    } catch(e) {
      lastErr = e;
      print(e);
    }
    try {
      await updateStats();
    } catch(e) {
      lastErr ??= e;
      print(e);
    }
    try {
      await updateReleaseGroupsHasHiddenType();
    } catch(e) {
      lastErr ??= e;
      print(e);
    }
    isLoading.value = false;
    if(lastErr != null)
      throw lastErr;
  }

  static Future<void> downloadNewReleaseGroups() async {
    var days = Duration(days: appConfig.minDaysToUpdateArtist);
    var maxDate = DateTime.now().subtract(days);
    var maxTS = maxDate.millisecondsSinceEpoch ~/ 1000;
    var ids = await appDb.getArtistsForUpdate(maxTS).get();
    await downloadAllReleaseGroupsFromArtists(ids);
  }

  static Future<int> downloadNewListens(int startFromTS) async {
    // find new listens
    var requestedCount = ListenBrainz.maxListensPerQuery;
    var lbListensResp = await listenBrainz.getListens(startFromTS: startFromTS, count: requestedCount);
    if(lbListensResp.listens.isEmpty)
      return 0;
    var newListens = <ListenBrainzListen>[];
    for(var lbListen in lbListensResp.listens) {
      var existingLbListen = await appDb.getListen(lbListen.recordingId, lbListen.listenedAt).getSingleOrNull();
      if(existingLbListen == null)
        newListens.add(lbListen);
    }
    if(newListens.isEmpty)
      return 0;

    // create artists
    var artists = <String, Artist?>{};
    var artistIdsToQuery = <String>[];
    var now = DateTime.now();
    for(var lbListen in newListens) {
      var artistId = lbListen.artistId;
      var artistName = lbListen.artistName;
      if(artistId == null || artistName == null)
        continue;
      var artist = artists[artistId] ??= await appDb.getArtist(artistId).getSingleOrNull();
      if(artist == null) {
        artist = Artist(
          id: artistId,
          name: artistName,
          filterListAbbr: FilterList.none.abbr,
          lastUpdatedAt: 0
        );
        appDb.addArtist(artist);
        artists[artistId] = artist;
      }
      var updatedDays = now.difference(DateTime.fromMillisecondsSinceEpoch(artist.lastUpdatedAt * 1000)).inDays;
      if(updatedDays > 0)
        artistIdsToQuery.add(artistId);
    }

    // create release groups
    var artistsReleaseGroups = await downloadAllReleaseGroupsFromArtists(artistIdsToQuery);

    // find release group in existing release groups
    var recordingReleaseGroups = <String, String>{};
    var recordingListens = <String, ListenBrainzListen>{};
    var releases = <String, Release?>{};
    var recordingsToQuery = <String>[];
    for(var lbListen in newListens) {
      var recordingId = lbListen.recordingId;
      var releaseId = lbListen.releaseId;
      var artistId = lbListen.artistId;
      if(recordingId == null || releaseId == null || artistId == null)
        continue;
      if(recordingReleaseGroups.containsKey(recordingId))
        continue;
      Release? dbRelease;
      if(releases.containsKey(releaseId))
        dbRelease = releases[releaseId];
      else
        dbRelease = releases[releaseId] = await appDb.getRelease(releaseId).getSingleOrNull();
      var groupId = dbRelease?.releaseGroupId ?? '';
      if(groupId.isEmpty) {
        var dbGroups = artistsReleaseGroups[artistId] ??= await appDb.getReleaseGroupsForArtist(artistId).get();
        var existingGroupId = findReleaseGroupIdInGroupsList(lbListen, dbGroups);
        if(existingGroupId != null) {
          if(existingGroupId.isEmpty) {
            recordingReleaseGroups[recordingId] = existingGroupId;
            recordingListens[recordingId] = lbListen;
            continue;
          }
          groupId = existingGroupId;
        }
      }
      if(groupId.isEmpty)
        recordingsToQuery.add(recordingId);
      recordingReleaseGroups[recordingId] = groupId;
      recordingListens[recordingId] = lbListen;
    }

    // find release group from recordings
    var recordingsReleaseGroups = await downloadAllReleaseGroupsFromRecordings(recordingsToQuery);
    for(var entry in recordingReleaseGroups.entries) {
      if(entry.value.isNotEmpty)
        continue;
      var releaseGroupId = recordingsReleaseGroups[entry.key] ?? '';
      if(releaseGroupId.isEmpty)
        continue;
      var lbListen = recordingListens[entry.key]!;
      var artistId = lbListen.artistId;
      if(artistId == null)
        continue;
      var dbGroups = artistsReleaseGroups[artistId] ??= await appDb.getReleaseGroupsForArtist(artistId).get();
      var dbGroup = dbGroups.firstWhereOrNull((dbGroup) => dbGroup.id == releaseGroupId);
      if(dbGroup == null)
        continue; // found group ID, but the group itself was not created (should not happen, but will happen)
      recordingsReleaseGroups[entry.key] = releaseGroupId;
    }

    // create releases, recordings and listens (groups and artists should be already created by the above code)
    var recordings = <String, Recording?>{};
    for(var lbListen in newListens) {
      var recordingId = lbListen.recordingId;
      var releaseId = lbListen.releaseId;
      Recording? rec;
      if(recordingId != null && releaseId != null) {
        rec = recordings[recordingId] ??= await appDb.getRecording(recordingId).getSingleOrNull();
        if(rec == null) {
          var release = releases[releaseId] ??= await appDb.getRelease(releaseId).getSingleOrNull();
          if(release == null) {
            var groupId = recordingReleaseGroups[recordingId] ?? '';
            if(groupId.isNotEmpty) {
              release = Release(id: releaseId, releaseGroupId: groupId);
              await appDb.addRelease(release);
              releases[releaseId] = release;
            }
          }
          if(release != null) {
            rec = Recording(id: recordingId, name: lbListen.recordingName, releaseId: releaseId);
            await appDb.addRecording(rec);
            recordings[recordingId] = rec;
          }
        }
      }
      Listen dbListen;
      if(rec == null) {
        dbListen = Listen(listenedAt: lbListen.listenedAt, artistName: lbListen.artistName, releaseName: lbListen.releaseName, trackName: lbListen.recordingName);
      } else {
        dbListen = Listen(listenedAt: lbListen.listenedAt, recordingId: lbListen.recordingId);
      }
      await appDb.addListen(dbListen);
    }

    if(lbListensResp.totalReturned != requestedCount)
      return 0;
    return lbListensResp.lastListenedAt;
  }

  static Future<Map<String, List<ReleaseGroup>>> downloadAllReleaseGroupsFromArtists(List<String> artistIds) async {
    artistIds = artistIds.toSet().toList();
    var chunks = artistIds.slices(ListenBrainz.maxArtistsPerQuery);
    var result = <String, List<ReleaseGroup>>{};
    for(var chunk in chunks) {
      var chunkResult = await _downloadReleaseGroupsFromArtists(chunk);
      result.addAll(chunkResult);
    }
    return result;
  }

  static Future<int> _addReleaseGroupType(String name) async {
    var groupTypeId = await appDb.getReleaseGroupTypeIdByName(name).getSingleOrNull();
    if(groupTypeId != null)
      return groupTypeId;
    var newGroupTypeId = await appDb.addReleaseGroupType(name);
    return newGroupTypeId;
  }

  static Future<Map<String, List<ReleaseGroup>>> _downloadReleaseGroupsFromArtists(List<String> artistIds) async {
    var lbGroupsMap = await listenBrainz.getReleaseGroupsFromArtists(artistIds);
    var dbGroupsMap = <String, List<ReleaseGroup>>{};
    for(var lbGroupsEntry in lbGroupsMap.entries) {
      var dbGroups = <ReleaseGroup>[];
      for(var lbGroup in lbGroupsEntry.value) {
        var dbGroup = await appDb.getReleaseGroup(lbGroup.id).getSingleOrNull();
        if(dbGroup == null) {
          await appDb.transaction(() async {
            var dbGroupTypeId = await _addReleaseGroupType(lbGroup.type);
            dbGroup = ReleaseGroup(
              id: lbGroup.id,
              artistId: lbGroup.artistId,
              coverReleaseId: lbGroup.coverReleaseId,
              name: lbGroup.name,
              typeId: dbGroupTypeId,
              date: lbGroup.date,
              isIgnored: false,
              hasHiddenType: false
            );
            await appDb.addReleaseGroup(dbGroup!);
            for(var secType in lbGroup.secondaryTypes) {
              var dbSecGroupTypeId = await _addReleaseGroupType(secType);
              await appDb.addReleaseGroupSecondaryType(lbGroup.id, dbSecGroupTypeId);
            }
          });
        }
        dbGroups.add(dbGroup!);
      }
      await appDb.setArtistUpdated((DateTime.now().millisecondsSinceEpoch / 1000).round(), lbGroupsEntry.key);
      dbGroupsMap[lbGroupsEntry.key] = dbGroups;
    }
    return dbGroupsMap;
  }

  static Future<Map<String, String>> downloadAllReleaseGroupsFromRecordings(List<String> recordingIds) async {
    recordingIds = recordingIds.toSet().toList();
    var chunks = recordingIds.slices(ListenBrainz.maxRecordingsPerQuery);
    var result = <String, String>{};
    for(var chunk in chunks) {
      var chunkResult = await _downloadReleaseGroupsFromRecordings(chunk);
      result.addAll(chunkResult);
    }
    return result;
  }

  static Future<Map<String, String>> _downloadReleaseGroupsFromRecordings(List<String> recordingIds) async {
    var releaseGroups = await listenBrainz.getReleaseGroupsFromRecordings(recordingIds);
    return releaseGroups;
  }

  static String? findReleaseGroupIdInGroupsList(ListenBrainzListen lbListen, List<ReleaseGroup> dbGroups) {
    for(var dbGroup in dbGroups) {
      if(dbGroup.coverReleaseId.isNotEmpty && dbGroup.coverReleaseId == lbListen.coverReleaseId)
        return dbGroup.id;
    }
    var matchingGroups = dbGroups.where((g) => g.name == lbListen.releaseName).toList();
    if(matchingGroups.length == 1)
      return matchingGroups.first.id;
    if(matchingGroups.length > 1)
      return '';
    return null;
  }

  static Future<String?> findExistingReleaseGroupId(ListenBrainzListen lbListen) async {
    var artistId = lbListen.artistId;
    if(artistId == null)
      return '';
    var dbGroups = await appDb.getReleaseGroupsForArtist(artistId).get();
    var groupId = findReleaseGroupIdInGroupsList(lbListen, dbGroups);
    return groupId;
  }

  static Future<void> updateStats() async {
    var now = DateTime.now();
    var weekTS  = now.subtract(const Duration(days:   7)).millisecondsSinceEpoch ~/ 1000;
    var monthTS = now.subtract(const Duration(days:  30)).millisecondsSinceEpoch ~/ 1000;
    var yearTS  = now.subtract(const Duration(days: 365)).millisecondsSinceEpoch ~/ 1000;
    await appDb.transaction(() async {
      await appDb.clearArtistStats();
      await appDb.updateArtistStats(weekTS, monthTS, yearTS);
      await appDb.clearReleaseGroupStats();
      await appDb.updateReleaseGroupStats(weekTS, monthTS, yearTS);
    });
    appConfig.statsUpdatedAt = now.millisecondsSinceEpoch ~/ 1000;
  }

  static Future<void> updateReleaseGroupsHasHiddenType() async {
    var hiddenTypes = appConfig.hideReleaseGroupsTypes;
    await appDb.updateReleaseGroupsHasHiddenType(hiddenTypes);
  }

  static Future<void> deleteListens() async {
    await appDb.listens.deleteAll();
    await Manager.updateStats();
  }
}
