// ==============================================================================
// 所属模块: Presentation / Screens
// 文件路径: lib/presentation/screens/pages_screen.dart
// 核心职责: Pages 静态资产托管管理、纯 Wrangler 驱动的一键发布
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/services/wrangler_service.dart';
import '../providers/deployment_status_provider.dart';
import '../providers/log_provider.dart';

class PagesScreen extends ConsumerStatefulWidget {
  const PagesScreen({super.key});

  @override
  ConsumerState<PagesScreen> createState() => _PagesScreenState();
}

class _PagesScreenState extends ConsumerState<PagesScreen> {
  final WranglerService _wranglerService = WranglerService();
  final TextEditingController _projectNameController =
      TextEditingController(text: 'my-pages-project');
  final TextEditingController _dirController = TextEditingController(text: '');

  bool _isPublishing = false;
  String? _deletingItemId;

  Future<void> _pickWorkingDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      setState(() {
        _dirController.text = selectedDirectory;
      });
    }
  }

  Future<void> _deployPages() async {
    final projectName = _projectNameController.text.trim();
    final dir = _dirController.text.trim();

    if (projectName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('请输入 Pages 项目名称'), backgroundColor: Colors.orange),
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
          name: projectName,
          type: DeployType.page,
        );

    ref.read(logProvider.notifier).appendLog(
        '\n[开始] 准备发布 Pages 项目: $projectName (依赖 wrangler.toml 配置)...\n');

    try {
      await _wranglerService.executeCommand(
        workingDirectory: dir,
        arguments: [
          'pages',
          'project',
          'create',
          projectName,
          '--production-branch',
          'main'
        ],
        onLog: (log) => ref.read(logProvider.notifier).appendLog(log),
      );

      final args = ['pages', 'deploy', '.', '--project-name', projectName];
      final exitCode = await _wranglerService.executeCommand(
        workingDirectory: dir,
        arguments: args,
        onLog: (log) => ref.read(logProvider.notifier).appendLog(log),
      );

      if (exitCode == 0) {
        ref.read(deploymentStatusProvider.notifier).recordResult(
              id: deployId,
              status: DeployStatus.success,
              message: '发布成功',
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('🌐 Pages [$projectName] 发布成功！'),
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
                content: Text('❌ Pages [$projectName] 发布失败，请查看全局日志控制台'),
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
    final pageItems =
        deployState.items.where((e) => e.type == DeployType.page).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pages 静态资产托管管理',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            const Text(
              '配置并执行 Pages 静态资产托管的分布式发布',
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
                          controller: _projectNameController,
                          decoration: const InputDecoration(
                            labelText: 'Pages 项目名称 (必填)',
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
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isPublishing ? null : _deployPages,
                      icon: _isPublishing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.web, size: 18),
                      label: Text(_isPublishing ? '正在发布 Pages...' : '一键发布page'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
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
                  'Pages 资产发布历史 (${pageItems.length})',
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
              child: pageItems.isEmpty
                  ? const SizedBox(
                      height: 200,
                      child: Center(
                        child: Text('暂无 Pages 发布记录',
                            style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: pageItems.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      itemBuilder: (context, index) {
                        final item = pageItems[index];
                        final statusColor = _getStatusColor(item.status);
                        final isDeletingThis = _deletingItemId == item.id;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 6),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.web,
                                color: Colors.blue, size: 18),
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
                                                '确定要删除 "${item.name}" 吗？\n\n系统将尝试在 Cloudflare 边缘端删除该 Pages 项目。只有边缘端删除成功后才会清理本地记录。'),
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
                                              '\n[开始] 准备从边缘端删除 Pages 项目: ${item.name}...\n');
                                          try {
                                            final remoteSuccess =
                                                await _wranglerService
                                                    .deleteRemotePagesProject(
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
