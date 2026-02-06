import 'package:flutter/material.dart';
class SecretInternalWidget extends StatelessWidget {
  const SecretInternalWidget({super.key});

  // 开头带下划线，或者放在 src 且不被 export，外部就无法访问
  @override
  Widget build(BuildContext context) => const Text("内部组件");
}