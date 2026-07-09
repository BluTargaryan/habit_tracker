import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/quote.dart';

/// Shown when the ZenQuotes API is unavailable (offline, timeout, error).
const List<Quote> fallbackQuotes = [
  Quote(text: 'The secret of getting ahead is getting started.', author: 'Mark Twain'),
  Quote(text: 'Small daily improvements are the key to staggering long-term results.',
      author: 'Robin Sharma'),
  Quote(text: 'Discipline is choosing between what you want now and what you want most.',
      author: 'Abraham Lincoln'),
  Quote(text: 'Well begun is half done.', author: 'Aristotle'),
  Quote(text: "You don't have to be great to start, but you have to start to be great.",
      author: 'Zig Ziglar'),
];

class ZenQuotesService {
  static const _endpoint = 'https://zenquotes.io/api/random';

  Future<Quote> fetchRandomQuote() async {
    final response = await http
        .get(Uri.parse(_endpoint))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('ZenQuotes request failed with status ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    final first = decoded.first as Map<String, dynamic>;
    return Quote(text: first['q'] as String, author: first['a'] as String);
  }
}
