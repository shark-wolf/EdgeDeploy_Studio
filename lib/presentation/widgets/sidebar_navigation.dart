// ==============================================================================
// 所属模块: Presentation / Widgets
// 文件路径: lib/presentation/widgets/sidebar_navigation.dart
// 核心职责: 左侧导航栏，集成系统各功能模块跳转入口（修复 onTap 属性）
// ==============================================================================

import 'package:flutter/material.dart';

class SidebarNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onLogout;

  const SidebarNavigation({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.cloud_queue,
                      color: Colors.blue, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'EdgeDeploy',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildNavItem(
                    index: 0, icon: Icons.dashboard_outlined, label: '系统概览'),
                const SizedBox(height: 4),
                _buildNavItem(index: 1, icon: Icons.bolt, label: 'Workers 管理'),
                const SizedBox(height: 4),
                _buildNavItem(index: 2, icon: Icons.web, label: 'Pages 管理'),
                const SizedBox(height: 4),
                _buildNavItem(index: 3, icon: Icons.terminal, label: '日志控制台'),
                const SizedBox(height: 4),
                _buildNavItem(
                    index: 4, icon: Icons.info_outline, label: '关于系统'),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onLogout,
                icon:
                    const Icon(Icons.logout, size: 18, color: Colors.redAccent),
                label: const Text('退出登录',
                    style: TextStyle(color: Colors.redAccent)),
                style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      {required int index, required IconData icon, required String label}) {
    final isSelected = currentIndex == index;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => onDestinationSelected(index), // 修复：InkWell 属性名为 onTap
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color:
                    isSelected ? Colors.blue.shade700 : const Color(0xFF64748B),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.blue.shade700
                      : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
