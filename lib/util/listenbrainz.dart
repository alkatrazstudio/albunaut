// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../util/config.dart';

class ListenBrainzThrottling {
  const ListenBrainzThrottling({
    required this.remaining,
    required this.resetIn
  });

  final int remaining;
  final int resetIn;
}

class ListenBrainzResponse {
  const ListenBrainzResponse({
    required this.throttling,
    required this.payload
  });

  final ListenBrainzThrottling throttling;
  final dynamic payload;
}

class ListenBrainzRequest {
  const ListenBrainzRequest({
    this.endpoint,
    required this.path,
    this.uriParams = const {}
  });

  final String path;
  final String? endpoint;
  final Map<String, dynamic> uriParams;

  Uri get uri {
    Uri? uri;
    var ep = endpoint ?? appConfig.apiEndpoint;
    var uriStr = ep.isNotEmpty ? ep : 'https://api.listenbrainz.org';
    uri = Uri.parse(uriStr);
    var strParams = <String, String>{};
    for(var param in uriParams.entries) {
      if(param.value != null)
        strParams[param.key] = param.value.toString();
    }
    uri = uri.replace(path: path, queryParameters: strParams);
    return uri;
  }
}

class ListenBrainzListen {
  const ListenBrainzListen({
    required this.listenedAt,
    required this.recordingId,
    required this.recordingName,
    required this.releaseId,
    required this.releaseName,
    required this.artistId,
    required this.artistName,
    required this.coverReleaseId
  });

  final int listenedAt;
  final String? recordingId;
  final String recordingName;
  final String? releaseId;
  final String? releaseName;
  final String? artistId;
  final String? artistName;
  final String? coverReleaseId;
}

class ListenBrainzListensResponse {
  const ListenBrainzListensResponse({
    required this.listens,
    required this.totalReturned,
    required this.lastListenedAt
  });

  final List<ListenBrainzListen> listens;
  final int totalReturned;
  final int lastListenedAt;
}

class ListenBrainzReleaseGroup {
  const ListenBrainzReleaseGroup({
    required this.id,
    required this.name,
    required this.type,
    required this.secondaryTypes,
    required this.date,
    required this.artistId,
    required this.artistName,
    required this.coverReleaseId
  });

  final String id;
  final String name;
  final String type;
  final List<String> secondaryTypes;
  final String date;
  final String artistId;
  final String artistName;
  final String coverReleaseId;
}

class ListenBrainz {
  bool isRunning = false;
  DateTime? waitUntil;

  var client = HttpClient();

  static const waitTimeoutMs = 10;
  static const maxListensPerQuery = 1000; // MAX_ITEMS_PER_GET https://listenbrainz.readthedocs.io/en/latest/users/api/core.html#listenbrainz.webserver.views.api_tools.MAX_ITEMS_PER_GET
  static const maxArtistsPerQuery = 50;
  static const maxRecordingsPerQuery = 50;

  Future<String> getUserNameByToken(String token, {String? endpoint}) async {
    var resp = await get<Map<String, dynamic>>(
      '1/validate-token',
      token: token,
      endpoint: endpoint
    );
    if(resp['valid'] == true)
      return resp['user_name'];
    throw Exception(resp['message']);
  }

  Future<int> getOldestListenTS() async {
    var resp = await get<Map<String, dynamic>>(
        '/1/user/${appConfig.userName}/listens',
        uriParams: {'count': 1, 'max_ts': 1}
    );
    var ts = resp['payload']['oldest_listen_ts'];
    return ts;
  }

  Future<ListenBrainzListensResponse> getListens({required int count, required int startFromTS}) async {
    var uri = '/1/user/${appConfig.userName}/listens';
    var resp = await get<Map<String, dynamic>>(
      uri,
      uriParams: {'count': count, 'min_ts': startFromTS}
    );
    var respListens = resp['payload']['listens'] as List<dynamic>;
    var totalReturned = respListens.length;
    var listens = <ListenBrainzListen>[];
    int? lastListenedAt;
    for(var respListen in respListens.reversed) {
      try {
        var listenedAt = respListen['listened_at'] as int;
        lastListenedAt = listenedAt;
        var meta = respListen['track_metadata'] as Map<String, dynamic>?;
        var mapping = meta?['mbid_mapping'];
        var listen = ListenBrainzListen(
          listenedAt: listenedAt,
          recordingId: mapping?['recording_mbid'],
          recordingName: mapping?['recording_name'] ?? meta?['track_name'],
          releaseId: mapping?['release_mbid'],
          releaseName: meta?['release_name'],
          artistId: mapping?['artist_mbids']?[0],
          artistName: meta?['artist_name'],
          coverReleaseId: mapping?['caa_release_mbid'] ?? ''
        );
        listens.add(listen);
      } catch(e) {
        if (kDebugMode) {
          print(e);
        }
      }
    }
    return ListenBrainzListensResponse(listens: listens, totalReturned: totalReturned, lastListenedAt: lastListenedAt ?? 0);
  }

