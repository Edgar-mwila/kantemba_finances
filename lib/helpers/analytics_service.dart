import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AnalyticsService {
  static const String _apiBase = 'https://your-backend-url.com/api/analytics'; // TODO: Set your backend URL

  static Future<void> logEvent(String event, {Map<String, dynamic>? data}) async {
    await _send('event', {'event': event, 'data': data});
  }

  static Future<void> logError(String error, {String? stack, Map<String, dynamic>? context}) async {
    await _send('error', {'error': error, 'stack': stack, 'context': context});
  }

  static Future<void> logReview(String review, {int? rating, Map<String, dynamic>? user}) async {
    await _send('review', {'review': review, 'rating': rating, 'user': user});
  }

  static Future<void> _send(String type, Map<String, dynamic> payload) async {
    try {
      await http.post(
        Uri.parse(_apiBase),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': type,
          'timestamp': DateTime.now().toIso8601String(),
          ...payload,
        }),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Analytics send failed: $e');
      }
    }
  }

  static void initializeErrorHandling() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      logError(details.exceptionAsString(), stack: details.stack?.toString());
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      logError(error.toString(), stack: stack.toString());
      return true;
    };
  }
} 