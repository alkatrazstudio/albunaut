// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/material.dart';

import 'package:drift/drift.dart' hide Column;

import '../db/database.dart';
import '../widgets/listens_list.dart';

class ListensPage extends StatefulWidget {
  @override
  State<ListensPage> createState() => _ListensPageState();
}

class _ListensPageState extends State<ListensPage> {
  static const pageSize = 100;

  var listens = <GetListensResult>[];
  var curPage = 0;
  var search = '';
  Future<List<GetListensResult>>? loadMoreFuture;
  var hasMore = true;
  var searchController = TextEditingController();

  String searchFunc() {
    var s = search.trim();
    s = s.isEmpty ? '%' : '%${s.replaceAllMapped(RegExp(r'[%_\\]'), (m) => '\\${m[0]}')}%';
    return s;
  }

  Future<List<GetListensResult>> loadMore(int page) async {
    var newListens = await appDb.getListens(
      searchFunc(),
      (ln, rec, rel, relG, a) {
        return OrderBy([OrderingTerm(expression: ln.listenedAt, mode: OrderingMode.desc)]);
      },
      pageSize,
      pageSize * page
    ).get();
    setState(() {
      if(page == 0)
        listens = newListens;
      else
        listens.addAll(newListens);
      curPage = page;
      hasMore = newListens.length == pageSize;
    });
    return newListens;
  }

  @override
  Widget build(context) {
    loadMoreFuture ??= loadMore(0);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Search...',
            suffixIcon: IconButton(
              onPressed: () {
                searchController.clear();
                setState(() {
                  search = '';
                  loadMoreFuture = loadMore(0);
                });
              },
              icon: const Icon(Icons.clear)
            )
          ),
          onChanged: (value) {
            setState(() {
              search = value;
              loadMoreFuture = loadMore(0);
            });
          },
        ),
      ),
      body: ListensList(
        items: listens,
        loadMoreBuilder: FutureBuilder(
          future: loadMoreFuture,
          builder: (context, snapshot) {
            var error = snapshot.error;
            if(error != null)
              return Text(error.toString());
            var result = snapshot.data;
            if(result == null)
              return const Center(child: CircularProgressIndicator());
            if(!hasMore)
              return const SizedBox.shrink();
            return ElevatedButton(
              onPressed: () {
                setState(() {
                  loadMoreFuture = loadMore(curPage + 1);
                });
              },
              child: const Text('Load more')
            );
          },
        )
      )
    );
  }
}
