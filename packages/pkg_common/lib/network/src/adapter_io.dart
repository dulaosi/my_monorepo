
// IO implementation using dart:io HttpClient
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'types.dart';

class _IoAdapter implements HttpAdapter {
  final HttpClient _client;
  final Duration _defaultTimeout;

  _IoAdapter({Duration? defaultTimeout})
      : _client = HttpClient(),
        _defaultTimeout = defaultTimeout ?? const Duration(seconds: 30);

  @override
  Future<NetworkResponse> send(NetworkRequest request, {void Function(void Function())? registerAbort}) async {
    final timeout = request.timeout ?? _defaultTimeout;

    final HttpClientRequest req = await _client.openUrl(request.method, request.uri);
    // Attach aborter once request exists.
    registerAbort?.call(() {
      try { req.abort(); } catch (_) {}
    });

    // Headers
    request.headers.forEach((k, v) {
      try {
        req.headers.set(k, v);
      } catch (_) {
        // ignore invalid header
      }
    });

    // Body
    if (request.bodyBytes != null && request.bodyBytes!.isNotEmpty) {
      req.add(request.bodyBytes!);
    }

    final HttpClientResponse resp = await req.close().timeout(timeout);

    // Collect bytes
    final builder = BytesBuilder(copy: false);
    await for (final chunk in resp) {
      builder.add(chunk);
    }
    final bodyBytes = builder.toBytes();

    // Headers map (join values by comma)
    final Map<String, String> headers = <String, String>{};
    resp.headers.forEach((name, values) {
      headers[name] = values.join(',');
    });

    return NetworkResponse(
      statusCode: resp.statusCode,
      headers: headers,
      bodyBytes: bodyBytes,
    );
  }

  @override
  void close() {
    _client.close(force: true);
  }
}

HttpAdapter createDefaultAdapter({Duration? defaultTimeout}) => _IoAdapter(defaultTimeout: defaultTimeout);
