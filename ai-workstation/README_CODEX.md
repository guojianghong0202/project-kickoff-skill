# AI实战飞书 GPT 工作站：Codex 直装入口

此分支只保存不含任何密钥的 Codex 部署任务书与 Windows 引导脚本。

在办公室 Windows 台式机按 `Win + R`，粘贴下面整行并回车：

```powershell
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$p=Join-Path ([Environment]::GetFolderPath('Desktop')) 'AIWorkstation-Codex.ps1'; Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/guojianghong0202/project-kickoff-skill/b24955945495409b0f32e66b99d2ef3bee3ad2ea/ai-workstation/BOOTSTRAP_CODEX.ps1' -OutFile $p; if ((Get-FileHash $p -Algorithm SHA256).Hash.ToLower() -ne '55a076ad18ce7b7ff6b136a9efc34975af52366d03a3902da80ef9f5eca1bef7') { Remove-Item $p -Force; throw '引导脚本校验失败，已停止' }; & $p"
```

脚本会下载到桌面、进行 SHA-256 校验、请求 Windows 管理员权限、检查或安装 Node.js 22、安装官方 `@openai/codex`、完成 Codex 登录、读取固定版本的部署任务书，在 `D:\AI_ShiZhan_Workstation`（无 D 盘时使用用户目录）生成并测试工作站，最后打开交互式配置入口。

用户本人仍需完成 Windows UAC、Codex/OpenAI 登录、OpenAI API Key 输入、飞书管理员扫码、应用发布以及把机器人加入“AI实战”群。这些安全授权不会写入本仓库。
