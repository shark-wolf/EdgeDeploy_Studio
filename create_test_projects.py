# ==============================================================================
# 脚本名称: create_test_projects.py
# 核心职责: 自动生成符合 EdgeDeploy-Studio 标准的 Worker 与 Pages 本地测试项目
# 包含内容:
#   1. test-edge-worker (含 wrangler.toml 及 workers_dev = true 配置, src/index.js)
#   2. test-pages-project (含 wrangler.toml 及 pages_build_output_dir 配置, dist/index.html)
# ==============================================================================

import os

def create_test_projects():
    print("正在创建 EdgeDeploy-Studio 本地测试项目...\n")

    # 1. 创建 Worker 测试项目
    worker_dir = "test-edge-worker"
    os.makedirs(os.path.join(worker_dir, "src"), exist_ok=True)

    worker_toml_path = os.path.join(worker_dir, "wrangler.toml")
    with open(worker_toml_path, "w", encoding="utf-8") as f:
        f.write('''name = "test-edge-worker"
main = "src/index.js"
compatibility_date = "2024-01-01"
# 对应控制台中的 .dev 域名开关状态 (true 启用 / false 禁用)
workers_dev = true
''')

    worker_js_path = os.path.join(worker_dir, "src", "index.js")
    with open(worker_js_path, "w", encoding="utf-8") as f:
        f.write('''export default {
  async fetch(request, env, ctx) {
    return new Response("Hello from EdgeDeploy-Studio Worker (Wrangler Driver)!");
  },
};
''')
    print(f"✅ Worker 测试项目已生成: {os.path.abspath(worker_dir)}")

    # 2. 创建 Pages 测试项目
    pages_dir = "test-pages-project"
    os.makedirs(os.path.join(pages_dir, "dist"), exist_ok=True)

    pages_toml_path = os.path.join(pages_dir, "wrangler.toml")
    with open(pages_toml_path, "w", encoding="utf-8") as f:
        f.write('''name = "test-pages-project"
compatibility_date = "2024-01-01"
# Pages 项目专用的静态资产构建输出目录
pages_build_output_dir = "./dist"
''')

    pages_html_path = os.path.join(pages_dir, "dist", "index.html")
    with open(pages_html_path, "w", encoding="utf-8") as f:
        f.write('''<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <title>Test Pages Project</title>
    <style>
        body { font-family: sans-serif; text-align: center; margin-top: 50px; background-color: #f8fafc; color: #0f172a; }
        h1 { color: #2563eb; }
    </style>
</head>
<body>
    <h1>Hello from EdgeDeploy-Studio Pages!</h1>
    <p>这是一个由纯 Wrangler 驱动托管的静态前端资产页面。</p>
</body>
</html>
''')
    print(f"✅ Pages 测试项目已生成: {os.path.abspath(pages_dir)}")

    print("\n--------------------------------------------------")
    print("准备就绪！您现在可以在 Flutter 客户端中点击文件夹选择器，")
    print(f"分别选中上述两个目录进行一键发布测试。")
    print("--------------------------------------------------")

if __name__ == "__main__":
    create_test_projects()
