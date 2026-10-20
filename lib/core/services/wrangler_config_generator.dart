// ==============================================================================
// 文件路径: lib/core/services/wrangler_config_generator.dart
// 核心职责: 静态行为分析 Worker 入口代码，精准识别真实绑定，生成零冗余临时配置
// ==============================================================================

import 'dart:io';

class WranglerConfigGenerator {
  /// 检测项目是否存在 wrangler.toml，若无则智能分析代码生成临时配置
  static Future<bool> ensureTomlExists({
    required String projectDir,
    required String workerName,
  }) async {
    final tomlFile = File('$projectDir/wrangler.toml');

    // 如果用户已有 wrangler.toml，直接跳过
    if (await tomlFile.exists()) {
      return false;
    }

    // 自动寻找常见的 JS/TS 入口文件
    final possibleEntries = [
      'src/index.ts',
      'src/index.js',
      'index.ts',
      'index.js',
      'src/worker.ts',
      'src/worker.js',
    ];

    File? entryFile;
    String mainEntry = 'src/index.js'; // 默认兜底入口

    for (final relativePath in possibleEntries) {
      final file = File('$projectDir/$relativePath');
      if (await file.exists()) {
        entryFile = file;
        mainEntry = relativePath;
        break;
      }
    }

    final Set<String> kvBindings = {};
    final Set<String> d1Bindings = {};
    final Set<String> r2Bindings = {};

    // 智能行为分析：通过检查代码中的方法调用来判定是否为真实的云端资源绑定
    if (entryFile != null && await entryFile.exists()) {
      final code = await entryFile.readAsString();

      // 1. 识别 KV 绑定: 必须伴随 .get(, .put(, .delete(, .list( 方法调用
      for (final m
          in RegExp(r'env\.([a-zA-Z0-9_]+)\s*\.\s*(get|put|delete|list)\s*\(')
              .allMatches(code)) {
        final bindingName = m.group(1)!;
        if (!_isCommonKeyword(bindingName)) {
          // 如果是 R2 特征名字，可选择性跳过或归入 R2，此处优先判为 KV
          kvBindings.add(bindingName);
        }
      }

      // 2. 识别 D1 数据库绑定: 必须伴随 .prepare( 方法调用
      for (final m in RegExp(r'env\.([a-zA-Z0-9_]+)\s*\.\s*prepare\s*\(')
          .allMatches(code)) {
        final bindingName = m.group(1)!;
        if (!_isCommonKeyword(bindingName)) {
          d1Bindings.add(bindingName);
        }
      }

      // 3. 识别 R2 存储桶绑定: 名字包含 bucket 或 r2 且有 get/put 操作
      for (final m in RegExp(
              r'env\.([a-zA-Z0-9_]*(BUCKET|R2|STORAGE)[a-zA-Z0-9_]*)\s*\.\s*(get|put|delete)\s*\(',
              caseSensitive: false)
          .allMatches(code)) {
        final bindingName = m.group(1)!;
        r2Bindings.add(bindingName);
        // 从 kvBindings 中剔除（防止重复归类）
        kvBindings.remove(bindingName);
      }
    }

    // 拼接临时 wrangler.toml 内容（无绑定时保持绝对干净，杜绝虚假 ID 提示）
    final buffer = StringBuffer();
    buffer.writeln('# --------------------------------------------------');
    buffer.writeln('# [EdgeDeploy Studio] 智能生成的临时配置文件');
    buffer.writeln('# --------------------------------------------------');
    buffer.writeln('name = "$workerName"');
    buffer.writeln('main = "$mainEntry"');
    buffer.writeln('compatibility_date = "2026-01-01"');
    buffer.writeln();

    if (kvBindings.isNotEmpty) {
      buffer.writeln('kv_namespaces = [');
      for (final b in kvBindings) {
        buffer.writeln('  { binding = "$b", id = "AUTO_DETECTED_KV_ID" },');
      }
      buffer.writeln(']');
      buffer.writeln();
    }

    if (d1Bindings.isNotEmpty) {
      buffer.writeln('d1_databases = [');
      for (final b in d1Bindings) {
        buffer.writeln(
            '  { binding = "$b", database_name = "AUTO_DB", database_id = "AUTO_D1_ID" },');
      }
      buffer.writeln(']');
      buffer.writeln();
    }

    if (r2Bindings.isNotEmpty) {
      buffer.writeln('r2_buckets = [');
      for (final b in r2Bindings) {
        buffer.writeln('  { binding = "$b", bucket_name = "AUTO_BUCKET" },');
      }
      buffer.writeln(']');
      buffer.writeln();
    }

    await tomlFile.writeAsString(buffer.toString());
    return true;
  }

  /// 过滤内置对象或常用词，避免误伤
  static bool _isCommonKeyword(String name) {
    const keywords = [
      'console',
      'JSON',
      'Math',
      'Object',
      'Array',
      'String',
      'Number',
      'Boolean',
      'Date',
      'Promise',
      'Crypto',
      'Response',
      'Request'
    ];
    return keywords.contains(name);
  }

  /// 安全清理生成的临时 wrangler.toml
  static Future<void> cleanupTempToml(String projectDir) async {
    final tomlFile = File('$projectDir/wrangler.toml');
    if (await tomlFile.exists()) {
      try {
        await tomlFile.delete();
      } catch (_) {
        // 忽略删除异常
      }
    }
  }
}
