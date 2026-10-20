// ==============================================================================
// 所属模块: Core / Services
// 文件路径: lib/core/services/wrangler_service.dart
// 核心职责: 封装 Wrangler CLI 进程调用、授权登录、环境检查、边缘资产拉取与带日志输出的边缘端删除
// ==============================================================================

import 'dart:convert';
import 'dart:io';

class WranglerService {
  /// 执行 Wrangler 独立授权登录 (wrangler login)
  Future<bool> login({required void Function(String log) onLog}) async {
    try {
      final executable = Platform.isWindows ? 'npx.cmd' : 'npx';
      onLog('[信息] 正在唤起浏览器执行 Wrangler 授权登录...\n');

      final process = await Process.start(
        executable,
        ['wrangler', 'login'],
        runInShell: true,
      );

      process.stdout.transform(utf8.decoder).listen((data) {
        onLog(data);
      });

      process.stderr.transform(utf8.decoder).listen((data) {
        onLog('[错误] $data');
      });

      final exitCode = await process.exitCode;
      onLog('\n[信息] 登录进程结束，退出码: $exitCode\n');
      return exitCode == 0;
    } catch (e) {
      onLog('\n[异常] 登录调用失败: $e\n');
      return false;
    }
  }

  /// 获取云端 Pages 项目名称列表
  Future<List<String>> fetchRemotePagesProjects() async {
    try {
      final executable = Platform.isWindows ? 'npx.cmd' : 'npx';
      final result = await Process.run(
        executable,
        ['wrangler', 'pages', 'project', 'list', '--json'],
        runInShell: true,
        stdoutEncoding: null,
        stderrEncoding: null,
      );

      final stdoutStr = result.stdout is List<int>
          ? utf8.decode(result.stdout as List<int>, allowMalformed: true)
          : result.stdout.toString();

      if (result.exitCode == 0 && stdoutStr.trim().isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(stdoutStr);
        return jsonList
            .map((e) =>
                e['name']?.toString() ?? e['Project Name']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// 检查指定 Worker 在云端边缘是否存在部署记录
  Future<bool> checkRemoteWorkerExists(String workerName) async {
    try {
      final executable = Platform.isWindows ? 'npx.cmd' : 'npx';
      final result = await Process.run(
        executable,
        ['wrangler', 'deployments', 'list', '--name', workerName, '--json'],
        runInShell: true,
        stdoutEncoding: null,
        stderrEncoding: null,
      );

      final stdoutStr = result.stdout is List<int>
          ? utf8.decode(result.stdout as List<int>, allowMalformed: true)
          : result.stdout.toString();

      if (result.exitCode == 0 && stdoutStr.trim().isNotEmpty) {
        final decoded = jsonDecode(stdoutStr);
        if (decoded is List && decoded.isNotEmpty) {
          return true;
        } else if (decoded is Map && decoded.containsKey('deployments')) {
          final list = decoded['deployments'];
          return list is List && list.isNotEmpty;
        }
      }
    } catch (_) {}
    return false;
  }

  /// 从边缘端删除指定 Worker（支持日志流式输出）
  Future<bool> deleteRemoteWorker(String workerName,
      {required void Function(String log) onLog}) async {
    final exitCode = await executeCommand(
      workingDirectory: '',
      arguments: ['delete', workerName, '--force'],
      onLog: onLog,
    );
    return exitCode == 0;
  }

  /// 从边缘端删除指定 Pages 项目（支持日志流式输出）
  Future<bool> deleteRemotePagesProject(String projectName,
      {required void Function(String log) onLog}) async {
    final exitCode = await executeCommand(
      workingDirectory: '',
      arguments: ['pages', 'project', 'delete', projectName],
      onLog: onLog,
    );
    return exitCode == 0;
  }

  /// 检查当前 Wrangler 授权状态（whoami）
  Future<String> checkWhoAmI() async {
    try {
      final executable = Platform.isWindows ? 'npx.cmd' : 'npx';
      final result = await Process.run(
        executable,
        ['wrangler', 'whoami'],
        runInShell: true,
        stdoutEncoding: null,
        stderrEncoding: null,
      );

      final stdoutStr = result.stdout is List<int>
          ? utf8.decode(result.stdout as List<int>, allowMalformed: true)
          : result.stdout.toString();
      final stderrStr = result.stderr is List<int>
          ? utf8.decode(result.stderr as List<int>, allowMalformed: true)
          : result.stderr.toString();

      if (result.exitCode == 0) {
        return stdoutStr.trim();
      } else {
        return '未授权或未登录 (${stderrStr.isNotEmpty ? stderrStr.trim() : stdoutStr.trim()})';
      }
    } catch (e) {
      return 'Wrangler 环境检查异常: $e';
    }
  }

  /// 执行通用 Wrangler 异步指令（实时输出日志）
  Future<int> executeCommand({
    required String workingDirectory,
    required List<String> arguments,
    required void Function(String log) onLog,
  }) async {
    try {
      final executable = Platform.isWindows ? 'npx.cmd' : 'npx';
      onLog('[信息] 正在执行指令: wrangler ${arguments.join(' ')}\n');

      final process = await Process.start(
        executable,
        ['wrangler', ...arguments],
        workingDirectory: workingDirectory.isEmpty ? '.' : workingDirectory,
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
      onLog('\n[异常] 进程启动失败: $e\n');
      return -1;
    }
  }
}
