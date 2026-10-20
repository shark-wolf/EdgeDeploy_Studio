#!/usr/bin/env python3
# ==============================================================================
# 脚本名称: package.py
# 核心职责: 跨平台 Flutter 桌面端自动化打包脚本 (完美适配 Windows / macOS / Linux)
# 使用方法:
#   1. 正常打包: python package.py
#   2. 清理并打包: python package.py --clean
# ==============================================================================

import os
import sys
import platform
import shutil
import subprocess
import zipfile
import argparse

def run_command(cmd):
    """执行子进程命令并实时输出"""
    print(f"[*] 正在执行: {' '.join(cmd) if isinstance(cmd, list) else cmd}")
    is_windows = platform.system() == "Windows"
    result = subprocess.run(cmd, shell=is_windows)
    if result.returncode != 0:
        print("[-] 命令执行失败")
        sys.exit(result.returncode)

def main():
    parser = argparse.ArgumentParser(description="EdgeDeploy-Studio 跨平台打包脚本")
    parser.add_argument("--clean", action="store_true", help="打包前执行 flutter clean 清理缓存")
    args = parser.parse_args()

    if not os.path.exists("pubspec.yaml"):
        print("[-] 错误: 请在 Flutter 项目根目录下运行此脚本！")
        sys.exit(1)

    current_os = platform.system()
    print("==================================================")
    print("  EdgeDeploy-Studio 跨平台全依赖打包工具")
    print(f"  当前检测到的操作系统: {current_os}")
    print("==================================================")

    if args.clean:
        print("[*] 正在执行 flutter clean...")
        run_command(["flutter", "clean"])

    print("[*] 正在获取 Flutter 依赖 (flutter pub get)...")
    run_command(["flutter", "pub", "get"])

    dist_dir = "dist"
    app_name = "EdgeDeploy-Studio"
    target_output_dir = os.path.join(dist_dir, app_name)

    if os.path.exists(dist_dir):
        shutil.rmtree(dist_dir)
    os.makedirs(target_output_dir, exist_ok=True)

    # ------------------------------------------------------------------
    uploader_zip = ""

    if current_os == "Windows":
        print("[*] 正在构建 Windows Release 版本...")
        run_command(["flutter", "build", "windows", "--release"])
        source_build_dir = os.path.join("build", "windows", "x64", "runner", "Release")

        if not os.path.exists(source_build_dir):
            print(f"[-] 错误: 未找到编译产物目录: {source_build_dir}")
            sys.exit(1)

        print("[*] 正在搜集 Windows 所有依赖 DLL 与产物...")
        for item in os.listdir(source_build_dir):
            s = os.path.join(source_build_dir, item)
            d = os.path.join(target_output_dir, item)
            if os.path.isdir(s):
                shutil.copytree(s, d, dirs_exist_ok=True)
            else:
                shutil.copy2(s, d)

        zip_filename = os.path.join(dist_dir, f"{app_name}-Windows-x64.zip")
        print(f"[*] 正在生成归档压缩包: {zip_filename}...")
        with zipfile.ZipFile(zip_filename, 'w', zipfile.ZIP_DEFLATED) as zipf:
            for root, dirs, files in os.walk(target_output_dir):
                for file in files:
                    file_path = os.path.join(root, file)
                    arcname = os.path.relpath(file_path, target_output_dir)
                    zipf.write(file_path, arcname)

    elif current_os == "Darwin":  # macOS
        print("[*] 正在构建 macOS Release 版本...")
        run_command(["flutter", "build", "macos", "--release"])
        source_build_dir = os.path.join("build", "macos", "Build", "Products", "Release")

        if not os.path.exists(source_build_dir):
            print(f"[-] 错误: 未找到编译产物目录: {source_build_dir}")
            sys.exit(1)

        # 在 Release 目录下寻找 .app 目标
        app_bundle_name = None
        for item in os.listdir(source_build_dir):
            if item.endswith(".app"):
                app_bundle_name = item
                break

        if not app_bundle_name:
            print("[-] 错误: 未能在编译目录中找到 .app 产物")
            sys.exit(1)

        source_app_path = os.path.join(source_build_dir, app_bundle_name)
        target_app_path = os.path.join(target_output_dir, app_bundle_name)

        print(f"[*] 正在复制 macOS 独立应用包: {app_bundle_name}...")
        shutil.copytree(source_app_path, target_app_path, dirs_exist_ok=True)

        zip_filename = os.path.join(dist_dir, f"{app_name}-macOS.zip")
        print(f"[*] 正在使用 macOS 原生 ditto 命令进行安全归档（保留软链接与签名属性）...")
        # 使用 Apple 推荐的 ditto 命令，避免 .app 内部的 symlink 损坏
        run_command(["ditto", "-c", "-k", "--sequesterRsrc", "--keepParent", target_app_path, zip_filename])

    elif current_os == "Linux":
        print("[*] 正在构建 Linux Release 版本...")
        run_command(["flutter", "build", "linux", "--release"])
        source_build_dir = os.path.join("build", "linux", "x64", "release", "bundle")

        if not os.path.exists(source_build_dir):
            print(f"[-] 错误: 未找到编译产物目录: {source_build_dir}")
            sys.exit(1)

        print("[*] 正在搜集 Linux 编译产物...")
        for item in os.listdir(source_build_dir):
            s = os.path.join(source_build_dir, item)
            d = os.path.join(target_output_dir, item)
            if os.path.isdir(s):
                shutil.copytree(s, d, dirs_exist_ok=True)
            else:
                shutil.copy2(s, d)

        zip_filename = os.path.join(dist_dir, f"{app_name}-Linux-x64.zip")
        print(f"[*] 正在生成归档压缩包: {zip_filename}...")
        with zipfile.ZipFile(zip_filename, 'w', zipfile.ZIP_DEFLATED) as zipf:
            for root, dirs, files in os.walk(target_output_dir):
                for file in files:
                    file_path = os.path.join(root, file)
                    arcname = os.path.relpath(file_path, target_output_dir)
                    zipf.write(file_path, arcname)

    else:
        print(f"[-] 不支持的操作系统: {current_os}")
        sys.exit(1)

    print("==================================================")
    print("  🎉 EdgeDeploy-Studio 跨平台打包成功！")
    print(f"  - 绿色产物目录: {os.path.abspath(target_output_dir)}")
    print(f"  - 分发压缩包: {os.path.abspath(zip_filename)}")
    print("==================================================")

if __name__ == "__main__":
    main()
