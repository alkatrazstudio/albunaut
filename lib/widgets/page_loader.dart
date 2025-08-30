// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/material.dart';

class PageLoader<T> extends StatelessWidget {
  const PageLoader({
    required this.future,
    required this.builder
  });

  final Future<T> future;
  final Widget Function(BuildContext context, T page) builder;

  @override
  Widget build(context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if(snapshot.hasError)
          return const Center(child: Text('failed to load'));
        var page = snapshot.data;
        if(page == null)
          return const Center(child: CircularProgressIndicator());
        return builder(context, page);
      },
    );
  }
}
