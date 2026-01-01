// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:mega_form/mega_form.dart';

import '../db/database.dart';
import '../util/alert_util.dart';
import '../util/config.dart';
import '../util/listenbrainz.dart';
import '../util/manager.dart';
import '../widgets/dialogs.dart';

class SettingsPage extends StatelessWidget {
  final controller = MegaFormController();
  final isSaving = ValueNotifier(false);

  static const defaultReleaseTypes = [
    '', 'Album', 'Audio drama', 'Audiobook', 'Broadcast', 'Compilation',
    'DJ-mix', 'Demo', 'EP', 'Field recording', 'Interview', 'Live',
    'Mixtape/Street', 'Other', 'Remix', 'Single', 'Soundtrack', 'Spokenword',
  ];

  Future<void> save(BuildContext context) async {
    var json = controller.save();
    if(json == null)
      return;

    var prevUserName = appConfig.userName;
    String userName;
    if((json['token'] as String).isNotEmpty) {
      if(json['apiEndpoint'] != appConfig.apiEndpoint || json['token'] != appConfig.token)
        userName = await listenBrainz.getUserNameByToken(json['token'], endpoint: json['apiEndpoint']);
      else
        userName = appConfig.userName;
    } else {
      userName = json['userName'];
    }
    if(userName.isEmpty)
      throw Exception('Must set either token or user name');
    if(prevUserName.isNotEmpty && userName != prevUserName) {
      var listensCount = await appDb.listens.count().getSingle();
      if(listensCount > 0) {
        if(context.mounted) {
          var doClear = await showConfirmDialog(
            context,
            'Changing the user name',
            'You have changed the user name to "$userName", but the current database has data for the user "$prevUserName".\n\nDo you want to remove all this data? It\'s the same as Database > Remove listens.'
          );
          if(doClear)
            await Manager.deleteListens();
        }
      }
    }
    json['userName'] = userName;
    json['hideReleaseGroupsTypes'] = (json['hideReleaseGroupsTypes'] as List).cast<String>();
    appConfig.applyJson(json);

    await Manager.updateReleaseGroupsHasHiddenType();

    if(context.mounted)
      Navigator.of(context).pop();
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: MegaForm(
          controller: controller,
          child: Column(
            children: [
              MegaFormSettingsGroup(
                title: 'ListenBrainz connection',
                fields: [
                  MegaFormFieldString(
                    label: 'API endpoint\n(leave empty to use the offical server)',
                    name: 'apiEndpoint',
                    initialValue: appConfig.apiEndpoint,
                    maxLen: 255,
                    isRequired: false,
                  ),
                  MegaFormFieldString(
                    label: 'Token',
                    name: 'token',
                    initialValue: appConfig.token,
                    isRequired: false,
                    maxLen: 36,
                  ),
                  MegaFormFieldString(
                    label: 'Username',
                    name: 'userName',
                    initialValue: appConfig.userName,
                    isRequired: false,
                    maxLen: 255,
                  ),
                ],
              ),
              MegaFormSettingsGroup(
                title: 'Display',
                fields: [
                  StreamBuilder(
                    stream: appDb.getReleaseGroupTypes().watch(),
                    builder: (context, snapshot) {
                      var options = snapshot.data ?? [];
                      options.addAll(defaultReleaseTypes);
                      options = options.toSet().toList().sortedBy((opt) => opt);
                      return MegaFormFieldStringListChip(
                        label: 'Hide release types',
                        name: 'hideReleaseGroupsTypes',
                        initialValue: appConfig.hideReleaseGroupsTypes,
                        options: MegaFormFieldStringListChip.optionsFromStrings(options),
                        selectedColor: Theme.of(context).colorScheme.onError,
                      );
                    },
                  ),
                  MegaFormFieldBool(
                    label: 'Show last update dates',
                    name: 'showLastUpdateDates',
                    initialValue: appConfig.showLastUpdateDates,
                  ),
                  MegaFormFieldBool(
                    label: 'Show ListenBrainz ID',
                    name: 'showListenBrainzId',
                    initialValue: appConfig.showListenBrainzId,
                  ),
                ]
              ),
              MegaFormSettingsGroup(
                title: 'Sync',
                fields: [
                  MegaFormFieldNum(
                    typeName: 'integer',
                    label: 'Number of days before updating an artist\'s albums',
                    name: 'minDaysToUpdateArtist',
                    initialValue: appConfig.minDaysToUpdateArtist,
                  ),
                ]
              ),
            ]
          )
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            isSaving.value = true;
            await save(context);
          } catch(e) {
            alert(context, e);
          } finally {
            isSaving.value = false;
          }
        },
        child: ValueListenableBuilder(
          valueListenable: isSaving,
          builder: (context, value, child) {
            if(value)
              return const CircularProgressIndicator();
            return const Icon(Icons.save);
          },
        )
      ),
    );
  }

  List<String> parseStringList(List<dynamic> dynList) {
    var strList = dynList.map((x) => x as String).toList();
    return strList;
  }
}
