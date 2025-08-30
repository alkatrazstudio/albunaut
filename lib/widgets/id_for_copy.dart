// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../util/config.dart';

class IdForCopy extends StatelessWidget {
  const IdForCopy({
    required this.id
  });

  final String id;

  @override
  Widget build(context) {
    if(!appConfig.showListenBrainzId)
      return const SizedBox.shrink();
    return InkWell(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: id));
        if(context.mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to the clipboard')));
      },
      child: Chip(
        label: Text(id),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
