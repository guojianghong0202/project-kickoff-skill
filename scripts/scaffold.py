#!/usr/bin/env python3
"""Create a minimal project kickoff file scaffold without overwriting files."""

from __future__ import annotations

import argparse
from pathlib import Path


FILES = {
    "AGENTS.md": """# AGENTS.md

## 项目目标

- 这个项目用于：TBD（负责人 / 截止日）
- 主要用户和场景：TBD（负责人 / 截止日）
- 当前阶段：TBD（S/M/L，第几阶段）
- 暂时不做（Out of scope）：TBD（负责人 / 截止日）

## 技术栈与目录结构

- 技术栈：TBD（负责人 / 截止日）
- 源码目录：TBD（负责人 / 截止日）
- 测试目录：TBD（负责人 / 截止日）
- 文档目录：docs/

## 开发命令

- 安装依赖：TBD（负责人 / 截止日）
- 本地启动：TBD（负责人 / 截止日）
- 运行测试：TBD（负责人 / 截止日）
- 代码检查 / lint：TBD（负责人 / 截止日）
- 构建：TBD（负责人 / 截止日）

## 修改边界

- 不要修改密钥、环境变量、生产配置。
- 不要删除用户数据、迁移文件、历史记录。
- 不要自动执行 git push 或部署。
- 破坏性、批量、不可逆操作前先停止并向人确认。

## 验收标准

- 改完说明改了什么、在哪。
- 能跑测试必须跑，跑不了说明原因。
- 标出仍存在的风险。
- 验收指标：TBD（负责人 / 截止日）
""",
    "README.md": """# 项目名

一句话简介：TBD（负责人 / 截止日）

## 快速上手

- 安装：TBD（负责人 / 截止日）
- 启动：TBD（负责人 / 截止日）
- 测试：TBD（负责人 / 截止日）

## 目录结构

- src/：TBD（负责人 / 截止日）
- docs/：项目文档

## 文档

- 项目协作规则见 AGENTS.md。
""",
    "CLAUDE.md": "本项目代理规则见 AGENTS.md。\n",
    "docs/api.md": "# API 规范\n\nTBD（负责人 / 截止日）\n",
    "docs/db.md": "# 数据库规范\n\nTBD（负责人 / 截止日）\n",
    "docs/frontend.md": "# 前端规范\n\nTBD（负责人 / 截止日）\n",
    "docs/release.md": "# 发布流程\n\nTBD（负责人 / 截止日）\n",
}


def main() -> int:
    parser = argparse.ArgumentParser(description="Create kickoff scaffold files.")
    parser.add_argument("target", nargs="?", default=".", help="Target project directory")
    parser.add_argument("--force", action="store_true", help="Overwrite existing files")
    args = parser.parse_args()

    target = Path(args.target).resolve()
    target.mkdir(parents=True, exist_ok=True)

    created: list[str] = []
    skipped: list[str] = []

    for relative_path, content in FILES.items():
        path = target / relative_path
        if path.exists() and not args.force:
            skipped.append(relative_path)
            continue
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        created.append(relative_path)

    if created:
        print("Created:")
        for item in created:
            print(f"  - {item}")

    if skipped:
        print("Skipped existing files:")
        for item in skipped:
            print(f"  - {item}")

    if not created and not skipped:
        print("No files configured.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
