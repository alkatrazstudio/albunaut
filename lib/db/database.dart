// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import '../util/filter.dart';

part 'database.g.dart';

@DriftDatabase(include: {'database.drift'})
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      if (Platform.isAndroid)
        await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
      sqlite3.tempDirectory = (await getTemporaryDirectory()).path;
      return NativeDatabase.createInBackground(
        await AppDatabase.file(),
        logStatements: false,
        cachePreparedStatements: true
      );
    });
  }

  Future<List<QueryRow>> run(String sql, {Set<TableInfo>? updates}) async {
    if(sql.trim().startsWith(RegExp('^(SELECT|EXPLAIN)', caseSensitive: false))) {
      var rows = await customSelect(sql).get();
      return rows;
    }
    await customUpdate(sql, updates: updates);
    return [];
  }

  static Future<File> file() async {
    var dbFolder = await getApplicationDocumentsDirectory();
    var file = File(path.join(dbFolder.path, 'db.sqlite'));
    return file;
  }
}

final appDb = AppDatabase();

abstract class DbDefaults {
  static FilterPreset filterPreset() {
    return const FilterPreset(
      id: 0,
      name: '',
      listenedCriteria: ListenedCriteria.notListened,
      artistListFilter: ArtistListFilter.none,
      entryType: EntryType.releaseGroup,
      isAscending: false,
      listSortParam: ListSortParam.releaseDate,
      ignoredInclusion: IgnoredInclusion.exclude
    );
  }
}
