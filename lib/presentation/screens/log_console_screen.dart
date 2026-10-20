// ==============================================================================
// 所属模块: Presentation / Screens
// 文件路径: lib/presentation/screens/log_console_screen.dart
// 核心职责: 独立的全局日志控制台页面，支持默认开启、开关切换、清空及文本选中复制
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/log_provider.dart';

class LogConsoleScreen extends ConsumerWidget {
  const LogConsoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logState = ref.watch(logProvider);
    final logNotifier = ref.read(logProvider.notifier);
    final scrollController = ScrollController();

    // 当有新日志时自动滚动到底部
    ref.listen(logProvider, (previous, next) {
      if (scrollController.hasClients && next.logs.isNotEmpty) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶栏标题与操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '全局日志控制台',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A)),
                ),
                Row(
                  children: [
                    Row(
                      children: [
                        const Text('启用日志',
                            style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w500)),
                        const SizedBox(width: 8),
                        Switch(
                          value: logState.isEnabled,
                          onChanged: (val) => logNotifier.toggle(val),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () => logNotifier.clear(),
                      icon: const Icon(Icons.delete_sweep, size: 18),
                      label: const Text('清空日志'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade200),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 日志输出显示区域（使用 SelectableText 完美支持鼠标选中与复制）
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A), // 经典暗色控制台背景
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: logState.logs.isEmpty
                    ? const Center(
                        child: Text(
                          '暂无日志输出...',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: logState.logs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: SelectableText(
                              logState.logs[index],
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
