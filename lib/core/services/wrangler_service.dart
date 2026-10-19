// ==============================================================================
// 所属模块: Core / Services
// 文件路径: lib/core/services/wrangler_service.dart
// 核心职责: Wrangler CLI 核心进程包装器，支持授权登录、whoami 校验及正确编码的日志捕获
// ==============================================================================

import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class WranglerService {
  /// 校验本地是否具备 Node.js 及 wrangler 环境
  Future<bool> checkEnvironment() async {
    try {
      final executable = Platform.isWindows ? 'npx.cmd' : 'npx';
      final result = await Process.run(executable, ['wrangler', '--version']);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('[WranglerService] 环境检查失败: $e');
      return false;
    }
  }

  /// 触发 Wrangler 网页端授权登录 (wrangler login)
  Future<bool> login({required void Function(String log) onLog}) async {
    final exitCode = await executeCommand(
      workingDirectory: '.',
      arguments: ['login'],
      onLog: onLog,
    );
    return exitCode == 0;
  }

  /// 检查当前 Wrangler 的登录及账户状态 (wrangler whoami，使用 utf8 防止乱码)
  Future<String> checkWhoAmI() async {
    try {
      final executable = Platform.isWindows ? 'npx.cmd' : 'npx';
      final result = await Process.run(executable, ['wrangler', 'whoami'],
          runInShell: true);

      // 使用 utf8.decode 正确解析标准输出，避免表格边框出现乱码
      String output = '';
      try {
        output = utf8.decode(result.stdout);
      } catch (_) {
        output = result.stdout.toString();
      }

      if (result.exitCode == 0) {
        return output;
      } else {
        return '未检测到有效登录状态，或执行出错:\n$output';
      }
    } catch (e) {
      return '获取账户状态异常: $e';
    }
  }

  /// 异步执行通用 Wrangler 命令，统一使用 utf8 解码实时日志流
  Future<int> executeCommand({
    required String workingDirectory,
    required List<String> arguments,
    required void Function(String log) onLog,
  }) async {
    final isWindows = Platform.isWindows;
    final executable = isWindows ? 'npx.cmd' : 'npx';
    final fullArgs = ['wrangler', ...arguments];

    try {
      onLog('[信息] 正在执行指令: wrangler ${arguments.join(' ')}\n');

      final process = await Process.start(
        executable,
        fullArgs,
        workingDirectory: workingDirectory,
        runInShell: true,
      );

      process.stdout.transform(utf8.decoder).listen((data) {
        onLog(data);
      });

      process.stderr.transform(utf8.decoder).listen((data) {
        onLog('[错误] $data');
      });

      final exitCode = await process.exitCode;
      onLog('\n[信息] 进程执行完毕，退出码: $exitCode\n');
      return exitCode;
    } catch (e) {
      onLog('\n[严重错误] 无法拉起子进程: $e\n');
      return -1;
    }
  }
}
