import 'dart:convert';

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
  static final List<String> _idCandidates = [
    'id',
    '번호',
    'no',
    '순번',
    'index',
  ];
  static final List<String> _nameCandidates = [
    'name',
    'name_ko',
    'namekr',
    '이름',
    '티니핑',
    '캐릭터',
    '캐릭터명',
  ];
  static final List<String> _imageCandidates = [
    'image',
    'image_url',
    'imageurl',
    'img',
    '이미지',
    '사진',
    '썸네일',
  ];
  static final List<String> _typeCandidates = [
    'type',
    'types',
    '속성',
    '분류',
    '시즌',
  ];
  static final List<String> _descriptionCandidates = [
    'description',
    'quote',
    '설명',
    '소개',
    '특징',
  ];
  static final List<String> _releaseVersionCandidates = [
    'release_version',
    'releaseversion',
    'release',
    'version',
    '시즌',
    '출시',
    '출시버전',
  ];

  @override
  Future<List<Tiniping>> fetchTinipings() async {
    final uri = _buildCsvUri(sheetUrl);
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('시트 데이터를 불러오지 못했습니다. (${response.statusCode})');
    }
    final body = utf8.decode(response.bodyBytes, allowMalformed: true).replaceFirst(
      '\uFEFF',
      '',
    );
    if (body.trimLeft().startsWith('<!DOCTYPE html>')) {
      throw Exception('시트가 공개되지 않았거나 CSV 내보내기가 허용되지 않았습니다.');
    }

    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
    ).convert(body);
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

      final name = pick(_nameCandidates);
      if (name.isEmpty) {
        continue;
      }

      final pickedId = pick(_idCandidates);
      final id = pickedId.isEmpty ? '$i' : pickedId;
      final imageUrl = pick(_imageCandidates);
      final type = pick(_typeCandidates);
      final description = pick(_descriptionCandidates);
      final releaseVersion = pick(_releaseVersionCandidates);

      final extras = <String, String>{};
      final coreFields = {
        ..._idCandidates.map(_normalizeKey),
        ..._nameCandidates.map(_normalizeKey),
        ..._imageCandidates.map(_normalizeKey),
        ..._typeCandidates.map(_normalizeKey),
        ..._descriptionCandidates.map(_normalizeKey),
        ..._releaseVersionCandidates.map(_normalizeKey),
      };
      rowMap.forEach((key, value) {
        if (value.isEmpty) {
          return;
        }
        final normalizedKey = _normalizeKey(key);
        if (!coreFields.contains(normalizedKey)) {
          extras[key] = value;
        }
      });

      items.add(
        Tiniping(
          id: id,
          name: name,
          imageUrl: imageUrl,
          type: type,
          releaseVersion: releaseVersion,
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
