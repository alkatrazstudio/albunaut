// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:drift/drift.dart' hide Column;
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:pad5/pad5.dart';

import '../db/database.dart';
import '../util/alert_util.dart';
import '../util/manager.dart';
import '../widgets/dialogs.dart';

class SqlPage extends StatefulWidget {
  @override
  State<SqlPage> createState() => _SqlPageState();
}

class _SqlPageState extends State<SqlPage> {
  Future<List<QueryRow>>? rowsFuture;

  var sqlController = TextEditingController();
  DateTime? startTime;

  void run() {
    var sql = sqlController.text.trim();
    if(sql.isEmpty)
      return;
    setState(() {
      startTime = DateTime.now();
      rowsFuture = appDb.run(sql);
    });
  }

  void exitApp() {
    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
  }

  Future<void> export() async {
    var name = 'albunaut_${DateFormat('yyyyMMdd').format(DateTime.now())}.sqlite';
    try {
      await appDb.run('BEGIN IMMEDIATE');
      var file = await AppDatabase.file();
      var bytes = await file.readAsBytes();
      await FilePicker.platform.saveFile(
        dialogTitle: 'Save the database',
        fileName: name,
        type: FileType.custom,
        allowedExtensions: ['sqlite'],
        bytes: bytes
      );
    } finally {
      await appDb.run('ROLLBACK');
    }
  }

  Future<void> import() async {
    var result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['sqlite']);
    if(result == null)
      return;
    var filePath = result.files.firstOrNull?.path;
    if(filePath == null)
      throw Exception('Cannot get the file path');
    if(!filePath.endsWith('.sqlite'))
      throw Exception('');
    var srcFile = File(filePath);
    var targetFile = await AppDatabase.file();
    await appDb.close();
    await srcFile.copy(targetFile.path);
    exitApp();
  }

  Future<void> deleteDatabase() async {
    var file = await AppDatabase.file();
    await appDb.close();
    await file.delete();
    exitApp();
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder(
          future: rowsFuture,
          builder: (context, snapshot) {
            var text = 'Database';
            if(snapshot.hasData) {
              var now = DateTime.now().millisecondsSinceEpoch;
              var start = startTime!.millisecondsSinceEpoch;
              var diff = (now - start) / 1000;
              text = '$text [${diff.toStringAsFixed(2)}s]';
            }
            return Text(text);
          }
        ),
        actions: [
          MenuAnchor(
            menuChildren: [
              MenuItemButton(
                onPressed: () async {
                  try {
                    await export();
                    alert(context, 'Exported');
                  } catch(e) {
                    alert(context, e);
                  }
                },
                leadingIcon: const Icon(Icons.file_upload),
                child: const Text('Backup to file'),
              ),
              MenuItemButton(
                onPressed: () async {
                  try {
                    await import();
                  } catch(e) {
                    alert(context, e);
                  }
                },
                leadingIcon: const Icon(Icons.file_download),
                child: const Text('Restore from file'),
              ),
              MenuItemButton(
                onPressed: () async {
                  if(!await showConfirmDialog(context, 'Remove all listens', 'This will remove all listens.\n\nDo a backup first, just in case.\n\nRemove all listens?'))
                    return;
                  try {
                    await Manager.deleteListens();
                  } catch(e) {
                    alert(context, e);
                  }
                },
                leadingIcon: const Icon(Icons.cleaning_services),
                child: const Text('Remove listens'),
              ),
              MenuItemButton(
                onPressed: () async {
                  if(!await showConfirmDialog(
                    context,
                    'Remove everything',
                    'This will completely remove the ENTIRE DATABASE!!!\n\nDo a backup first, just in case.\n\nRemove everything?')
                  ) {
                    return;
                  }
                  try {
                    await deleteDatabase();
                  } catch(e) {
                    alert(context, e);
                  }
                },
                leadingIcon: const Icon(Icons.delete_forever),
                child: const Text('Remove everything'),
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
        ],
      ),
      body: Column(
        children: [
          TextField(
            controller: sqlController,
            minLines: 1,
            maxLines: 10,
            decoration: InputDecoration(
              hintText: 'SQL...',
              prefixIcon:  IconButton(
                onPressed: () {
                  sqlController.text = '';
                },
                icon: const Icon(Icons.clear)
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  run();
                },
                icon: const Icon(Icons.play_arrow)
              )
            ),
            onSubmitted: (sql) {
              run();
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              child: FutureBuilder(
                future: rowsFuture,
                builder: (context, snapshot) {
                  if(rowsFuture == null)
                    return const SizedBox.shrink();
                  if(snapshot.hasError)
                    return Text(snapshot.error?.toString() ?? 'N/A').padAll;
                  if(!snapshot.hasData)
                    return const CircularProgressIndicator();
                  var rows = snapshot.data;
                  if(rows == null || rows.isEmpty)
                    return const Text('- no data -');
                  var firstRow = rows.first;
                  var fields = firstRow.data.keys.toList();
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: fields.map((field) => DataColumn(label: Text(field))).toList(),
                      rows: rows.map((row) => DataRow(
                        cells: fields.map((field) => DataCell(Text(row.data[field]?.toString() ?? '<null>'))).toList()
                      )).toList()
                    )
                  );
                },
              )
            )
          )
        ],
      )
    );
  }
}
