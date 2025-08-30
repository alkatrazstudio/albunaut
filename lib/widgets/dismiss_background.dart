// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/material.dart';

import 'package:pad5/pad5.dart';

class DismissBackground extends StatelessWidget {
  const DismissBackground(this.right, this.text);

  final bool right;
  final String text;

  @override
  Widget build(context) {
    return Container(
      color: right ? Colors.green : Colors.red,
      child: Align(
        alignment: right ? Alignment.centerLeft : Alignment.centerRight,
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold
          ),
        ).padHorizontal
      )
    );
  }
}
