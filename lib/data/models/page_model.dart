// ==============================================================================
// 所属模块: Data / Models
// 文件路径: lib/data/models/page_model.dart
// 核心职责: Cloudflare Pages 项目与部署记录模型
// ==============================================================================

class PageModel {
  final String id;
  final String name;
  final String subdomain;
  final String? latestDeploymentId;

  PageModel({
    required this.id,
    required this.name,
    required this.subdomain,
    this.latestDeploymentId,
  });

  factory PageModel.fromJson(Map<String, dynamic> json) {
    return PageModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '未命名 Pages 项目',
      subdomain: json['subdomain'] as String? ?? '',
      latestDeploymentId: json['latest_deployment']?['id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subdomain': subdomain,
      'latest_deployment_id': latestDeploymentId,
    };
  }
}
