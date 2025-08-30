// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:typed_prefs/annotations.dart';

part 'config.g.dart';

@immutable
@TypedPrefs((
  apiEndpoint: '',
  token: '',
  userName: '',
  hideReleaseGroupsTypes: <String>[],
  showLastUpdateDates: false,
  showListenBrainzId: false,
  minDaysToUpdateArtist: 7,
  filterId: 0,
  statsUpdatedAt: 0,
))
final class Config {
  const Config();
}
const appConfig = Config();
