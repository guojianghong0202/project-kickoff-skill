# AI实战飞书 Codex 工作站：零 API 额外计费版部署任务书

你正在一台由用户本人授权的 Windows 10/11 台式机上工作。请在当前工作目录创建一个可运行、可审计的公司内部飞书机器人工作站。目标群名称固定为“AI实战”，机器人名称建议为“AI实战助手”。

## 核心目标

三位内部成员只需在飞书群里明确 `@AI实战助手`，即可让这台台式机完成中文问答、文案、方案、文件整理，以及白名单项目内的检查、修改、测试和打包。

本版本 **禁止调用 OpenAI API，禁止要求 OPENAI_API_KEY，禁止产生 API 用量账单**。所有模型任务统一通过本机官方 Codex CLI 的“使用 ChatGPT 登录”方式执行，消耗对应成员自己的 ChatGPT/Codex 套餐额度。

## 账号与计费边界

- 每个飞书成员必须绑定自己的 ChatGPT 账号和独立 Codex 本地凭据目录。
- 一个 Codex 凭据配置只能绑定一个飞书 sender_id；不得把同一 ChatGPT 登录态映射给多个人。
- 用户本人的 Pro/Plus 配额只用于该用户自己从飞书发起的任务。
- 两位同事可分别使用自己的 ChatGPT Free、Go、Plus、Pro、Business 等符合当前 Codex资格的账号；实际额度以各自账号当时可用范围为准。
- 不得复制、导出、群发或提交 `auth.json`、访问令牌、Cookie、API Key 或浏览器凭据。
- 不得实现“所有成员共用管理员个人 ChatGPT 套餐”的模式。
- 不使用官方 `openai` SDK，不创建 Responses API 请求，不读取 `OPENAI_API_KEY`。

## 总体架构

```text
飞书“AI实战”群
  -> 飞书企业自建应用机器人（WebSocket 长连接）
  -> Windows 本地 Worker
  -> 按飞书 sender_id 路由到独立 CODEX_HOME
  -> codex exec（ChatGPT 登录）
  -> 指定工作区或项目目录
  -> 结果和交付文件返回飞书
```

台式机只需能正常访问互联网，不需要公网 IP、固定 IP、域名、端口映射或云服务器。

## 不可违反的安全边界

- 不允许群成员提交任意 CMD、PowerShell 或管理员命令。
- Codex 只能在配置的工作区根目录和项目根目录内读写；默认禁用任务网络访问。
- 不自动执行付款、转账、生产发布、对外群发、账号权限变更、关闭安全软件、大范围删除等高风险操作。
- 只服务绑定后的唯一内部群；私聊默认不执行 AI 任务。
- 普通成员只能查看/取消自己的任务；首次绑定人可以查看全部任务和诊断信息。
- 安装器不得读取或修改本任务无关的个人文件。
- 任何日志都不得记录 ChatGPT 登录令牌、飞书 App Secret、认领码明文或附件中的敏感内容。

## 技术要求

- Node.js 22 或更高版本，ESM。
- 安装官方 `@openai/codex@latest` CLI；运行时不得使用 OpenAI API SDK。
- 飞书优先使用官方 `@larksuiteoapi/node-sdk`。可先检查当前稳定版 `@larksuite/channel`；若其 WebSocket、消息归一化、媒体下载和回复能力可用，可以使用；否则直接用官方 node-sdk 的 `WSClient`、`EventDispatcher` 和 `Client`。
- 依赖采用当前 npm 注册表可安装的稳定版本，生成 `package-lock.json`。
- Windows 脚本兼容 PowerShell 5.1，文本使用 UTF-8。

## 必须生成的文件和入口

至少包含：

