
import 'dart:convert';
import 'dart:typed_data';

class NetworkResponse {
  final int statusCode;
  final Map<String, String> headers;
  final Uint8List bodyBytes;

  const NetworkResponse({
    required this.statusCode,
    required this.headers,
    required this.bodyBytes,
  });

  bool get ok => statusCode >= 200 && statusCode < 300;

  String bodyAsString({Encoding encoding = utf8}) => encoding.decode(bodyBytes);

  /// Try to decode body as JSON. Returns  if decode fails.
  dynamic jsonOrNull() {
    try {
      final s = bodyAsString();
      if (s.isEmpty) return null;
      return json.decode(s);
    } catch (_) {
      return null;
    }
  }
}

class NetworkRequest {
  final String method; // e.g. GET/POST/PUT/DELETE/PATCH
  final Uri uri;
  final Map<String, String> headers;
  final Uint8List? bodyBytes;
  final Duration? timeout;
  final bool withCredentials;

  const NetworkRequest({
    required this.method,
    required this.uri,
    this.headers = const {},
    this.bodyBytes,
    this.timeout,
    this.withCredentials = false,
  });
}

/// Base adapter interface.
abstract class HttpAdapter {
  /// [registerAbort] will be called with an aborter callback when the underlying
  /// platform request object has been created. Callers can then wire it to a
  /// [CancelToken].
  Future<NetworkResponse> send(
    NetworkRequest request, {
    void Function(void Function())? registerAbort,
  });
  void close();
}
