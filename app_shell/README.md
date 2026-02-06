创建多package流程

1 我们将创建一个名为 my_monorepo 的根目录，里面包含：

app_shell: 壳工程（主 App，负责打包和运行）。

pkg_logic: 登录功能包。

pkg_room: 房间功能包。

pkg_common: 公共组件包（放置公共 UI 和网络请求）。

第一步：创建根目录和基础结构
在你的电脑上创建一个文件夹（不要在 VS Code 里直接 flutter create）：

Bash
mkdir my_monorepo
cd my_monorepo
mkdir packages  # 专门放功能模块
用 VS Code 打开 my_monorepo 文件夹。

第二步：创建各个子项目
打开 VS Code 的终端 (Ctrl + ~)，依次执行以下命令：

Bash
# 1. 创建主 App (壳工程)
flutter create app_shell

# 2. 进入 packages 目录创建功能包
cd packages
flutter create --template=package pkg_common
flutter create --template=package pkg_logic
flutter create --template=package pkg_room
此时你的目录结构应该是：

第三步：配置依赖关系（核心环节）
现在我们需要让它们“打通”。在 VS Code 中分别打开以下文件进行修改：

1. 配置 pkg_logic（它可能需要公共组件）
打开 packages/pkg_logic/pubspec.yaml：

YAML
dependencies:
  flutter:
    sdk: flutter
  pkg_common:
    path: ../pkg_common  # 相对路径引用
2. 配置 app_shell（主项目需要所有模块）
打开 app_shell/pubspec.yaml：

YAML
dependencies:
  flutter:
    sdk: flutter
  pkg_common:
    path: ../packages/pkg_common
  pkg_logic:
    path: ../packages/pkg_logic
  pkg_room:
    path: ../packages/pkg_room
关键动作： 修改完后，在 app_shell 目录下运行 flutter pub get。

第四步：在代码中调用
为了验证是否成功，我们尝试在主项目调用 pkg_logic 的代码。

在 pkg_logic 中写点东西：
打开 packages/pkg_logic/lib/pkg_logic.dart：

Dart
library pkg_logic;
import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("这是登录模块")));
  }
}
在 app_shell 中引用：
打开 app_shell/lib/main.dart，在文件顶部导入：

Dart
import 'package:pkg_logic/pkg_logic.dart'; // 像引用第三方库一样引用它
然后在 build 方法里直接使用 const LoginPage()。

第五步：VS Code 多工作区优化（进阶技巧）
在 VS Code 中，如果你同时打开几十个 Package，侧边栏会很乱。

建议做法：

在根目录创建一个文件叫 my_project.code-workspace。

写入以下内容：

JSON
{
  "folders": [
    { "path": "app_shell" },
    { "path": "packages/pkg_common" },
    { "path": "packages/pkg_logic" },
    { "path": "packages/pkg_room" }
  ]
}
点击 VS Code 右下角的 "Open Workspace"。

效果：VS Code 侧边栏会把这几个项目当作并列的独立项目处理，调试和跳转会非常顺滑，且每个项目都有独立的 Flutter 运行入口。

给三位开发者的协作建议：
开发 A (Auth)：只管 pkg_logic 文件夹。如果需要新按钮，去 pkg_common 提需求或自己改。

开发 B (room)：同理，只管 pkg_room。

公共代码：所有通用的网络封装（Dio）、颜色值、字体全放 pkg_common。

按照最专业的 “出口管理（Encapsulation）” 模式来配置你的 pkg_auth。这种方式能让你的模块看起来就像一个闭源的 SDK，只暴露必须的接口，隐藏复杂的实现细节。

1. 物理目录结构
在 packages/pkg_auth 目录下，按照这个结构组织代码：

Plaintext
pkg_auth/
├── lib/
│   ├── pkg_auth.dart       <-- 【唯一出口文件】
│   └── src/                <-- 【内部实现目录】
│       ├── login_logic.dart
│       ├── login_widgets.dart
│       └── private_tool.dart
└── pubspec.yaml
2. 内部实现（放在 src 文件夹）
在 lib/src/login_widgets.dart 中，你写你的 UI：

Dart
import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Text("登录页"));
}

class _SecretInternalWidget extends StatelessWidget {
  // 开头带下划线，或者放在 src 且不被 export，外部就无法访问
  @override
  Widget build(BuildContext context) => const Text("内部组件");
}
3. 配置出口（修改 lib/pkg_auth.dart）
这是关键的一步。在这个文件里，你决定要把哪些东西“公开”给另外两个同事：

Dart
// lib/pkg_auth.dart

// 1. 声明库名（可选，建议写上以便识别）
library pkg_auth;

// 2. 导出你想公开的文件
export 'src/login_widgets.dart'; 
// 注意：如果你只想导出某个文件里的特定类，可以写：
// export 'src/login_widgets.dart' show LoginPage;

// 3. 不要导出 private_tool.dart
// 这样另外两位同事在他们的模块里，就永远搜不到你的私有工具类
4. 为什么要这么麻烦？（对三人协作的好处）
减少干扰：当开发 B（订单模块）在代码里输入 Log... 时，VS Code 只会提示你导出的 LoginPage。如果他想搜你的 private_tool，编辑器根本不会提示，这能有效防止同事乱用你的内部逻辑。

重构自由：只要你不改 lib/pkg_auth.dart 里的导出类名，你可以随意修改 src/ 目录下的文件名或文件夹结构，而不会破坏其他人的代码。这就像 Android 里的 public 和 private 作用域。

清晰的 API 边界：这也是所有 Flutter 官方插件（比如 provider, dio）的做法。

下一步建议的操作：
现在你可以让三位开发人员按照这个模式，分别在各自的 packages/ 下创建 src 文件夹，并统一通过包名命名的 .dart 文件导出。


外部项目引用方式

  mono_sdk:
    git:
      url: https://github.com/dulaosi/my_monorepo.git
      path: packages/mono_sdk
      ref: mono_sdk_0.0.1  # 只需要指定聚合包的 Tag