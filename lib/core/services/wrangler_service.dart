// ==============================================================================
// 所属模块: Core / Services
// 文件路径: lib/core/services/wrangler_service.dart
// 核心职责: 纯 Wrangler 命令行封装，包含 login、delete、executeCommand 等
// ==============================================================================

import 'dart:convert';
import 'dart:io';

class WranglerService {
  /// 检查 Wrangler 登录状态 (whoami)
  Future<String> checkWhoAmI() async {
    try {
      final result =
          await Process.run('npx', ['wrangler', 'whoami'], runInShell: true);
      if (result.exitCode == 0) {
        return result.stdout.toString();
      } else {
        return '未登录或未授权: ${result.stderr}';
      }
    } catch (e) {
      return '执行异常: $e';
    }
  }

  /// 执行登录指令 (wrangler login)
  Future<bool> login({required void Function(String log) onLog}) async {
    final exitCode = await executeCommand(
      workingDirectory: '',
      arguments: ['login'],
      onLog: onLog,
    );
    return exitCode == 0;
  }

  /// 通用命令执行器（支持实时流式日志输出）
  Future<int> executeCommand({
    required String workingDirectory,
    required List<String> arguments,
    required void Function(String log) onLog,
  }) async {
    try {
      onLog('[信息] 正在执行指令: wrangler ${arguments.join(' ')}\n');

      final process = await Process.start(
        'npx',
        ['wrangler', ...arguments],
        workingDirectory: workingDirectory.isNotEmpty ? workingDirectory : null,
        runInShell: true,
      );

      process.stdout.transform(utf8.decoder).listen((data) {
        onLog(data);
      });

      process.stderr.transform(utf8.decoder).listen((data) {
        onLog('[错误] $data');
      });

      final exitCode = await process.exitCode;
      onLog('[信息] 指令执行结束，退出码: $exitCode\n');
      return exitCode;
    } catch (e) {
      onLog('[异常] 执行出错: $e\n');
      return -1;
    }
  }

  /// 检查远端 Worker 是否存在
  Future<bool> checkRemoteWorkerExists(String workerName) async {
    try {
      final result = await Process.run(
          'npx', ['wrangler', 'secret', 'list', '--name', workerName],
          runInShell: true);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// 获取远端 Pages 项目列表
  Future<List<String>> fetchRemotePagesProjects() async {
    try {
      final result = await Process.run(
          'npx', ['wrangler', 'pages', 'project', 'list'],
          runInShell: true);
      if (result.exitCode == 0) {
        final lines = LineSplitter.split(result.stdout.toString());
        final projects = <String>[];
        for (var line in lines) {
          final trimmed = line.trim();
          if (trimmed.isNotEmpty &&
              !trimmed.startsWith('─') &&
              !trimmed.startsWith('Projects')) {
            final parts = trimmed.split(RegExp(r'\s+'));
            if (parts.isNotEmpty && parts[0] != 'Project') {
              projects.add(parts[0]);
            }
          }
        }
        return projects;
      }
    } catch (_) {}
    return [];
  }

  /// 从边缘端删除指定 Worker
  Future<bool> deleteRemoteWorker(String workerName,
      {required void Function(String log) onLog}) async {
    final exitCode = await executeCommand(
      workingDirectory: '',
      arguments: ['delete', workerName, '--force'],
      onLog: onLog,
    );
    return exitCode == 0;
  }

  /// 从边缘端删除指定 Pages 项目
  Future<bool> deleteRemotePagesProject(String projectName,
      {required void Function(String log) onLog}) async {
    final exitCode = await executeCommand(
      workingDirectory: '',
      arguments: ['pages', 'project', 'delete', projectName, '--force'],
      onLog: onLog, // 修正：直接传递回调函数，而非错误的 ref 调用
    );
    return exitCode == 0;
  }
}
