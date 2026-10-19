// ==============================================================================
// 所属模块: Data / Models
// 文件路径: lib/data/models/worker_model.dart
// 核心职责: Cloudflare Worker 实体及配置属性模型
// ==============================================================================

class WorkerModel {
  final String id;
  final String name;
  final String? modifiedOn;
  final bool deployedFromScript;

  WorkerModel({
    required this.id,
    required this.name,
    this.modifiedOn,
    this.deployedFromScript = true,
  });

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    return WorkerModel(
      id: json['id'] as String? ?? '',
      name: json['id'] as String? ?? '未命名 Worker',
      modifiedOn: json['modified_on'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'modified_on': modifiedOn,
    };
  }
}
