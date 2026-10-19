# ==============================================================================
# 所属模块: Tools / Icon Generator
# 文件路径: generate_icon.py
# 核心职责: 使用 Pillow 重新生成带有米白色背景、专业现代风格的 EdgeDeploy-Studio 桌面端应用图标
# ==============================================================================

import os
from pathlib import Path

try:
    from PIL import Image, ImageDraw
except ImportError:
    print("[错误] 未检测到 Pillow 库，请先在终端执行: pip install Pillow")
    exit(1)

def generate_app_icon():
    """
    绘制并生成 EdgeDeploy-Studio 桌面端高级应用图标（米白色背景版）
    设计亮点：柔和高级的米白色圆角底座（#FAF9F6）、标志性流线型橙色云朵、电光蓝边缘计算节点与白色代码符号。
    """
    # 1. 创建图标输出目录
    icon_dir = Path("assets/icons")
    icon_dir.mkdir(parents=True, exist_ok=True)

    # 2. 初始化 1024x1024 超高分辨率画布
    size = 1024
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    # 3. 绘制现代极简圆角方形底座 (Squircle) - 改为柔和高级的米白色 (#FAF9F6)
    margin = 64
    radius = 220
    bg_box = [margin, margin, size - margin, size - margin]

    # 主背景：温润米白色 (#FAF9F6)
    draw.rounded_rectangle(bg_box, radius=radius, fill=(250, 249, 246, 255))
    # 边缘精致边框高亮线（浅灰色轮廓，适配明亮主题 #CBD5E1）
    draw.rounded_rectangle(bg_box, radius=radius, outline=(203, 213, 225, 255), width=8)

    # 4. 精密绘制标志性的流线型蓬松云朵 (Cloudflare Vibrant Orange)
    cloud_color = (249, 115, 22, 255)

    # 组合多层饱满的圆弧与基础底块，精准打造云朵的自然形态
    # 左侧小云团
    draw.ellipse([270, 440, 450, 620], fill=cloud_color)
    # 顶部中心大云团
    draw.ellipse([380, 320, 630, 570], fill=cloud_color)
    # 右侧云团
    draw.ellipse([540, 400, 730, 590], fill=cloud_color)
    # 中下部融合成型块（确保云朵底部平滑饱满）
    draw.rounded_rectangle([330, 490, 670, 610], radius=50, fill=cloud_color)

    # 5. 叠加边缘计算分布式网络节点 (Edge Nodes - Cyan)
    node_cyan = (14, 165, 233, 255) # 适配浅色背景的更深一点电光蓝

    # 底部横向网关连接线
    draw.line([(320, 720), (704, 720)], fill=(203, 213, 225, 255), width=8)

    # 绘制三个微光边缘节点
    nodes_x = [320, 512, 704]
    for nx in nodes_x:
        draw.ellipse([nx - 18, 702 - 18, nx + 18, 702 + 18], fill=(250, 249, 246, 255))
        draw.ellipse([nx - 12, 702 - 12, nx + 12, 702 + 12], fill=node_cyan)

    # 6. 在云朵中心精确嵌入高对比度纯白代码符号 "</>"
    w = 16
    # 左尖括号 <
    draw.line([(455, 425), (395, 475), (455, 525)], fill=(255, 255, 255, 255), width=w)
    # 右尖括号 >
    draw.line([(569, 425), (629, 475), (569, 525)], fill=(255, 255, 255, 255), width=w)
    # 中间斜杠 /
    draw.line([(530, 415), (484, 535)], fill=(255, 255, 255, 255), width=w)

    # 7. 保存生成的图标文件
    output_path = icon_dir / "app_icon.png"
    image.save(output_path, "PNG")
    print(f"[成功] 米白色背景版应用图标已重新生成并保存在: {output_path.resolve()}")

if __name__ == "__main__":
    generate_app_icon()
