// ==============================================================================
// 所属模块: Presentation / Widgets
// 文件路径: lib/presentation/widgets/sidebar_navigation.dart
// 核心职责: 桌面端侧边栏导航组件（包含 4 个核心导航项及底部退出登录）
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
    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/icons/app_icon.png',
                width: 44,
                height: 44,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'EdgeDeploy',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              tooltip: '退出登录',
              onPressed: onLogout,
            ),
          ),
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('系统概览'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.cloud_upload_outlined),
          selectedIcon: Icon(Icons.cloud_upload),
          label: Text('Workers'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.web_outlined),
          selectedIcon: Icon(Icons.web),
          label: Text('Pages'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.info_outline),
          selectedIcon: Icon(Icons.info),
          label: Text('应用信息'),
        ),
      ],
    );
  }
}
