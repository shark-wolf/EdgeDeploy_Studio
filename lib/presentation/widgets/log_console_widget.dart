// ==============================================================================
// 所属模块: Presentation / Widgets
// 文件路径: lib/presentation/widgets/log_console_widget.dart
// 核心职责: 日志输出组件，修复布尔判断类型错误
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/log_provider.dart';

class LogConsoleWidget extends ConsumerWidget {
  const LogConsoleWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logState = ref.watch(logProvider);
    final logNotifier = ref.read(logProvider.notifier);
    final scrollController = ScrollController();

    ref.listen(logProvider, (previous, next) {
      if (scrollController.hasClients && next.logs.isNotEmpty) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '执行日志',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => logNotifier.clear(),
                icon: const Icon(Icons.delete_sweep,
                    size: 14, color: Colors.redAccent),
                label: const Text('清空',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, minimumSize: const Size(50, 24)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: logState.logs.isEmpty // 修复：恢复为正确的 bool 判断
                ? const Center(
                    child: Text('暂无日志...',
                        style: TextStyle(color: Colors.grey, fontSize: 11)))
                : ListView.builder(
                    controller: scrollController,
                    itemCount: logState.logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1.0),
                        child: Text(
                          logState.logs[index],
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
