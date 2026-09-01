# AI实战共享 AI 工单中心｜Codex 直装版

此目录用于让办公室 Windows 台式机上的官方 Codex CLI 自动创建、安装和测试共享工单中心。

## 目标

- 三位成员日常只使用飞书“AI实战”群。
- 普通任务经 Slack 私有频道触发用户现有 ChatGPT Work 任务。
- 本地项目修改由群主在飞书批准后，使用群主本人 Codex ChatGPT 登录执行。
- 不使用 OpenAI API，不采集 `OPENAI_API_KEY`，不产生 API 用量账单。
- 不把用户的 ChatGPT 密码或登录态交给普通成员。

## Windows 一行启动

在办公室 Windows 台式机按 `Win + R`，粘贴下面完整一行并回车：

```powershell
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$p=Join-Path ([Environment]::GetFolderPath('Desktop')) 'AI-ShiZhan-Shared-Work-Codex.ps1'; Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/guojianghong0202/project-kickoff-skill/aa1a1b82ca0e1bf4b2ba14238c896b7910ac496e/ai-shizhan-shared-work-center/BOOTSTRAP_CODEX.ps1' -OutFile $p; & $p"
```

脚本从不可变的 Git commit 下载，不经过聊天附件下载按钮。

## 自动完成

1. 请求 Windows 管理员权限；
2. 检查或安装 Node.js 22+；
3. 安装最新版官方 `@openai/codex`；
4. 建立只允许 ChatGPT 登录的隔离 Codex 配置；
5. 让套餐所有者本人完成 Codex 登录；
6. 下载固定版本部署任务书；
7. 让本机 Codex 实际生成全部项目文件、安装依赖并运行测试；
8. 检查项目不含 OpenAI API SDK、API 域名或 `OPENAI_API_KEY`；
9. 打开飞书、Slack、ChatGPT Work 的交互式安全配置入口；
10. 生成闭环测试入口。

默认目录：

```text
D:\AI_ShiZhan_Shared_Work_Center
```

无 D 盘时使用：

```text
%USERPROFILE%\AI_ShiZhan_Shared_Work_Center
```

## 必须由账号本人完成

这些步骤不能由脚本绕过：

- Windows UAC；
- Codex 使用 ChatGPT 登录；
- 飞书管理员扫码、发布应用、把机器人加入“AI实战”群；
- 创建 Slack App、获得 `xoxb-` 和 `xapp-`；
- 把网关机器人和 `@ChatGPT` 加入私有 Slack 频道；
- 在 ChatGPT 设置中连接 Slack；
- 在 Work 中创建并启用 Slack 新频道消息事件任务；
- 根据账号界面批准 Slack 写消息/上传文件动作。

## 验收

安装完成后运行：

```text
CHECK_CLOSED_LOOP.cmd
```

只有自测消息经过 Slack → ChatGPT Work → Slack 线程完整返回，才算普通任务链路完成。

然后在飞书群测试：

```text
@AI实战助手 /问 只回复：AI实战工作站连接成功
```

本地项目测试：

```text
@AI实战助手 /执行 商图工厂 只检查项目并列出问题，不修改文件
```

群主随后使用任务号执行：

```text
@AI实战助手 /批准 任务号
```
