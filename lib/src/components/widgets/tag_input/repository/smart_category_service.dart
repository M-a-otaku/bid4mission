// lib/src/services/smart_category_service.dart

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../infrastructure/commons/url_repository.dart';

class SmartCategoryService {

  static Future<List<String>> getSuggestions(String query) async {
    final q = query.trim();
    if (q.isEmpty || q.length < 2) return [];

    try {
      final response = await http.get(UrlRepository.missions);
      if (response.statusCode != 200) return [];

      // decode bytes with UTF-8 to correctly handle Persian characters
      final body = utf8.decode(response.bodyBytes);
      final List<dynamic> missions = jsonDecode(body);

      final Set<String> categories = {};
      final normalizedQuery = _normalizePersian(q).toLowerCase();

      for (final m in missions) {
        try {
          final dynamic rawCat = m['category'];
          if (rawCat == null) continue;
          final catStr = rawCat is String ? rawCat : rawCat.toString();
          final normalizedCat = _normalizePersian(catStr).toLowerCase();

          if (normalizedCat.contains(normalizedQuery) || _fuzzyMatch(normalizedQuery, normalizedCat)) {
            categories.add(catStr.trim());
          }
        } catch (_) {
          // skip malformed entries
          continue;
        }
      }

      final List<String> result = categories.toList()..sort();
      return result;
    } catch (e) {
      return [];
    }
  }

  /// Fetch all unique categories from the missions endpoint.
  /// This reads the missions JSON and extracts the `category` field
  /// (robust to nulls and non-string values), normalizes Persian
  /// characters and returns a sorted list of unique category strings.
  static Future<List<String>> getAllCategories() async {
    try {
      final response = await http.get(UrlRepository.missions);
      if (response.statusCode != 200) return [];

      final body = utf8.decode(response.bodyBytes);
      final List<dynamic> missions = jsonDecode(body);

      final Set<String> categories = {};
      for (final m in missions) {
        try {
          final dynamic rawCat = m['category'];
          if (rawCat == null) continue;
          final catStr = rawCat is String ? rawCat : rawCat.toString();
          categories.add(catStr.trim());
        } catch (_) {
          continue;
        }
      }

      final List<String> result = categories.toList()..sort();
      return result;
    } catch (_) {
      return [];
    }
  }

  // normalize common Arabic/Persian variants so matching works reliably
  static String _normalizePersian(String s) {
    if (s.isEmpty) return s;
    return s
        .replaceAll('\u064A', '\u06CC') // Arabic Yeh -> Farsi Yeh (ي -> ی)
        .replaceAll('\u0643', '\u06A9') // Arabic Kaf -> Farsi Kaf (ك -> ک)
        .replaceAll('ي', 'ی')
        .replaceAll('ك', 'ک')
        .replaceAll(RegExp(r"\s+"), ' ')
        .trim();
  }

  // simple fuzzy match
  static bool _fuzzyMatch(String input, String target) {
    if (input.length > target.length) return false;
    int i = 0, j = 0;
    while (i < input.length && j < target.length) {
      if (input[i] == target[j]) i++;
      j++;
    }
    return i == input.length;
  }
}