// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:pad5/pad5.dart';

import '../db/database.dart';
import '../util/config.dart';
import '../widgets/dialogs.dart';

class FilterPresetsSelector extends StatelessWidget {
  const FilterPresetsSelector({
    required this.currentPreset,
    required this.onCurrentChanged,
    required this.detailsShown
  });

  final FilterPreset currentPreset;
  final ValueNotifier<bool> detailsShown;
  final void Function(FilterPreset newPreset) onCurrentChanged;

  Future<void> changeById(int id) async {
    var presets = await appDb.getFilterPresets().get();
    if(presets.isEmpty)
      return;
    var preset = presets.firstWhereOrNull((p) => p.id == id);
    if(preset != null)
      onCurrentChanged(preset);
    else
      onCurrentChanged(presets.first);
  }

  @override
  Widget build(context) {
    return StreamBuilder(
      stream: appDb.getFilterPresets().watch(),
      builder: (context, snapshot) {
        var presets = snapshot.data;
        if(presets == null)
          return const SizedBox.shrink();
        if(presets.isEmpty)
          presets = [DbDefaults.filterPreset()];
        var savedPreset = presets.firstWhereOrNull((p) => p.id == currentPreset.id);
        var curPresetId = savedPreset?.id;
        if(curPresetId == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            var preset = presets!.firstWhereOrNull((p) => p.id == appConfig.filterId);
            preset ??= presets.first;
            onCurrentChanged(preset);
          });
        }
        var isCurrentChanged = currentPreset != savedPreset;
        return Row(
          children: [
            IconButton(
              onPressed: () {
                detailsShown.value = !detailsShown.value;
              },
              icon: Icon(detailsShown.value ? Icons.arrow_drop_up : Icons.arrow_drop_down)
            ),
            Expanded(
              child: DropdownButton(
                isExpanded: true,
                value: curPresetId ?? presets.first.id,
                items: presets.map((preset) => DropdownMenuItem(
                  value: preset.id,
                  child: Text(preset.name.isEmpty ? '- no preset -' : '${isCurrentChanged ? '• ' : ''}${preset.name}'),
                )).toList(),
                onChanged: (id) {
                  changeById(id ?? 0);
                }
              ).padLeft
            ),
            MenuAnchor(
              menuChildren: [
                MenuItemButton(
                  onPressed: () async {
                    var name = await showSaveDialog(context: context, title: 'New preset');
                    if(name == null)
                      return;
                    var row = currentPreset.toCompanion(false).copyWith(
                        id: const Value.absent(),
                        name: Value(name)
                    );
                    var newPresetId = await appDb.addFilterPreset(row);
                    changeById(newPresetId);
                  },
                  leadingIcon: const Icon(Icons.add),
                  child: const Text('Save as...'),
                ),
                MenuItemButton(
                  onPressed: currentPreset.id <= 0 ? null : () async {
                    await appDb.filterPresets.insertOnConflictUpdate(currentPreset);
                  },
                  leadingIcon: const Icon(Icons.save),
                  child: const Text('Save'),
                ),
                MenuItemButton(
                  onPressed: currentPreset.id <= 0 ? null : () async {
                    var newName = await showSaveDialog(context: context, title: 'New preset', initialText: currentPreset.name);
                    if(newName == null)
                      return;
                    var updatedPreset = currentPreset.copyWith(name: newName);
                    await appDb.filterPresets.insertOnConflictUpdate(updatedPreset);
                    changeById(currentPreset.id);
                  },
                  leadingIcon: const Icon(Icons.drive_file_rename_outline),
                  child: const Text('Rename...'),
                ),
                MenuItemButton(
                  onPressed: currentPreset.id <= 0 ? null : () async {
                    if(await showConfirmDialog(context, 'Remove the preset', 'This preset will be removed:\n\n${currentPreset.name}'))
                      await appDb.removeFilterPreset(currentPreset.id);
                    changeById(0);
                  },
                  leadingIcon: const Icon(Icons.delete_forever),
                  child: const Text('Remove'),
                ),
                MenuItemButton(
                  onPressed: currentPreset.id <= 0 || savedPreset == null ? null : () {
                    onCurrentChanged(savedPreset);
                  },
                  leadingIcon: const Icon(Icons.refresh),
                  child: const Text('Reload'),
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
                  icon: const Icon(Icons.menu),
                );
              }
            )
          ],
        );
      },
    );
  }
}
