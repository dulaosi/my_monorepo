import 'package:flutter/material.dart';
import 'package:pkg_common/pkg_common.dart';

/// 一个最简“登录示例”页面：只演示点击按钮发起一次网络请求并展示结果。
///
/// 说明：
/// - 为了保证示例可运行，这里使用了 jsonplaceholder 的公开测试接口。
/// - 真正接入业务时，改造 baseUrl 和 path 即可。
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final NetworkClient _client;
  final _username = TextEditingController(text: 'demo');
  final _password = TextEditingController(text: '123456');
  CancelToken? _cancelToken;
  bool _loading = false;
  String? _result;

  @override
  void initState() {
    super.initState();
    _client = NetworkClient(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      timeout: const Duration(seconds: 15),
      enableLog: true,
    );
  }

  @override
  void dispose() {
    _cancelToken?.cancel('dispose');
    _client.close();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _result = null;
    });
    final token = CancelToken();
    _cancelToken = token;
    try {
      // 这里用 POST /posts 作为模拟登录请求
      final resp = await _client.post(
        '/posts',
        data: {
          'username': _username.text,
          'password': _password.text,
        },
        cancelToken: token,
      );
      if (!mounted) return;
      setState(() {
        if (resp.ok) {
          _result = resp.bodyAsString();
        } else {
          _result = 'HTTP ' + resp.statusCode.toString() + '\n' + resp.bodyAsString();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _result = '请求失败: ' + e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _onCancel() {
    _cancelToken?.cancel('user cancel');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('登录示例')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _username,
              decoration: const InputDecoration(labelText: '用户名'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: '密码'),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _onLogin,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('登录'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _loading ? _onCancel : null,
                  child: const Text('取消'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_result ?? '点击登录查看请求结果……'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
