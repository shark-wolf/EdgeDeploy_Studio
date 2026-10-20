// ==============================================================================
// 所属模块: Core / Services
// 文件路径: lib/core/services/wrangler_service.dart
// 核心职责: 纯 Wrangler 命令行封装，包含登录、命令执行、Worker/Pages 部署及带智能容错的远端删除
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

  /// 从边缘端删除指定 Worker（智能容错：404/不存在时自动清理本地；绑定域名/路由时安全拦截）
  Future<bool> deleteRemoteWorker(String workerName,
      {required void Function(String log) onLog}) async {
    try {
      onLog('[信息] 正在请求边缘端删除 Worker: $workerName\n');

      final process = await Process.start(
        'npx',
        ['wrangler', 'delete', workerName, '--force'],
        runInShell: true,
      );

      final stderrBuffer = StringBuffer();

      process.stdout.transform(utf8.decoder).listen((data) {
        onLog(data);
      });

      process.stderr.transform(utf8.decoder).listen((data) {
        stderrBuffer.write(data);
        onLog('[错误] $data');
      });

      final exitCode = await process.exitCode;

      if (exitCode == 0) {
        return true;
      }

      final errOutput = stderrBuffer.toString().toLowerCase();

      // 1. 容错兜底：若远端资源已不存在，视作成功以清理本地僵尸记录
      if (errOutput.contains('not found') ||
          errOutput.contains('does not exist') ||
          errOutput.contains('could not find') ||
          errOutput.contains('no worker') ||
          errOutput.contains('does not exist on your account') ||
          errOutput.contains('404')) {
        onLog('[警告] 边缘端未找到该 Worker（可能已被删除），将同步清理本地记录。\n');
        return true;
      }

      // 2. 安全拦截：检测是否有未解除的自定义域名或路由绑定
      if (errOutput.contains('custom domain') ||
          errOutput.contains('custom domains') ||
          errOutput.contains('route')) {
        onLog(
            '[错误] ❌ 边缘端删除被拒绝：该 Worker 仍绑定有自定义域名或路由规则。请先前往 Cloudflare 网页后台解除绑定后重试。\n');
      } else {
        onLog('[错误] ❌ 边缘端 API 删除失败，请检查上方具体的 Cloudflare 错误日志。\n');
      }

      return false;
    } catch (e) {
      onLog('[异常] 删除 Worker 出错: $e\n');
      return false;
    }
  }

  /// 从边缘端删除指定 Pages 项目（使用 --yes 跳过交互；智能容错与安全拦截）
  Future<bool> deleteRemotePagesProject(String projectName,
      {required void Function(String log) onLog}) async {
    try {
      onLog('[信息] 正在请求边缘端删除 Pages 项目: $projectName\n');

      final process = await Process.start(
        'npx',
        ['wrangler', 'pages', 'project', 'delete', projectName, '--yes'],
        runInShell: true,
      );

      final stderrBuffer = StringBuffer();

      process.stdout.transform(utf8.decoder).listen((data) {
        onLog(data);
      });

      process.stderr.transform(utf8.decoder).listen((data) {
        stderrBuffer.write(data);
        onLog('[错误] $data');
      });

      final exitCode = await process.exitCode;

      if (exitCode == 0) {
        return true;
      }

      final errOutput = stderrBuffer.toString().toLowerCase();

      // 1. 容错兜底：若远端项目已不存在，视作成功以清理本地僵尸记录
      if (errOutput.contains('not found') ||
          errOutput.contains('does not exist') ||
          errOutput.contains('could not find') ||
          errOutput.contains('404')) {
        onLog('[警告] 边缘端未找到该 Pages 项目（可能已被删除），将同步清理本地记录。\n');
        return true;
      }

      // 2. 安全拦截：检测自定义域名绑定或部署版本过多拦截
      if (errOutput.contains('custom domain') ||
          errOutput.contains('custom domains')) {
        onLog(
            '[错误] ❌ 边缘端删除被拒绝：该 Pages 项目仍绑定有自定义域名。请先前往 Cloudflare 网页后台解除域名绑定后重试。\n');
      } else if (errOutput.contains('deployments')) {
        onLog('[错误] ❌ 边缘端删除被拒绝：该 Pages 项目的历史部署版本过多，请先清理旧部署。\n');
      } else {
        onLog('[错误] ❌ 边缘端 API 删除失败，请检查上方具体的 Cloudflare 错误日志。\n');
      }

      return false;
    } catch (e) {
      onLog('[异常] 删除 Pages 项目出错: $e\n');
      return false;
    }
  }
}
