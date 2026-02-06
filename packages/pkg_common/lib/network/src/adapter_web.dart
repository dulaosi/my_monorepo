// Web implementation using dart:html HttpRequest
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'types.dart';

class _WebAdapter implements HttpAdapter {
  final Duration _defaultTimeout;
  _WebAdapter({Duration? defaultTimeout})
      : _defaultTimeout = defaultTimeout ?? const Duration(seconds: 30);

  @override
  Future<NetworkResponse> send(NetworkRequest request, {void Function(void Function())? registerAbort}) async {
    final timeout = request.timeout ?? _defaultTimeout;
    final c = Completer<NetworkResponse>();

    final xhr = html.HttpRequest();
    bool completed = false;

    void completeOnce(FutureOr<NetworkResponse> value) {
      if (completed) return;
      completed = true;
      c.complete(value);
    }

    void completeErrorOnce(Object error) {
      if (completed) return;
      completed = true;
      c.completeError(error);
    }

    // Open
    xhr.open(request.method, request.uri.toString());

    // Timeout
    xhr.timeout = timeout.inMilliseconds;

    // Headers
    request.headers.forEach((k, v) {
      try { xhr.setRequestHeader(k, v); } catch (_) {}
    });

    // Credentials
    xhr.withCredentials = request.withCredentials;

    // Abort support
    registerAbort?.call(() {
      try { xhr.abort(); } catch (_) {}
    });

    xhr.onTimeout.listen((_) {
      completeErrorOnce(TimeoutException('Request timed out', timeout));
      try { xhr.abort(); } catch (_) {}
    });

    xhr.onError.listen((_) {
      completeErrorOnce(StateError('Network error'));
    });

    xhr.onAbort.listen((_) {
      completeErrorOnce(StateError('Aborted'));
    });

    xhr.onLoadEnd.listen((_) {
      try {
        final status = xhr.status ?? 0;
        final headers = <String, String>{};
        // Parse raw headers
        final raw = xhr.getAllResponseHeaders();
        if (raw.isNotEmpty) {
          for (final line in raw.split('\n')) {
            final idx = line.indexOf(':');
            if (idx > 0) {
              final name = line.substring(0, idx).trim();
              final value = line.substring(idx + 1).trim();
              headers[name] = value;
            }
          }
        }
        Uint8List bytes;
        final resp = xhr.response;
        if (resp is String) {
          bytes = Uint8List.fromList(utf8.encode(resp));
        } else if (resp is ByteBuffer) {
          bytes = resp.asUint8List();
        } else {
          // Fallback to responseText
          bytes = Uint8List.fromList(utf8.encode(xhr.responseText ?? ''));
        }
        completeOnce(NetworkResponse(statusCode: status, headers: headers, bodyBytes: bytes));
      } catch (e) {
        completeErrorOnce(e);
      }
    });

    // Send body
    if (request.bodyBytes != null && request.bodyBytes!.isNotEmpty) {
      // Send as text by default
      try {
        xhr.send(utf8.decode(request.bodyBytes!));
      } catch (_) {
        xhr.send(request.bodyBytes);
      }
    } else {
      xhr.send();
    }

    return c.future;
  }

  @override
  void close() {}
}

HttpAdapter createDefaultAdapter({Duration? defaultTimeout}) => _WebAdapter(defaultTimeout: defaultTimeout);
