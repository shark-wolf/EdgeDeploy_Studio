// ==============================================================================
// 文件路径: lib/main.dart
// 核心职责: 应用入口、初始化窗口居中管理器并托管根组件
// ==============================================================================

import 'package:EdgeDeploy_Studio/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  // 必须确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化窗口管理器
  await windowManager.ensureInitialized();

  // 配置窗口启动参数并实现启动时自动居中
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1100, 750), // 默认窗口大小
    minimumSize: Size(900, 600), // 最小窗口限制
    center: true, // ★ 核心：让窗口启动时自动居中
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(
    const ProviderScope(
      child: EdgeDeployApp(),
    ),
  );
}
