// ==============================================================================
// 文件路径: lib/core/services/wrangler_service.dart
// 核心职责: 封装 Wrangler 命令行交互、认证、Worker/Pages 部署与远程管理
// ==============================================================================

import 'dart:convert';
import 'dart:io';
import 'wrangler_config_generator.dart';

class WranglerService {
  /// 执行底层命令（已修复乱码：强制使用 utf8.decoder 解析 Wrangler 输出）
  Future<int> executeCommand({
    required String workingDirectory,
    required List<String> arguments,
    required void Function(String log) onLog,
  }) async {
    try {
      onLog('[信息] 执行指令: npx wrangler@latest ${arguments.join(' ')}\n');

      final process = await Process.start(
        'npx',
        ['wrangler@latest', ...arguments],
        workingDirectory: workingDirectory.isNotEmpty ? workingDirectory : null,
        runInShell: true,
      );

      // 强制使用 UTF-8 解码，彻底解决 Windows 下的中文及 Emoji/框线乱码问题
      process.stdout.transform(utf8.decoder).listen(onLog);
      process.stderr.transform(utf8.decoder).listen(onLog);

      return await process.exitCode;
    } catch (e) {
      onLog('[-] 执行命令出错: $e\n');
      return -1;
    }
  }

  // ==============================================================================
  // 认证与远程管理相关方法
  // ==============================================================================

  /// 检查当前登录状态 (whoami)
  Future<String> checkWhoAmI({void Function(String log)? onLog}) async {
    final buffer = StringBuffer();
    final exitCode = await executeCommand(
      workingDirectory: '',
      arguments: ['whoami'],
      onLog: (log) {
        buffer.write(log);
        onLog?.call(log);
      },
    );
    return exitCode == 0 ? buffer.toString() : '';
  }

  /// 触发浏览器登录 (login)
  Future<bool> login({void Function(String log)? onLog}) async {
    final exitCode = await executeCommand(
      workingDirectory: '',
      arguments: ['login'],
      onLog: onLog ?? (_) {},
    );
    return exitCode == 0;
  }

  /// 获取远程 Pages 项目列表
  Future<List<String>> fetchRemotePagesProjects() async {
    final buffer = StringBuffer();
    final exitCode = await executeCommand(
      workingDirectory: '',
      arguments: ['pages', 'project', 'list'],
      onLog: (log) => buffer.write(log),
    );
    if (exitCode != 0) return [];

    final lines = buffer.toString().split('\n');
    List<String> projects = [];
    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty &&
          !trimmed.contains('Projects') &&
          !trimmed.contains('---')) {
        final parts = trimmed.split(RegExp(r'\s+'));
        if (parts.isNotEmpty && parts[0].isNotEmpty) {
          projects.add(parts[0]);
        }
      }
    }
    return projects;
  }

  /// 检查远程 Worker 是否存在
  Future<bool> checkRemoteWorkerExists(String workerName) async {
    final exitCode = await executeCommand(
      workingDirectory: '',
      arguments: ['subdomain', 'show'],
      onLog: (_) {},
    );
    return exitCode == 0;
  }

  /// 删除远程 Worker
  Future<bool> deleteRemoteWorker(
    String workerName, {
    String? workingDirectory,
    void Function(String log)? onLog,
  }) async {
    final exitCode = await executeCommand(
      workingDirectory: workingDirectory ?? '',
      arguments: ['delete', '--name', workerName, '--force'],
      onLog: onLog ?? (_) {},
    );
    return exitCode == 0;
  }

  /// 删除远程 Pages 项目
  Future<bool> deleteRemotePagesProject(
    String projectName, {
    void Function(String log)? onLog,
  }) async {
    final exitCode = await executeCommand(
      workingDirectory: '',
      arguments: ['pages', 'project', 'delete', projectName, '--yes'],
      onLog: onLog ?? (_) {},
    );
    return exitCode == 0;
  }

  // ==============================================================================
  // 核心部署相关方法（集成智能配置生成与清理）
  // ==============================================================================

  /// 部署 Worker（智能防污染：无 wrangler.toml 时行为分析自动生成，发布后强制 finally 安全清理）
  Future<int> deployWorker({
    required String projectDir,
    required String workerName,
    required void Function(String log) onLog,
  }) async {
    bool isTempTomlCreated = false;

    try {
      onLog('[*] 正在准备部署 Worker: $workerName\n');

      // 1. 智能检测并按需动态生成临时 wrangler.toml
      isTempTomlCreated = await WranglerConfigGenerator.ensureTomlExists(
        projectDir: projectDir,
        workerName: workerName,
      );

      if (isTempTomlCreated) {
        onLog('[*] 检测到项目缺少 wrangler.toml，已通过智能行为分析动态挂载临时配置。\n');
      }

      // 2. 调用 Wrangler 执行发布
      final exitCode = await executeCommand(
        workingDirectory: projectDir,
        arguments: ['deploy'],
        onLog: onLog,
      );

      return exitCode;
    } catch (e) {
      onLog('[-] 部署 Worker 出现异常: $e\n');
      return -1;
    } finally {
      // 3. ★ 核心保障：无论部署成功还是崩溃抛错，只要是临时生成的，必定在此安全清理
      if (isTempTomlCreated) {
        onLog('[*] 正在清理临时生成的 wrangler.toml...\n');
        await WranglerConfigGenerator.cleanupTempToml(projectDir);
        onLog('[*] 临时配置文件已清除，源码目录保持绝对干净。\n');
      }
    }
  }

  /// 部署 Pages 项目（Pages 无需 toml，直接通过命令行产物路径发布）
  Future<int> deployPages({
    required String projectDir,
    required String outputDir,
    required String projectName,
    required void Function(String log) onLog,
  }) async {
    final targetOutput = outputDir.isNotEmpty ? outputDir : './dist';
    onLog('[*] 正在发布 Pages 项目: $projectName (产物目录: $targetOutput)...\n');

    return await executeCommand(
      workingDirectory: projectDir,
      arguments: [
        'pages',
        'deploy',
        targetOutput,
        '--project-name=$projectName',
        '--commit-dirty=true'
      ],
      onLog: onLog,
    );
  }
}