```text
package.json
.env.example
.gitignore
README.md
INSTALL_AND_CONFIGURE.cmd
CREATE_FEISHU_APP.cmd
INSTALL_CODEX.cmd
ADD_CODEX_USER.cmd
LIST_CODEX_USERS.cmd
REVOKE_CODEX_USER.cmd
START_HIDDEN.cmd
START_AI_WORKER.cmd
STOP_AI_WORKER.cmd
CHECK_STATUS.cmd
UNINSTALL_AUTOSTART.cmd
config/assistant_instructions.md
config/codex_instructions.md
config/projects.json
scripts/install.ps1
scripts/register-feishu-app.mjs
scripts/add-codex-user.ps1
scripts/list-codex-users.ps1
scripts/revoke-codex-user.ps1
scripts/run-codex.ps1
scripts/run-worker.ps1
scripts/stop.ps1
scripts/status.mjs
scripts/start-hidden.vbs
src/index.mjs
src/config.mjs
src/codex-profiles.mjs
src/codex-runner.mjs
src/projects.mjs
src/security.mjs
src/attachments.mjs
src/task-queue.mjs
src/store.mjs
src/logger.mjs
src/commands.mjs
src/messages.mjs
src/utils.mjs
tests/smoke.mjs
```

文件可以增加，但不能省略关键能力。

## `.env` 配置

安装脚本只采集飞书凭据和本地目录，不采集任何 OpenAI API Key：

```env
FEISHU_APP_ID=""
FEISHU_APP_SECRET=""
BIND_CODE="随机6位数字"
PROJECT_ROOT="D:\公司项目"
WORK_ROOT="D:\AI_ShiZhan_Workspaces"
CODEX_PROFILE_ROOT="C:\ProgramData\AI_ShiZhan\codex-profiles"
CODEX_TIMEOUT_MINUTES="45"
CODEX_NETWORK_ACCESS="false"
MAX_CONCURRENCY="2"
DAILY_TASK_LIMIT_PER_USER="50"
MAX_ATTACHMENTS="5"
MAX_ATTACHMENT_MB="20"
MAX_TOTAL_ATTACHMENT_MB="50"
MAX_SEND_FILE_MB="30"
TARGET_GROUP_NAME="AI实战"
AUTO_BIND_BY_GROUP_NAME="true"
TIMEZONE="Asia/Taipei"
```

没有 D 盘时，`PROJECT_ROOT` 默认 `%USERPROFILE%\公司项目`，`WORK_ROOT` 默认 `%USERPROFILE%\AI_ShiZhan_Workspaces`。

用 `icacls` 将 `.env`、`data`、`logs` 和 `CODEX_PROFILE_ROOT` 权限限制为当前 Windows 用户、SYSTEM 和 Administrators。对每个 profile 的 `auth.json` 使用同样的严格 ACL。

## 独立 Codex 用户配置

### 本地添加用户

`ADD_CODEX_USER.cmd` 调用 `scripts/add-codex-user.ps1`：

1. 询问用户显示名；
2. 创建随机 profile_id 和 6 位一次性认领码，15 分钟过期；
3. 在 `CODEX_PROFILE_ROOT\<profile_id>` 创建独立 `CODEX_HOME`；
4. 写入该 profile 的 `config.toml`：

```toml
forced_login_method = "chatgpt"
cli_auth_credentials_store = "file"
```

5. 在该进程环境中设置 `CODEX_HOME`，优先执行 `codex login --device-auth`；若当前 CLI 不支持则回退 `codex login`；
6. 登录完成后执行 `codex login status` 验证为 ChatGPT 登录，而不是 API Key；
7. 将 profile_id、显示名、认领码哈希、过期时间写入受保护的 pending profiles 数据文件；
8. 显示一次性认领码和群内命令，不显示或复制 `auth.json`。

用户随后在“AI实战”群发送：

```text
@AI实战助手 /认领 123456
```

Worker 必须把当前飞书 sender_id 与该 profile 一对一绑定，并立即销毁认领码。已绑定 profile 不可被第二个 sender_id 认领；同一 sender_id 不可静默改绑其他 profile。

