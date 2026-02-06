/// pkg_common
library pkg_common;

export 'network/network_client.dart';
export 'network/src/cancel_token.dart';

/// 示例：保留原始 Calculator，避免对依赖方造成破坏。
class Calculator {
  /// Returns [value] plus 1.
  int addOne(int value) => value + 1;
}