  Future<Map<String, List<ListenBrainzReleaseGroup>>> getReleaseGroupsFromArtists(List<String> artistIds) async {
    if(artistIds.isEmpty)
      return {};
    var respArtists = await get<List<dynamic>>(
        '/1/metadata/artist',
        uriParams: {'artist_mbids': artistIds.join(','), 'inc': 'release_group'}
    );
    var result = <String, List<ListenBrainzReleaseGroup>>{};
    for(var respArtist in respArtists) {
      var groups = <ListenBrainzReleaseGroup>[];
      var artistId = respArtist['artist_mbid'] as String;
      var respGroups = respArtist['release_group'] as List<dynamic>;
      for(var respGroup in respGroups) {
        var secondaryTypes = (respGroup['secondary_types'] as List<dynamic>?) ?? [];
        var group = ListenBrainzReleaseGroup(
          id: respGroup['mbid'],
          name: respGroup['name'],
          type: respGroup['type'] ?? '',
          secondaryTypes: secondaryTypes.map((t) => t as String).toList(),
          date: respGroup['date'] ?? '',
          artistId: artistId,
          artistName: respArtist['name'],
          coverReleaseId: respGroup['caa_release_mbid'] ?? ''
        );
        groups.add(group);
      }
      result[artistId] = groups;
    }
    return result;
  }

  Future<Map<String, String>> getReleaseGroupsFromRecordings(List<String> recordingIds) async {
    if(recordingIds.isEmpty)
      return {};
    var respRecordings = await get<Map<String, dynamic>>(
      '/1/metadata/recording',
      uriParams: {'recording_mbids': recordingIds.join(','), 'inc': 'release'}
    );
    var groupsMap = <String, String>{};
    for(var respRec in respRecordings.entries) {
      var groupId = respRec.value['release']['release_group_mbid'];
      groupsMap[respRec.key] = groupId;
    }
    return groupsMap;
  }

  Future<ListenBrainzResponse> runRaw(ListenBrainzRequest request, String token) async {
    var req = await client.getUrl(request.uri);
    if(token.isNotEmpty)
      req.headers.set(HttpHeaders.authorizationHeader, 'Token $token');
    var resp = await req.close();
    var json = await resp.transform(utf8.decoder).join();
    var payload = jsonDecode(json);
    var remainingStr = resp.headers.value('X-RateLimit-Remaining') ?? '';
    var resetInStr = resp.headers.value('X-RateLimit-Reset-In') ?? '';
    var throttling = ListenBrainzThrottling(
      remaining: int.tryParse(remainingStr) ?? 0,
      resetIn: int.tryParse(resetInStr) ?? 0
    );
    var response = ListenBrainzResponse(throttling: throttling, payload: payload);
    return response;
  }

  Future<T> get<T>(String path, {Map<String, dynamic> uriParams = const {}, String? token, String? endpoint}) async {
    while(isRunning)
      await Future.delayed(const Duration(milliseconds: waitTimeoutMs));
    isRunning = true;

    var waitUntil = this.waitUntil;
    if(waitUntil != null) {
      var uSecs = waitUntil.microsecondsSinceEpoch - DateTime.now().microsecondsSinceEpoch;
      if(uSecs > 0)
        await Future.delayed(Duration(microseconds: uSecs));
      this.waitUntil = null;
    }

    try {
      var req = ListenBrainzRequest(path: path, uriParams: uriParams, endpoint: endpoint);
      var resp = await runRaw(req, token ?? appConfig.token);
      if(resp.throttling.remaining == 0) {
        var waitUntil = DateTime.now().add(Duration(seconds: resp.throttling.resetIn + 1));
        this.waitUntil = waitUntil;
      }
      isRunning = false;
      return resp.payload as T;
    } catch(e) {
      isRunning = false;
      rethrow;
    }
  }
}

final listenBrainz = ListenBrainz();
