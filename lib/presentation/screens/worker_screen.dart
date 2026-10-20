// ==============================================================================
// 所属模块: Presentation / Screens
// 文件路径: lib/presentation/screens/worker_screen.dart
// 核心职责: Workers 边缘计算管理、一键发布 (自动维护 wrangler.toml 的 workers_dev 开关)
// ==============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/services/wrangler_service.dart';
import '../providers/deployment_status_provider.dart';
import '../providers/log_provider.dart';

class WorkerScreen extends ConsumerStatefulWidget {
  const WorkerScreen({super.key});

  @override
  ConsumerState<WorkerScreen> createState() => _WorkerScreenState();
}

class _WorkerScreenState extends ConsumerState<WorkerScreen> {
  final WranglerService _wranglerService = WranglerService();
  final TextEditingController _nameController =
      TextEditingController(text: 'my-worker');
  final TextEditingController _dirController = TextEditingController(text: '');
  final TextEditingController _subdomainController =
      TextEditingController(text: '');
  final TextEditingController _mainDomainController =
      TextEditingController(text: 'ccwu.cc');

  bool _isPublishing = false;
  bool _enableWorkersDev = true; // 启用/禁用 .dev 域名开关
  bool _enableCustomDomain = false; // 是否启用自定义域名
  String? _deletingItemId;

