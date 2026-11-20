import 'dart:math';
import 'package:dio/dio.dart';
import '../models/todo.dart';

typedef RetryLog = void Function(String message);

/// Short text for an error, used in the retry log.
String describeError(Object e) {
  if (e is DioException) {
    final code = e.response?.statusCode;
    return code != null ? 'HTTP $code' : e.type.name;
  }
  return e.toString();
}

/// Runs [op] up to [maxAttempts] times.
/// The wait grows exponentially (400, 800, 1600, 3200 ms) and a random
/// jitter is added so retries do not line up.
Future<T> withRetry<T>(
    Future<T> Function() op, {
      int maxAttempts = 5,
      int baseMs = 400,
      RetryLog? onLog,
    }) async {
  for (var i = 0; ; i++) {
    final attempt = i + 1;
    try {
      final result = await op();
      onLog?.call('Attempt $attempt/$maxAttempts: OK');
      return result;
    } catch (e) {
      if (attempt == maxAttempts) {
        onLog?.call(
            'Attempt $attempt/$maxAttempts: failed (${describeError(e)}), giving up');
        rethrow;
      }
      final backoff = baseMs * (1 << i);
      final jitter = Random().nextInt(backoff);
      final delay = backoff + jitter;
      onLog?.call(
          'Attempt $attempt/$maxAttempts: failed (${describeError(e)}), '
              'retry in $delay ms ($backoff + $jitter jitter)');
      await Future.delayed(Duration(milliseconds: delay));
    }
  }
}

class TodoApi {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  /// JSON is decoded only here.
  Future<List<Todo>> _fetchOnce(String path) async {
    final res = await _dio.get<dynamic>(path);
    final raw = res.data as List<dynamic>;
    return raw.map((j) => Todo.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<Todo>> fetchTodos({String path = '/todos', RetryLog? onLog}) =>
      withRetry(() => _fetchOnce(path), onLog: onLog);
}