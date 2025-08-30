// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/material.dart';

Future<void> showInfoDialog(
  BuildContext context,
  String title,
  String text
) async {
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop()
          )
        ]
      );
    }
  );
}

Future<bool> showConfirmDialog(
  BuildContext context,
  String title,
  String text
) async {
  return (await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: <Widget>[
          TextButton(
            child: const Text('No'),
            onPressed: () => Navigator.of(context).pop()
          ),
          TextButton(
            child: const Text('Yes'),
            onPressed: () => Navigator.of(context).pop(true)
          )
        ]
      );
    }
  )) ?? false;
}

Future<String?> showSaveDialog({
  required BuildContext context,
  required String title,
  String initialText = ''
}) async {

  void submit(String text) {
    text = text.trim();
    if(text.isEmpty)
      Navigator.of(context).pop(null);
    else
      Navigator.of(context).pop(text);
  }

  return await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      var inputController = TextEditingController();
      inputController.text = initialText;

      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title),
            TextField(
              autofocus: true,
              controller: inputController,
              textInputAction: TextInputAction.go,
              onSubmitted: (text) => submit(text)
            )
          ]
        ),
        actions: [
          TextButton(
            child: const Text('Save'),
            onPressed: () {
              submit(inputController.text);
            }
          )
        ]
      );
    }
  );
}
