// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/material.dart';

import '../pages/home_page.dart';
import '../util/config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await appConfig.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    var lbColor = const Color.fromARGB(255, 51, 48, 108);

    return MaterialApp(
      title: 'Albunaut',
      theme: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: lbColor,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: lbColor,
      ),
      home: HomePage()
    );
  }
}
