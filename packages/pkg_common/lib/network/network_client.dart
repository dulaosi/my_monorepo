
// network client for pkg_common

import 'dart:convert';
import 'dart:typed_data';

import 'src/cancel_token.dart';
import 'src/types.dart';
// Conditional adapter selection
import 'src/adapter_stub.dart'
    if (dart.library.io) 'src/adapter_io.dart'
    if (dart.library.html) 'src/adapter_web.dart';

/// 轻量网络客户端，仅使用 Dart/Flutter 自带库实现。
/// - 支持 GET/POST/PUT/PATCH/DELETE
/// - 支持基础超时、默认 Header、查询参数
/// - 支持取消（CancelToken）
/// - 不引入三方依赖
class NetworkClient {
  final Uri? _baseUri;
  final Map<String, String> _defaultHeaders;
  final Duration _defaultTimeout;
  final HttpAdapter _adapter;
  final bool _enableLog;
  final bool _withCredentials; // Web Only

  NetworkClient({
    String? baseUrl,
    Map<String, String>? defaultHeaders,
    Duration? timeout,
    bool enableLog = false,
    bool withCredentials = false,
  })  : _baseUri = baseUrl == null ? null : Uri.parse(baseUrl),
        _defaultHeaders = Map.unmodifiable(defaultHeaders ?? const {}),
        _defaultTimeout = timeout ?? const Duration(seconds: 30),
        _adapter = createDefaultAdapter(defaultTimeout: timeout),
        _enableLog = enableLog,
        _withCredentials = withCredentials;

  void close() => _adapter.close();

  Future<NetworkResponse> get(
    String path, {
    Map<String, Object?>? query,
    Map<String, String>? headers,
    Duration? timeout,
    CancelToken? cancelToken,
  }) {
    return _send('GET', path, query: query, headers: headers, timeout: timeout, cancelToken: cancelToken);
  }

  Future<NetworkResponse> delete(
    String path, {
    Map<String, Object?>? query,
    Map<String, String>? headers,
    Duration? timeout,
    CancelToken? cancelToken,
  }) {
    return _send('DELETE', path, query: query, headers: headers, timeout: timeout, cancelToken: cancelToken);
  }

  Future<NetworkResponse> post(
    String path, {
    Map<String, Object?>? query,
    Object? data, // Map/List/String/bytes
    Map<String, String>? headers,
    Duration? timeout,
    CancelToken? cancelToken,
  }) {
    return _send('POST', path, query: query, data: data, headers: headers, timeout: timeout, cancelToken: cancelToken);
  }

  Future<NetworkResponse> put(
    String path, {
    Map<String, Object?>? query,
    Object? data,
    Map<String, String>? headers,
    Duration? timeout,
    CancelToken? cancelToken,
  }) {
    return _send('PUT', path, query: query, data: data, headers: headers, timeout: timeout, cancelToken: cancelToken);
  }

  Future<NetworkResponse> patch(
    String path, {
    Map<String, Object?>? query,
    Object? data,
    Map<String, String>? headers,
    Duration? timeout,
    CancelToken? cancelToken,
  }) {
    return _send('PATCH', path, query: query, data: data, headers: headers, timeout: timeout, cancelToken: cancelToken);
  }

  Future<NetworkResponse> _send(
    String method,
    String path, {
    Map<String, Object?>? query,
    Object? data,
    Map<String, String>? headers,
    Duration? timeout,
    CancelToken? cancelToken,
  }) async {
    final uri = _buildUri(path, query);
    final mergedHeaders = <String, String>{}..addAll(_defaultHeaders)..addAll(headers ?? const {});

    Uint8List? bodyBytes;
    // JSON encode for Map/List by default
    if (data != null) {
      if (data is Uint8List) {
        bodyBytes = data;
      } else if (data is List<int>) {
        bodyBytes = Uint8List.fromList(data);
      } else if (data is String) {
        bodyBytes = Uint8List.fromList(utf8.encode(data));
      } else {
        bodyBytes = Uint8List.fromList(utf8.encode(json.encode(data)));
        mergedHeaders.putIfAbsent('Content-Type', () => 'application/json; charset=utf-8');
      }
    }

    final req = NetworkRequest(
      method: method.toUpperCase(),
      uri: uri,
      headers: mergedHeaders,
      bodyBytes: bodyBytes,
      timeout: timeout ?? _defaultTimeout,
      withCredentials: _withCredentials,
    );

    void registerAbort(void Function() aborter) {
      if (cancelToken != null) {
        cancelToken.onCancellable(aborter);
      }
    }

    if (_enableLog) {
      // Very light logging
      // ignore: avoid_print
      print('[Network] => ' + method + ' ' + uri.toString());
    }

    final resp = await _adapter.send(req, registerAbort: registerAbort);

    if (_enableLog) {
      // ignore: avoid_print
      print('[Network] <= ' + resp.statusCode.toString() + ' (' + resp.bodyBytes.length.toString() + 'B)');
    }

    return resp;
  }

  Uri _buildUri(String path, Map<String, Object?>? query) {
    Uri uri;
    final base = _baseUri;
    if (base == null) {
      uri = Uri.parse(path);
    } else {
      uri = base.resolve(path);
    }
    if (query != null && query.isNotEmpty) {
      final qp = <String, String>{};
      query.forEach((k, v) {
        if (v == null) return;
        if (v is String) {
          qp[k] = v;
        } else if (v is num || v is bool) {
          qp[k] = v.toString();
        } else {
          qp[k] = json.encode(v);
        }
      });
      uri = uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...qp,
      });
    }
    return uri;
  }
}
