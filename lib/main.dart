import 'package:flutter/material.dart';

import 'src/repositories/tiniping_repository.dart';
import 'src/screens/tiniping_grid_screen.dart';

void main() {
  runApp(const TingpingDexApp());
}

class TingpingDexApp extends StatelessWidget {
  const TingpingDexApp({super.key, this.repository});

  final TinipingRepository? repository;

  static const String _sheetUrl =
      'https://docs.google.com/spreadsheets/d/1tcz2LVjw6k_Fja9I0MzgC_SKS5751GFJawpVOryDc0k/edit?pli=1&gid=0#gid=0';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '티니핑 도감',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
        useMaterial3: true,
      ),
      home: TinipingGridScreen(
        repository:
            repository ??
            GoogleSheetTinipingRepository(sheetUrl: _sheetUrl),
      ),
    );
  }
}
