// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title);

  final String title;

  @override
  Widget build(context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Text(title),
        const Expanded(child: Divider())
      ],
    );
  }
}
