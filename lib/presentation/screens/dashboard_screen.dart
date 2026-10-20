// ==============================================================================
// 所属模块: Presentation / Screens
// 文件路径: lib/presentation/screens/dashboard_screen.dart
// 核心职责: 主控看板，保留发布快捷入口，资产列表采用 Tab 标签页动态切换展示
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/wrangler_service.dart';
import '../providers/deployment_status_provider.dart';
import '../widgets/sidebar_navigation.dart';
import 'worker_screen.dart';
import 'pages_screen.dart';
import 'app_info_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const DashboardScreen({super.key, required this.onLogout});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  void _switchTab(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _currentIndex = index;
    });
  }

  late final List<Widget> _screens = [
    WorkersAndPagesOverviewTab(onNavigate: _switchTab),
    const WorkerScreen(),
    const PagesScreen(),
    const AppInfoScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: Row(
        children: [
          SidebarNavigation(
            currentIndex: _currentIndex,
            onDestinationSelected: (index) {
              FocusManager.instance.primaryFocus?.unfocus();
              setState(() {
                _currentIndex = index;
              });
            },
            onLogout: () {
              FocusManager.instance.primaryFocus?.unfocus();
              widget.onLogout();
            },
          ),
          const VerticalDivider(
              width: 1, thickness: 1, color: Color(0xFFCBD5E1)),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }
}

/// 系统概览视图：快捷入口 + Tab 切换资产列表
class WorkersAndPagesOverviewTab extends ConsumerStatefulWidget {
  final ValueChanged<int> onNavigate;

  const WorkersAndPagesOverviewTab({super.key, required this.onNavigate});

  @override
  ConsumerState<WorkersAndPagesOverviewTab> createState() =>
      _WorkersAndPagesOverviewTabState();
}

class _WorkersAndPagesOverviewTabState
    extends ConsumerState<WorkersAndPagesOverviewTab>
    with SingleTickerProviderStateMixin {
  final WranglerService _wranglerService = WranglerService();
  String _envSummary = '正在加载 Wrangler 运行环境...';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEnvSummary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEnvSummary() async {
    final status = await _wranglerService.checkWhoAmI();
    if (mounted) {
      setState(() {
        if (status.contains('Email:') ||
            status.contains('Token') ||
            status.contains('Account')) {
          _envSummary = '已通过 Wrangler 授权连接';
        } else {
          _envSummary =
              status.length > 50 ? '${status.substring(0, 50)}...' : status;
        }
      });
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
      case DeployStatus.idle:
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final deployState = ref.watch(deploymentStatusProvider);
    final workerItems =
        deployState.items.where((e) => e.type == DeployType.worker).toList();
    final pageItems =
        deployState.items.where((e) => e.type == DeployType.page).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部欢迎标语与环境徽章
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EdgeDeploy-Studio 边缘控制台',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A)),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '多环境分布式发布管理中心',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: Colors.green, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(_envSummary,
                          style: TextStyle(
                              color: Colors.green.shade800,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 保留的发布快捷入口
            const Text(
              '快捷入口',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildShortcutCard(
                    title: '进入 Workers 管理',
                    subtitle: 'Serverless 边缘计算与代理部署',
                    icon: Icons.cloud_upload_outlined,
                    iconColor: Colors.orange,
                    onPressed: () => widget.onNavigate(1),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildShortcutCard(
                    title: '进入 Pages 管理',
                    subtitle: '静态与全栈前端资产托管',
                    icon: Icons.web_outlined,
                    iconColor: Colors.blue,
                    onPressed: () => widget.onNavigate(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 资产列表标题
            const Text(
              '本系统发布资产状态列表',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),

            // Tab 标签页容器
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Column(
                children: [
                  // Tab 头部切换条
                  Container(
                    decoration: const BoxDecoration(
                      border:
                          Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.blue.shade700,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.blue,
                      tabs: [
                        Tab(text: 'Workers 资产 (${workerItems.length})'),
                        Tab(text: 'Pages 资产 (${pageItems.length})'),
                      ],
                    ),
                  ),
                  // Tab 内容视图
                  SizedBox(
                    height: 320,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAssetListView(workerItems, '暂无 Workers 发布记录'),
                        _buildAssetListView(pageItems, '暂无 Pages 发布记录'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetListView(List<DeployedItem> items, String emptyTip) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(emptyTip,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
      itemBuilder: (context, index) {
        final item = items[index];
        final statusColor = _getStatusColor(item.status);
        final isWorker = item.type == DeployType.worker;

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isWorker ? Colors.orange : Colors.blue).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isWorker ? Icons.bolt : Icons.web,
              color: isWorker ? Colors.orange : Colors.blue,
              size: 18,
            ),
          ),
          title: Text(
            item.name,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF0F172A)),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              '状态: ${item.message}  •  时间: ${item.timestamp}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                        color: statusColor, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(
                  item.status == DeployStatus.deploying
                      ? '正在发布'
                      : item.status == DeployStatus.success
                          ? '发布成功'
                          : item.status == DeployStatus.failed
                              ? '发布失败'
                              : '未发布',
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShortcutCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
