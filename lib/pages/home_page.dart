// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/material.dart';

import '../pages/help_page.dart';
import '../pages/listens_page.dart';
import '../pages/settings_page.dart';
import '../pages/sql_page.dart';
import '../util/config.dart';
import '../util/alert_util.dart';
import '../util/manager.dart';
import '../widgets/albums_list.dart';
import '../widgets/dialogs.dart';

class HomePage extends StatelessWidget {
  final albumsListController = AlbumsListController();
  final searchController = TextEditingController();

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Search...',
            suffixIcon: IconButton(
              onPressed: () {
                searchController.clear();
                albumsListController.setSearch('');
              },
              icon: const Icon(Icons.clear)
            )
          ),
          onChanged: (value) {
            albumsListController.setSearch(value);
          },
        ),
        actions: [
          ValueListenableBuilder(
            valueListenable: Manager.isLoading,
            builder: (context, isLoading, child) {
              return IconButton(
                onPressed: isLoading ? null : () async {
                  if(appConfig.userName.isEmpty) {
                    await showInfoDialog(
                      context,
                      'Connect your account',
                      'Setup your ListenBrainz token and/or username in Settings.'
                    );
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsPage())
                    );
                    return;
                  }
                  try {
                    await Manager.downloadAllNewListens();
                    alert(context, 'Sync done!');
                  } catch(e) {
                    alert(context, e);
                  } finally {
                    albumsListController.reload();
                  }
                },
                icon: isLoading ? const CircularProgressIndicator() : const Icon(Icons.refresh)
              );
            },
          ),
          ValueListenableBuilder(
            valueListenable: Manager.isLoading,
            builder: (context, isLoading, child) {
              return MenuAnchor(
                menuChildren: [
                  MenuItemButton(
                    onPressed: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute(builder: (context) => ListensPage())
                      );
                    },
                    leadingIcon: const Icon(Icons.queue_music),
                    child: const Text('Listens'),
                  ),
                  MenuItemButton(
                    onPressed: isLoading ? null : () async {
                      await Navigator.push<void>(
                        context,
                        MaterialPageRoute(builder: (context) => SqlPage())
                      );
                      albumsListController.reload();
                    },
                    leadingIcon: const Icon(Icons.storage),
                    child: const Text('Database'),
                  ),
                  MenuItemButton(
                    onPressed: isLoading ? null : () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute(builder: (context) => SettingsPage())
                      );
                    },
                    leadingIcon: const Icon(Icons.settings),
                    child: const Text('Settings'),
                  ),
                  MenuItemButton(
                    onPressed: () {
                      showHelpPage(context);
                    },
                    leadingIcon: const Icon(Icons.help),
                    child: const Text('Help'),
                  )
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
              );
            }
          )
        ],
      ),
      body: AlbumsList(
        controller: albumsListController,
      ),
    );
  }
}
