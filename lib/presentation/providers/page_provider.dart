// ==============================================================================
// 所属模块: Presentation / Providers
// 文件路径: lib/presentation/providers/page_provider.dart
// 核心职责: 管理 Pages 项目状态的 Riverpod 提供者
// ==============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/page_model.dart';

class PageStateNotifier extends StateNotifier<List<PageModel>> {
  PageStateNotifier() : super([]);

  void setPages(List<PageModel> pages) {
    state = pages;
  }
}

final pageProvider =
    StateNotifierProvider<PageStateNotifier, List<PageModel>>((ref) {
  return PageStateNotifier();
});