### 撤销用户

`REVOKE_CODEX_USER.cmd` 支持按显示名或 profile_id：

- 停止该 profile 的运行中任务；
- 删除飞书 sender_id 映射；
- 在确认后执行该 profile 环境下的 `codex logout`；
- 删除 profile 凭据目录；
- 保留不含敏感内容的审计记录。

`LIST_CODEX_USERS.cmd` 只显示显示名、绑定状态、最近使用时间和 Codex 登录状态，不显示 token、认领码或完整 sender_id。

## 飞书应用与长连接

最小租户权限：

```text
im:message.group_at_msg:readonly
im:message:send_as_bot
im:resource
im:chat:readonly
```

订阅事件：

```text
im.message.receive_v1
```

`CREATE_FEISHU_APP.cmd` 优先尝试使用当前 SDK 的设备码/二维码注册能力创建企业自建应用，预设名称“AI实战助手”。若租户不支持自动创建，则打开飞书开发者后台并生成清晰的 `SETUP_FEISHU_MANUAL.md`，引导用户创建应用、录入 App ID/App Secret、选择“使用长连接接收事件”、发布版本并把机器人加入群。

运行时要求：

- WebSocket 长连接；15 秒握手超时；断线自动重连；应用级保活；REST 请求超时；
- 私聊默认关闭，群消息必须明确 @机器人；
- 初次未绑定时，仅接受 `/绑定 6位码`、`/帮助`；也可在群名精确等于“AI实战”时，由首个明确 @机器人的真人消息自动绑定；
- 绑定后只处理唯一群，其他群静默拒绝；
- 忽略机器人自己和其他机器人消息；
- 未绑定 Codex profile 的成员只能使用 `/帮助`、`/我的ID`、`/认领`、`/授权状态`，AI 任务应返回清楚的授权提示。

## 群命令

自然语言默认等价 `/问`。至少实现：

```text
/帮助
/问 内容
/执行 项目名 任务内容
/项目
/状态
/状态 任务编号
/取消 任务编号
/文件 项目名 相对路径
/新会话
/额度
/我的ID
/授权状态
/认领 6位码
/绑定 6位码
/解绑 6位码
/诊断
```

项目名含空格时支持中文或英文引号。

## 普通问答也通过 Codex CLI

- `/问` 不调用 Responses API；统一调用发起人的独立 Codex profile。
- 为每个“群 + 成员 + 话题”建立独立工作目录和 `conversation.md`；保存最近有限轮次的用户需求与最终回复，超过阈值先本地压缩摘要。
- `/新会话` 清空当前成员当前话题的上下文文件。
- 附件下载到当前会话工作目录；图片通过 Codex CLI `--image` 传入，其他文件保存在工作目录并在提示词中列出相对路径，允许 Codex使用本地工具读取。
- 不把飞书原消息、附件或上下文写入其他用户工作目录。
- 回复过长时安全分片；最终结果由 `--output-last-message` 文件读取，不能依赖解析控制台彩色输出。

普通问答提示词必须说明：默认中文、直接完成工作、不要修改工作区外文件、不要读取凭据、需要生成交付文件时写入当前工作目录并在最终回复列出相对路径。

## 本地项目执行

`/执行` 只能解析为“白名单项目 + 自然语言任务”，绝不能提供裸 shell 命令入口。

项目白名单规则：

- `PROJECT_ROOT` 下的直接子文件夹自动成为项目；`config/projects.json` 可增加别名；
- 使用 `realpath` 和目录边界检查，防止 `..`、绝对路径、junction/symlink 越界；
- `/文件` 阻止 `.env`、`.git`、私钥、证书、密码库、凭据、浏览器数据和 `CODEX_PROFILE_ROOT`；
- 每个调用必须使用消息发送者自己的 profile，不得回退到管理员 profile。

调用 Codex CLI 时，在子进程环境设置该用户的 `CODEX_HOME`，并采用：

