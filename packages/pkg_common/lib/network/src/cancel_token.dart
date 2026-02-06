
/// CancelToken allows a caller to cancel an in-flight request.
class CancelToken {
  bool _isCanceled = false;
  void Function()? _onCancel;
  Object? _reason;

  bool get isCanceled => _isCanceled;
  Object? get reason => _reason;

  /// Register a callback that will be invoked when [cancel] is called.
  /// If already canceled, the callback is called immediately.
  void onCancellable(void Function() cb) {
    if (_isCanceled) {
      try { cb(); } catch (_) {}
    } else {
      _onCancel = cb;
    }
  }

  void cancel([Object? reason]) {
    if (_isCanceled) return;
    _isCanceled = true;
    _reason = reason;
    final cb = _onCancel;
    if (cb != null) {
      try { cb(); } catch (_) {}
    }
    _onCancel = null;
  }
}
