// ==============================================================================
// 所属模块: Presentation / App Entry
// 文件路径: lib/main.dart
// 核心职责: EdgeDeploy-Studio 应用程序的绝对入口，包裹 ProviderScope 启动状态管理
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 启动带有 Riverpod 全局状态容器的应用
  runApp(
    const ProviderScope(
      child: EdgeDeployApp(),
    ),
  );
}