```text
codex exec
--ask-for-approval never
--sandbox workspace-write
--cd <会话工作目录或项目目录>
--color never
--ephemeral
--ignore-user-config
--ignore-rules
--config sandbox_workspace_write.network_access=false
--config project_doc_max_bytes=0
--config features.plugins=false
--skip-git-repo-check
--output-last-message <总结文件>
```

先执行 `codex login status`；若不是有效 ChatGPT 登录，任务应失败并提示管理员重新运行 `ADD_CODEX_USER.cmd`，绝不能自动改用 API Key或其他成员凭据。

网络开关由 `.env` 控制，默认 false。不得使用 `--dangerously-bypass-approvals-and-sandbox`。

Codex 系统约束写入 `config/codex_instructions.md`：只读写当前工作目录或项目；不读取密钥和其他用户数据；不做高风险动作；先检查再修改；运行最相关测试；未验证必须明确；最终列出完成内容、修改文件、验证结果、风险和交付相对路径。

## 任务队列

- 默认最大并发 2；同一个项目串行锁；同一 profile 串行；同一会话串行；
- 任务状态包含 queued/running/completed/failed/cancelled；状态持久化；进程重启时把未完成任务标记失败；
- 支持取消和超时后终止完整进程树；
- 每人每日默认 50 个任务；保留最近 300 条任务；
- 每个任务记录 sender_id 的不可逆哈希、profile_id、项目、时间、状态和退出码，不记录提示词全文或 token；
- 任务完成后回复原消息，失败时给出可理解原因，不把完整内部日志发群。

## Windows 安装与运行

`INSTALL_AND_CONFIGURE.cmd` 调用 `scripts/install.ps1`：

1. 检查 Node.js 22+；缺失时用 winget 安装，失败必须停止并解释；
2. 安装或更新官方 Codex CLI；
3. `npm install --omit=dev --ignore-scripts --no-audit --no-fund`；
4. 安全采集项目根目录、工作目录和已有飞书凭据；**不得询问 OpenAI API Key**；
5. 生成随机群绑定码并写 `.env`；
6. 创建 profile 根目录并收紧 ACL；
7. 创建 Windows 登录启动快捷方式；
8. 运行 smoke tests；
9. 创建桌面“添加 Codex 用户、列出用户、撤销用户、启动、停止、查看状态、打开项目目录”快捷方式。

后台运行可用 VBS 隐藏窗口和自动重启 loop。电脑关机、断网或 Windows 用户注销时停止；显示器可以关闭。

## 测试和验收

必须实际执行：

```text
node --check src/*.mjs
node --check scripts/*.mjs
npm test
npm ls --depth=0
```

`tests/smoke.mjs` 至少覆盖：

- 命令解析和带空格项目名；
- 路径越界、敏感文件和危险任务拦截；
- sender_id 与 profile 一对一绑定；
- 认领码过期、重放和抢占；
- 未授权用户不得调用 AI；
- 不得回退到管理员 profile 或 API Key；
- 任务队列锁、取消、状态持久化和中断恢复；
- 不同用户会话和附件目录隔离；
- 日志脱敏。

最终不要只写方案。必须创建所有文件、安装本地依赖、运行测试并修复失败，直到本地静态检查和 smoke tests 通过。最后输出：

1. 安装目录；
2. 生成文件清单；
3. 依赖版本；
4. 测试结果；
5. 明确声明“未使用 OpenAI API Key，不产生 API用量账单”；
6. 用户仍需本人完成的动作：Windows UAC、飞书扫码/发布、为三位成员分别运行 `ADD_CODEX_USER.cmd` 并让每人登录自己的 ChatGPT账号；
7. 飞书群首条命令：`@AI实战助手 /我的ID`；
8. 添加用户后的认领命令：`@AI实战助手 /认领 6位码`；
9. 完整测试命令：`@AI实战助手 /问 只回复：AI实战工作站连接成功`。
