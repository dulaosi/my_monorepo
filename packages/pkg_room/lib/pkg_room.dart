library pkg_room;
// 2. 导出你想公开的文件
export 'src/room_main.dart'; 
// 注意：如果你只想导出某个文件里的特定类，可以写：
// export 'src/login_widgets.dart' show LoginPage;

// 3. 不要导出 private_tool.dart
// 这样另外两位同事在他们的模块里，就永远搜不到你的私有工具类