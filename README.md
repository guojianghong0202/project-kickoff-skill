# Project Kickoff Skill

中文项目启动工作流 skill：把“我想做个 X”变成可执行启动包，包含项目章程、PR/FAQ、RACI、里程碑关卡、风险登记和启动会议程。

它的核心不是多写模板，而是防止 AI 在没问清楚时直接开干：先澄清输入，再按 S/M/L 项目量级裁剪输出。

## What It Does

- 判断项目量级：S / M / L。
- 用最多两轮访谈收集关键信息。
- 输出项目启动包：章程、PR/FAQ、六页纸、RFC、RACI、里程碑、风险、启动会议程。
- 对 AI / 模型 / 数据项目补充 eval、灰度放量和安全失败模式分析。
- 可按需生成 `AGENTS.md`、`README.md`、`docs/`、`CLAUDE.md` 骨架。

## Quick Use

Typical prompts:

```text
帮我启动一个 AI 客服项目，先按你的流程问我。
```

```text
我想做个小程序，从哪开始？
```

```text
先别问，按合理假设给我一个项目章程草案，缺的信息标 TBD。
```

The skill should:

1. Judge project size: S / M / L.
2. Ask at most two rounds of 1-3 questions.
3. Produce a draft kickoff packet with explicit `TBD（负责人 / 截止日）` items.
4. Run the quality gate before final output.

## Skill Improvement Focus

This repository is primarily a project kickoff skill, not a plugin framework. The most important quality assets are:

- `SKILL.md`：triggering and execution workflow.
- `references/questions.md`：two-round interview question bank.
- `references/quality-gate.md`：self-check before delivering a kickoff packet.
- `references/templates.md`：copy-fill templates.
- `examples/m-project-kickoff.md`：filled example showing expected output quality.
- `evals/prompts.md`：manual regression prompts for trigger and boundary testing.

## Install Options

### Claude Code Plugin

Clone this repo, then install it as a local plugin:

```bash
claude plugin install ./project-kickoff-skill
```

After installation, invoke it directly:

```text
/project-kickoff:project-kickoff 帮我启动一个 AI 客服项目
```

Claude Code can also invoke the skill automatically when your prompt matches the description.

### Claude Code Personal Skill

Copy the skill folder to your personal skills directory:

```bash
mkdir -p ~/.claude/skills/project-kickoff
cp -R skills/project-kickoff/* ~/.claude/skills/project-kickoff/
```

Windows PowerShell example:

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\skills\project-kickoff"
Copy-Item -Recurse -Force "skills\project-kickoff\*" "$env:USERPROFILE\.claude\skills\project-kickoff\"
```

### Codex Skill

Copy the skill folder to your Codex skills directory:

```bash
mkdir -p ~/.codex/skills/project-kickoff
cp -R skills/project-kickoff/* ~/.codex/skills/project-kickoff/
```

Windows PowerShell example:

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.codex\skills\project-kickoff"
Copy-Item -Recurse -Force "skills\project-kickoff\*" "$env:USERPROFILE\.codex\skills\project-kickoff\"
```

If your Codex setup uses `AGENTS.md` routing, add:

```md
## Project Kickoff Route

When the user asks to 启动/立项/kickoff a project, write a 立项书, 项目章程, PR/FAQ, working backwards, 启动会, RACI, 里程碑, 验收标准, or says “我想做个 X，从哪开始”, use the `project-kickoff` skill before drafting a solution.
```

## Repository Layout

```text
.
├── .claude-plugin/plugin.json
├── skills/project-kickoff/SKILL.md
├── references/
│   ├── templates.md
│   ├── questions.md
│   ├── quality-gate.md
│   ├── playbooks.md
│   └── superpowers.md
├── examples/m-project-kickoff.md
├── evals/
│   ├── prompts.md
│   └── expected-behavior.md
└── scripts/scaffold.py
```

The root `SKILL.md` remains for backward compatibility. The plugin entrypoint is `skills/project-kickoff/SKILL.md`.

## Output Preview

For a mid-sized internal tool, the skill should produce something like:

```md
项目名称：销售线索录音分析工具
负责人：产品负责人 TBD（销售运营负责人 / 2026-07-12）
目标量级：M

目标：
- 在 6 周内完成销售通话录音转写、摘要、风险标签和线索评分的内测版本。

成功指标：
- 内测销售顾问每周节省复盘时间 30%。
- 录音摘要可用率达到 85%。
- 高风险话术召回率达到 80%。

本次不做：
- 不做 CRM 全量替换。
- 不做实时通话监听。
```

See `examples/m-project-kickoff.md` for a complete filled example.

## Quality Bar

Before treating a skill change as done:

- `SKILL.md` frontmatter description stays trigger-focused.
- At least one filled example exists.
- `evals/prompts.md` covers trigger, non-trigger, and boundary cases.
- `references/questions.md` supports short two-round interviews.
- `references/quality-gate.md` catches missing metrics, missing Out scope, unclear owner, and missing gate criteria.
- Missing information is marked as `TBD（负责人 / 截止日）`.
- S-sized projects stay lightweight.

## License

MIT