  Future<void> _pickWorkingDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      setState(() {
        _dirController.text = selectedDirectory;
      });
    }
  }

  /// 自动修改或写入工作目录下的 wrangler.toml 中的 workers_dev 配置
  Future<void> _updateWranglerToml(
      String dir, String name, bool enableDev) async {
    final separator = Platform.pathSeparator;
    final tomlFile = File('$dir${separator}wrangler.toml');
    try {
      String content = '';
      if (await tomlFile.exists()) {
        content = await tomlFile.readAsString();
        if (content.contains('workers_dev')) {
          content = content.replaceAll(
              RegExp(r'workers_dev\s*=\s*(true|false)', caseSensitive: false),
              'workers_dev = $enableDev');
        } else {
          content += '\nworkers_dev = $enableDev\n';
        }
      } else {
        content =
            'name = "$name"\nmain = "src/index.js"\ncompatibility_date = "2024-01-01"\nworkers_dev = $enableDev\n';
      }
      await tomlFile.writeAsString(content);
    } catch (e) {
      debugPrint('更新 wrangler.toml 失败: $e');
    }
  }

  Future<void> _deployWorker() async {
    final name = _nameController.text.trim();
    final dir = _dirController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('请输入 Worker 名称'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (dir.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('请选择或输入项目工作目录（必选）'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_isPublishing) return;
    setState(() => _isPublishing = true);

    final deployId = ref.read(deploymentStatusProvider.notifier).recordStart(
          name: name,
          type: DeployType.worker,
        );

    ref.read(logProvider.notifier).appendLog(
        '\n[开始] 准备发布 Worker: $name (.dev: ${_enableWorkersDev ? "已启用" : "已禁用"})...\n');

    try {
      // 核心修复：通过修改 wrangler.toml 文件来正确控制 workers.dev 的启用/禁用
      await _updateWranglerToml(dir, name, _enableWorkersDev);

      // 执行标准的 wrangler deploy 命令
      final args = ['deploy', '--name', name];
      final exitCode = await _wranglerService.executeCommand(
        workingDirectory: dir,
        arguments: args,
        onLog: (log) => ref.read(logProvider.notifier).appendLog(log),
      );

      if (exitCode == 0 && _enableCustomDomain) {
        final mainDomain = _mainDomainController.text.trim();
        final subdomain = _subdomainController.text.trim();
        final fullDomain =
            subdomain.isNotEmpty ? '$subdomain.$mainDomain' : mainDomain;
        ref
            .read(logProvider.notifier)
            .appendLog('[信息] 自定义域名绑定准备就绪: $fullDomain\n');
      }

      if (exitCode == 0) {
        ref.read(deploymentStatusProvider.notifier).recordResult(
              id: deployId,
              status: DeployStatus.success,
              message: '发布成功',
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('🚀 Worker [$name] 发布成功！'),
                backgroundColor: Colors.green),
          );
        }
      } else {
        ref.read(deploymentStatusProvider.notifier).recordResult(
              id: deployId,
              status: DeployStatus.failed,
              message: '发布失败 (退出码: $exitCode)',
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('❌ Worker [$name] 发布失败，请查看全局日志控制台'),
                backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      ref.read(deploymentStatusProvider.notifier).recordResult(
            id: deployId,
            status: DeployStatus.failed,
            message: '异常: $e',
          );
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  Color _getStatusColor(DeployStatus status) {
    switch (status) {
      case DeployStatus.deploying:
        return Colors.orange;
      case DeployStatus.success:
        return Colors.green;
      case DeployStatus.failed:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final deployState = ref.watch(deploymentStatusProvider);
    final workerItems =
        deployState.items.where((e) => e.type == DeployType.worker).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Workers 边缘计算管理',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            const Text(
              '配置并执行 Serverless 边缘脚本的分布式发布',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('发布参数配置',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Worker 名称',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _dirController,
                          decoration: InputDecoration(
                            labelText: '项目工作目录 (必选)',
                            hintText: '点击右侧图标选择目录',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.folder_open,
                                  color: Colors.blue),
                              tooltip: '选择工作目录',
                              onPressed: _pickWorkingDirectory,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // .dev 域名开关（状态文字随开关实时变化）
                  SwitchListTile(
                    title: const Text('启用 .dev 域名 (workers.dev)',
                        style: TextStyle(fontSize: 14)),
                    subtitle: Text(
                      _enableWorkersDev
                          ? '当前状态: 已启用 (将自动生成及分发 workers.dev 子域名)'
                          : '当前状态: 已禁用 (不分发 workers.dev 子域名)',
                      style: TextStyle(
                        fontSize: 12,
                        color: _enableWorkersDev
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    value: _enableWorkersDev,
                    onChanged: (val) => setState(() => _enableWorkersDev = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(height: 24),
                  // 自定义域名配置
                  CheckboxListTile(
                    title:
                        const Text('配置自定义域名', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('填写子域名与主域名',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    value: _enableCustomDomain,
                    onChanged: (val) =>
                        setState(() => _enableCustomDomain = val ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_enableCustomDomain) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _subdomainController,
                            decoration: const InputDecoration(
                              labelText: '子域名 (选填)',
                              hintText: '例如: api',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('.',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _mainDomainController,
                            decoration: const InputDecoration(
                              labelText: '主域名',
                              hintText: '例如: ccwu.cc',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isPublishing ? null : _deployWorker,
                      icon: _isPublishing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.bolt, size: 18),
                      label:
                          Text(_isPublishing ? '正在发布 Worker...' : '一键发布worker'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Workers 资产发布历史 (${workerItems.length})',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: workerItems.isEmpty
                  ? const SizedBox(
                      height: 200,
                      child: Center(
                        child: Text('暂无 Workers 发布记录',
                            style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: workerItems.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      itemBuilder: (context, index) {
                        final item = workerItems[index];
                        final statusColor = _getStatusColor(item.status);
                        final isDeletingThis = _deletingItemId == item.id;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 6),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.bolt,
                                color: Colors.orange, size: 18),
                          ),
                          title: Text(item.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF0F172A))),
                          subtitle: Text(
                              '状态: ${item.message}  •  时间: ${item.timestamp}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: statusColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  item.status == DeployStatus.deploying
                                      ? '正在发布'
                                      : item.status == DeployStatus.success
                                          ? '发布成功'
                                          : '发布失败',
                                  style: TextStyle(
                                      color: statusColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: isDeletingThis
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.redAccent))
                                    : const Icon(Icons.delete_outline,
                                        size: 18, color: Colors.redAccent),
                                tooltip: '从边缘端及本地彻底删除',
                                onPressed: _deletingItemId != null
                                    ? null
                                    : () async {
                                        final confirmed =
                                            await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('确认彻底删除资产'),
                                            content: Text(
                                                '确定要删除 "${item.name}" 吗？\n\n系统将尝试在 Cloudflare 边缘端删除该 Worker。只有边缘端删除成功后才会清理本地记录。'),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child: const Text('取消')),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                                style: TextButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.red),
                                                child: const Text('确认删除'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirmed == true &&
                                            context.mounted) {
                                          setState(
                                              () => _deletingItemId = item.id);
                                          ref.read(logProvider.notifier).appendLog(
                                              '\n[开始] 准备从边缘端删除 Worker: ${item.name}...\n');
                                          try {
                                            final remoteSuccess =
                                                await _wranglerService
                                                    .deleteRemoteWorker(
                                              item.name,
                                              onLog: (log) => ref
                                                  .read(logProvider.notifier)
                                                  .appendLog(log),
                                            );

                                            if (context.mounted) {
                                              if (remoteSuccess) {
                                                ref
                                                    .read(
                                                        deploymentStatusProvider
                                                            .notifier)
                                                    .removeItem(item.id);
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content: Text(
                                                          '🗑️ 边缘端删除成功，已同步从本地移除 ${item.name}'),
                                                      backgroundColor:
                                                          Colors.green),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          '❌ 边缘端删除失败，请查看全局日志控制台，本地记录未删除。'),
                                                      backgroundColor:
                                                          Colors.red),
                                                );
                                              }
                                            }
                                          } finally {
                                            if (mounted)
                                              setState(
                                                  () => _deletingItemId = null);
                                          }
                                        }
                                      },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
