import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quote.dart';
import '../services/zenquotes_service.dart';

class QuoteProvider extends ChangeNotifier {
  static const _quoteTextKey = 'quote.text';
  static const _quoteAuthorKey = 'quote.author';
  static const _quoteDateKey = 'quote.date';
  static const _refreshCooldown = Duration(seconds: 6);

  final ZenQuotesService _service;
  final DateTime Function() _now;

  QuoteProvider({ZenQuotesService? service, DateTime Function()? now})
      : _service = service ?? ZenQuotesService(),
        _now = now ?? DateTime.now;

  Quote? quote;
  bool isLoading = false;
  String? errorMessage;
  DateTime? _lastFetchAttempt;

  /// Loads the cached quote (today's, if any) without hitting the network.
  /// Safe to call from every screen that shows the quote — a quote already
  /// held in memory (this session) or cached for today is reused as-is.
  Future<void> loadIfNeeded() async {
    if (quote != null) return;

    final prefs = await SharedPreferences.getInstance();
    final today = _dateOnly(_now());
    final cachedDate = prefs.getString(_quoteDateKey);

    if (cachedDate == today) {
      final text = prefs.getString(_quoteTextKey);
      final author = prefs.getString(_quoteAuthorKey);
      if (text != null && author != null) {
        quote = Quote(text: text, author: author);
        notifyListeners();
        return;
      }
    }

    await refresh();
  }

  Future<void> refresh() async {
    final now = _now();
    if (_lastFetchAttempt != null && now.difference(_lastFetchAttempt!) < _refreshCooldown) {
      return;
    }
    _lastFetchAttempt = now;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _service.fetchRandomQuote();
      quote = fetched;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_quoteTextKey, fetched.text);
      await prefs.setString(_quoteAuthorKey, fetched.author);
      await prefs.setString(_quoteDateKey, _dateOnly(now));
    } catch (_) {
      quote ??= fallbackQuotes[now.day % fallbackQuotes.length];
      errorMessage = 'Could not fetch a new quote — showing a saved one instead.';
    }

    isLoading = false;
    notifyListeners();
  }

  String _dateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
