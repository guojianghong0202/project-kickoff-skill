# AI实战飞书 Codex 工作站：零 API 额外计费版

旧版 ZIP 和旧版命令会要求 `OPENAI_API_KEY`，不要再运行。

本版本不调用 OpenAI API，不收集 API Key，不产生 API 用量账单。模型任务通过官方 Codex CLI 的“使用 ChatGPT 登录”执行，并计入实际发起成员自己的 ChatGPT/Codex套餐额度。

## 重要账号规则

- 用户本人的飞书身份绑定用户本人的 ChatGPT/Codex 登录，消耗用户本人的套餐额度。
- 两位同事必须分别绑定自己的 ChatGPT账号；不得共同使用管理员的个人账号或套餐。
- 一个 Codex profile 只能绑定一个飞书 sender_id。
- Codex 当前包含在符合资格的 ChatGPT计划中，具体额度以各账号当时显示为准。

## Windows 一行启动

在办公室 Windows 台式机按 `Win + R`，粘贴下面整行并回车：

```powershell
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$p=Join-Path ([Environment]::GetFolderPath('Desktop')) 'AIWorkstation-Codex-NoAPI.ps1'; Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/guojianghong0202/project-kickoff-skill/6a613f50daea8113e3cfe840cd2c764da5df7297/ai-workstation/BOOTSTRAP_CODEX.ps1' -OutFile $p; & $p"
```

引导脚本会：

1. 写入桌面并请求 Windows 管理员权限；
2. 检查或安装 Node.js 22；
3. 安装官方 `@openai/codex`；
4. 用管理员自己的 ChatGPT登录让 Codex生成工作站；
5. 验证生成项目不包含 OpenAI API SDK，也不要求 `OPENAI_API_KEY`；
6. 运行 smoke tests；
7. 打开飞书配置入口和本地工作站目录。

工作站默认安装到：

```text
D:\AI_ShiZhan_Workstation
```

没有 D 盘时使用当前用户目录。

## 完成飞书应用后，为三位成员分别授权

在台式机上每位成员分别运行一次：

```text
ADD_CODEX_USER.cmd
```

由该成员本人使用自己的 ChatGPT账号完成 Codex 登录。程序会生成一次性认领码，然后该成员在“AI实战”群发送：

```text
@AI实战助手 /认领 6位码
```

完成后，群内自然语言、`/问` 与 `/执行` 都会路由到消息发送者自己的 Codex profile，不会回退到管理员账号，也不会改走 API Key。

用户本人仍需处理 Windows UAC、ChatGPT登录、飞书管理员扫码、应用发布以及把机器人加入“AI实战”群。这些安全授权不会写入仓库。
