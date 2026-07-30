import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;

import '../models/tiniping.dart';

abstract class TinipingRepository {
  Future<List<Tiniping>> fetchTinipings();
}

class GoogleSheetTinipingRepository implements TinipingRepository {
  GoogleSheetTinipingRepository({
    required this.sheetUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String sheetUrl;
  final http.Client _client;

  @override
  Future<List<Tiniping>> fetchTinipings() async {
    final uri = _buildCsvUri(sheetUrl);
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('시트 데이터를 불러오지 못했습니다. (${response.statusCode})');
    }

    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
    ).convert(response.body);
    if (rows.length < 2) {
      return const [];
    }

    final headers = rows.first.map((cell) => '$cell').toList();
    final items = <Tiniping>[];

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final rowMap = <String, String>{};

      for (var col = 0; col < headers.length; col++) {
        final header = headers[col];
        final value = col < row.length ? '${row[col]}'.trim() : '';
        rowMap[header] = value;
      }

      final normalized = <String, String>{};
      rowMap.forEach((key, value) {
        normalized[_normalizeKey(key)] = value;
      });

      String pick(List<String> candidates) {
        for (final candidate in candidates) {
          final value = normalized[_normalizeKey(candidate)] ?? '';
          if (value.isNotEmpty) {
            return value;
          }
        }
        return '';
      }

      final name = pick(['name', '이름', '티니핑', '캐릭터', '캐릭터명']);
      if (name.isEmpty) {
        continue;
      }

      final id =
          pick(['id', '번호', 'no', '순번', 'index']).isEmpty
          ? '$i'
          : pick(['id', '번호', 'no', '순번', 'index']);

      final imageUrl = pick([
        'image',
        'image_url',
        'img',
        '이미지',
        '사진',
        '썸네일',
      ]);
      final type = pick(['type', '속성', '분류', '시즌']);
      final description = pick(['description', '설명', '소개', '특징']);

      final extras = <String, String>{};
      rowMap.forEach((key, value) {
        if (value.isEmpty) {
          return;
        }
        final normalizedKey = _normalizeKey(key);
        final isCoreField = normalizedKey == _normalizeKey('id') ||
            normalizedKey == _normalizeKey('번호') ||
            normalizedKey == _normalizeKey('no') ||
            normalizedKey == _normalizeKey('순번') ||
            normalizedKey == _normalizeKey('index') ||
            normalizedKey == _normalizeKey('name') ||
            normalizedKey == _normalizeKey('이름') ||
            normalizedKey == _normalizeKey('티니핑') ||
            normalizedKey == _normalizeKey('캐릭터') ||
            normalizedKey == _normalizeKey('캐릭터명') ||
            normalizedKey == _normalizeKey('image') ||
            normalizedKey == _normalizeKey('image_url') ||
            normalizedKey == _normalizeKey('img') ||
            normalizedKey == _normalizeKey('이미지') ||
            normalizedKey == _normalizeKey('사진') ||
            normalizedKey == _normalizeKey('썸네일') ||
            normalizedKey == _normalizeKey('type') ||
            normalizedKey == _normalizeKey('속성') ||
            normalizedKey == _normalizeKey('분류') ||
            normalizedKey == _normalizeKey('시즌') ||
            normalizedKey == _normalizeKey('description') ||
            normalizedKey == _normalizeKey('설명') ||
            normalizedKey == _normalizeKey('소개') ||
            normalizedKey == _normalizeKey('특징');

        if (!isCoreField) {
          extras[key] = value;
        }
      });

      items.add(
        Tiniping(
          id: id,
          name: name,
          imageUrl: imageUrl,
          type: type,
          description: description,
          extraFields: extras,
        ),
      );
    }

    return items;
  }

  Uri _buildCsvUri(String spreadsheetUrl) {
    final original = Uri.parse(spreadsheetUrl);
    final segments = original.pathSegments;
    final indexOfD = segments.indexOf('d');
    if (indexOfD == -1 || indexOfD + 1 >= segments.length) {
      throw Exception('Google Sheet URL 형식이 올바르지 않습니다.');
    }

    final sheetId = segments[indexOfD + 1];
    var gid = original.queryParameters['gid'];
    if ((gid == null || gid.isEmpty) && original.fragment.isNotEmpty) {
      final match = RegExp(r'gid=(\d+)').firstMatch(original.fragment);
      gid = match?.group(1);
    }

    return Uri.https(
      'docs.google.com',
      '/spreadsheets/d/$sheetId/export',
      <String, String>{
        'format': 'csv',
        'gid': gid?.isNotEmpty == true ? gid! : '0',
      },
    );
  }

  String _normalizeKey(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');
  }
}
