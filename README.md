# Project Kickoff Skill

一个用于项目启动、立项和 kickoff 的 Codex skill。

它把模糊项目想法整理成可执行的启动包，包括：

- 项目量级判断
- 一页项目章程
- PR/FAQ
- 六页纸叙事
- 设计文档 / RFC
- RACI / DACI 决策矩阵
- 里程碑与阶段关卡
- 风险登记表
- 启动会议程

## 适用场景

当用户提到以下需求时使用：

- 启动一个新项目
- 写项目启动文档
- 写立项书或项目章程
- 做 PR/FAQ 或 working backwards
- 开项目启动会
- 定义项目目标、范围和验收标准
- 把一个想法变成可执行项目

## 安装

把整个仓库复制到 Codex skills 目录：

```bash
C:/Users/gjh/.codex/skills/project-kickoff
```

目录结构应类似：

```text
project-kickoff/
  SKILL.md
  references/
    templates.md
    playbooks.md
    superpowers.md
```

安装后重启 Codex，让新 skill 生效。

## 使用

示例提示词：

```text
请读取并严格遵循这个技能文件：
C:/Users/gjh/.codex/skills/project-kickoff/SKILL.md
按它的流程帮我启动【项目名称】。
需要模板时读同目录 references/templates.md，
想看大厂方法对照读 references/playbooks.md，
落地阶段读 references/superpowers.md。
```

## 文件说明

- `SKILL.md`：主技能文件。
- `references/templates.md`：项目启动文档模板。
- `references/playbooks.md`：Amazon、Google、Meta、Anthropic/OpenAI、PMBOK、Stage-Gate 方法对照。
- `references/superpowers.md`：从启动到落地的 brainstorming、writing-plans、subagent-driven-development 方法。
