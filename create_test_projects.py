# ==============================================================================
# 脚本名称: create_test_projects.py
# 核心职责: 在项目根目录下自动生成用于测试 EdgeDeploy-Studio 发布的 Worker 和 Pages 模板项目
# ==============================================================================

import os

def create_test_projects():
    # 1. 创建 Worker 测试项目
    worker_dir = "test-worker"
    src_dir = os.path.join(worker_dir, "src")
    os.makedirs(src_dir, exist_ok=True)

    # 写入 wrangler.toml 配置
    wrangler_toml = '''name = "test-edge-worker"
main = "src/index.js"
compatibility_date = "2026-03-01"
'''
    with open(os.path.join(worker_dir, "wrangler.toml"), "w", encoding="utf-8") as f:
        f.write(wrangler_toml)

    # 写入极简 Worker 入口代码
    worker_js = '''export default {
  async fetch(request, env, ctx) {
    return new Response("Hello from EdgeDeploy-Studio Test Worker! 🚀");
  },
};
'''
    with open(os.path.join(src_dir, "index.js"), "w", encoding="utf-8") as f:
        f.write(worker_js)

    print(f"✅ 成功创建 Worker 测试项目目录: ./{worker_dir}")

    # 2. 创建 Pages 测试项目 (带标准 dist 产物目录)
    pages_dir = "test-pages"
    dist_dir = os.path.join(pages_dir, "dist")
    os.makedirs(dist_dir, exist_ok=True)

    # 写入静态网页产物 index.html
    index_html = '''<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <title>EdgeDeploy-Studio Pages Test</title>
    <style>
        body { font-family: system-ui, sans-serif; text-align: center; padding-top: 100px; background: #FAF9F6; color: #0F172A; }
        h1 { color: #2563EB; }
    </style>
</head>
<body>
    <h1>Hello from EdgeDeploy-Studio Test Pages! 🎉</h1>
    <p>这是一个用于测试 Cloudflare Pages 静态托管一键部署的本地示例页面。</p>
</body>
</html>
'''
    with open(os.path.join(dist_dir, "index.html"), "w", encoding="utf-8") as f:
        f.write(index_html)

    print(f"✅ 成功创建 Pages 测试项目目录: ./{pages_dir} (产物目录: ./{pages_dir}/dist)")

if __name__ == "__main__":
    print("🚀 正在生成 EdgeDeploy-Studio 部署测试项目...")
    create_test_projects()
    print("✨ 生成完毕！您可以在桌面端应用中输入对应的路径进行发布测试。")
