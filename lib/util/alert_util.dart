// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/material.dart';

void alert(BuildContext context, dynamic msg) {
  if(context.mounted)
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg.toString())));
}
