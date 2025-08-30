// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/material.dart';

import 'package:pad5/pad5.dart';

import '../widgets/section_header.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.header,
    required this.child,
    this.childIsExpanded = false
  });

  final String header;
  final Widget child;
  final bool childIsExpanded;

  @override
  Widget build(context) {
    return Card(
      child: Column(
        children: [
          SectionHeader(header),
          if(childIsExpanded)
            Expanded(child: child.padAll)
          else
            child.padAll
        ],
      ),
    );
  }
}
