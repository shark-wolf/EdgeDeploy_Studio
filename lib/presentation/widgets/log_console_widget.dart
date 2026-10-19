// ==============================================================================
// 所属模块: Presentation / Widgets
// 文件路径: lib/presentation/widgets/log_console_widget.dart
// 核心职责: 用于展示 wrangler 实时输出日志的现代化深色终端控制台组件
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/log_provider.dart';

class LogConsoleWidget extends ConsumerWidget {
  const LogConsoleWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logContent = ref.watch(logProvider);
    final scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '终端实时输出 (Console Output)',
                style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
              IconButton(
                icon: const Icon(Icons.cleaning_services,
                    size: 16, color: Colors.grey),
                tooltip: '清空控制台',
                onPressed: () => ref.read(logProvider.notifier).clearLogs(),
              ),
            ],
          ),
          const Divider(color: Colors.grey),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: SelectableText(
                logContent,
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
