# AI实战共享 AI 工单中心：Codex 本机部署任务书

你正在一台由用户本人授权的 Windows 10/11 台式机上工作。请在当前目录创建、安装并测试一个可运行、可审计的公司内部 AI 工单中心。

## 1. 最终目标

唯一日常入口是飞书群 **“AI实战”**，机器人建议命名 **“AI实战助手”**。

三位内部成员都可以在群里提交工作任务。系统分成两条路径：

1. **普通工作任务**：飞书消息 → 本机网关 → 私有 Slack 频道 → 用户本人 ChatGPT Work 的 Slack 新消息事件任务 → 结果和附件回到 Slack 线程 → 本机网关回传飞书。
2. **本地项目任务**：成员提交 `/执行 项目名 任务` → 等待群主本人在飞书 `/批准 任务号` → 本机 Codex CLI 使用群主本人“使用 ChatGPT 登录”的会话执行 → 结果回传飞书。

## 2. 不可变约束

- **禁止调用 OpenAI API**，不得要求、读取或保存 `OPENAI_API_KEY`，不得安装 `openai` API SDK，不产生 API 用量账单。
- 普通任务使用用户现有 ChatGPT 计划中的 Work 事件任务额度。
- 本地项目任务使用用户现有 ChatGPT 计划中的 Codex 额度。
- 不共享 ChatGPT 密码、Cookie、令牌或 Codex 凭据；普通成员不能进入用户的 ChatGPT 账号。
- 不用模拟点击 ChatGPT 网页或桌面软件。
- 飞书和 Slack 都使用主动出站 WebSocket/Socket Mode，不需要公网 IP、域名、服务器或端口映射。
- 普通成员不得直接运行本地 Codex；只有绑定群时记录的群主 sender_id 可以批准。
- 不执行付款、转账、生产发布、对外群发、账号权限变更、关闭安全软件、大范围删除、凭据提取等高风险操作。

## 3. 技术栈

- Node.js 22+，ESM。
- 飞书：优先使用当前 npm 稳定版 `@larksuite/channel`；若安装或类型/API 验证失败，回退至 `@larksuiteoapi/node-sdk` 的 `WSClient`、`EventDispatcher`、`Client`。
- Slack：当前稳定版 `@slack/bolt`，Socket Mode；文件上传使用 `client.files.uploadV2`，禁止使用旧 `files.upload`。
- 本地 AI：官方 `@openai/codex@latest` CLI，只允许 ChatGPT 登录。
- 数据：本地 JSON 原子写入或无需原生编译的轻量存储。
- PowerShell 兼容 Windows PowerShell 5.1，所有文本 UTF-8。
- 不依赖 Docker、WSL、公网回调或外部数据库。

## 4. 必须生成的文件

至少包含：

```text
package.json
package-lock.json
.env.example
.gitignore
README.md
SECURITY.md
SETUP_CHECKLIST.md
SLACK_APP_MANIFEST.json
WORK_TASK_PROMPT.md

INSTALL_AND_CONFIGURE.cmd
CREATE_FEISHU_APP.cmd
OPEN_SLACK_SETUP.cmd
OPEN_CHATGPT_WORK_SETUP.cmd
INSTALL_CODEX.cmd
START_HIDDEN.cmd
START_WORKER.cmd
STOP_WORKER.cmd
CHECK_STATUS.cmd
CHECK_CLOSED_LOOP.cmd
UNINSTALL_AUTOSTART.cmd

config/assistant_instructions.md
config/codex_instructions.md
config/projects.json

scripts/install.ps1
scripts/register-feishu-app.mjs
scripts/configure-secrets.ps1
scripts/run-worker.ps1
scripts/stop-worker.ps1
scripts/status.mjs
scripts/closed-loop-test.mjs
scripts/start-hidden.vbs

src/index.mjs
src/config.mjs
src/logger.mjs
src/store.mjs
src/security.mjs
src/commands.mjs
src/task-queue.mjs
src/feishu-client.mjs
src/slack-client.mjs
src/slack-result-parser.mjs
src/attachments.mjs
src/projects.mjs
src/codex-runner.mjs
src/messages.mjs
src/utils.mjs

tests/smoke.mjs
```

可以增加文件，不能省略关键能力。

## 5. 配置

`.env.example`：

```env
FEISHU_APP_ID=""
FEISHU_APP_SECRET=""
FEISHU_BIND_CODE=""
TARGET_FEISHU_GROUP_NAME="AI实战"

SLACK_BOT_TOKEN=""
SLACK_APP_TOKEN=""
SLACK_CHANNEL_ID=""

PROJECT_ROOT="D:\\公司项目"
OUTPUT_ROOT="D:\\AI实战输出"
DATA_ROOT="D:\\AI_ShiZhan_Shared_Work_Center\\data"
LOG_ROOT="D:\\AI_ShiZhan_Shared_Work_Center\\logs"

CODEX_ENABLED="true"
CODEX_TIMEOUT_MINUTES="45"
CODEX_NETWORK_ACCESS="false"

MAX_PENDING_WORK_TASKS="20"
MAX_ATTACHMENTS="8"
MAX_ATTACHMENT_MB="25"
MAX_TOTAL_ATTACHMENT_MB="80"
MAX_SEND_FILE_MB="40"
DAILY_WORK_TASK_LIMIT_PER_USER="30"
TASK_RETENTION_DAYS="14"
TIMEZONE="Asia/Taipei"
```

无 D 盘时默认用 `%USERPROFILE%` 下相应目录。

必须做到：

- Worker 和 Codex 子进程删除 `OPENAI_API_KEY`、`AZURE_OPENAI_API_KEY`、`OPENAI_BASE_URL` 等 API 环境变量。
- `package.json` 不得包含 `openai` 依赖。
- 源码不得调用 `api.openai.com`、Responses API 或 Chat Completions API。
- `.env`、data、logs、Codex 凭据目录使用 `icacls`，只允许当前 Windows 用户、SYSTEM、Administrators。
- 日志脱敏飞书 Secret、Slack `xoxb-`/`xapp-`、绑定码和 Codex token。
- 密钥和 auth 文件不得写入 Git。

## 6. 飞书接入

最小租户权限：

```text
im:message.group_at_msg:readonly
im:message:send_as_bot
im:resource
im:chat:readonly
```

订阅 `im.message.receive_v1`，使用长连接。

`CREATE_FEISHU_APP.cmd` 优先尝试 SDK 的设备码/二维码注册能力创建“AI实战助手”；不支持时生成 `SETUP_FEISHU_MANUAL.md` 并打开飞书开发者后台。

群绑定规则：

- 安装时生成随机 6 位 `FEISHU_BIND_CODE`。
- 未绑定时只响应 `/帮助`、`/绑定 6位码`。
- 首次成功绑定时保存唯一 chat_id 和群主 sender_id。
- 后续只处理这个群；私聊默认关闭；群消息必须明确 @机器人。
- 忽略机器人、系统消息和重复事件。

## 7. Slack 网关

使用 Socket Mode：

- `SLACK_BOT_TOKEN=xoxb-...`
- `SLACK_APP_TOKEN=xapp-...`，需 `connections:write`
- 私有频道建议 `ai-shizhan-gateway`
- 频道邀请自建网关机器人和官方 `@ChatGPT`

生成 `SLACK_APP_MANIFEST.json`，至少包含：

- Socket Mode 开启
- bot scopes：`chat:write`、`files:write`、`files:read`、`channels:read`、`channels:history`、`groups:read`、`groups:history`
- bot events：`message.channels`、`message.groups`

不得把 token 写入 manifest 或源码。

## 8. ChatGPT Work 事件任务

生成 `WORK_TASK_PROMPT.md`，供用户在 ChatGPT Work 中创建 Slack 新频道消息触发任务。

触发条件：

- 只处理目标 Slack 频道根消息。
- 第一行严格为 `[FEISHU_TASK]`。
- 包含 `task_id:` 与 `mode: work`。
- 忽略 `[FEISHU_RESULT]`、线程回复、ChatGPT 自己的输出。
- 尽可能限定发送者为自建“AI实战网关”机器人。

Work 任务必须：

- 默认中文，直接完成工作，而非只给方法。
- 读取同一根消息的全部附件。
- 支持文案、研究、分析、Word、Excel、PPT、PDF、报告等 Work 能生成的交付物。
- 使用 Slack 写动作回复原消息线程；有文件时上传到原线程。
- 成功第一行：`[FEISHU_RESULT] <task_id> COMPLETED`
- 失败第一行：`[FEISHU_RESULT] <task_id> FAILED`
- 不泄露内部推理、凭据或其他频道内容。

网关发布协议：

```text
[FEISHU_TASK]
task_id: FS-YYYYMMDD-HHMMSS-XXXX
feishu_sender: <显示名或匿名短号>
mode: work
reply_required: slack_thread
request:
<<<
用户原始任务文本
>>>
```

有附件时优先通过一次 `files.uploadV2` 的 `file_uploads` + `initial_comment`，把文本和附件放在同一个根消息，避免任务在附件上传前触发；无附件用 `chat.postMessage`。

## 9. 飞书命令

自然语言默认等价 `/问`。至少支持：

```text
/帮助
/问 内容
/状态
/状态 任务号
/取消 任务号
/新会话
/项目
/执行 项目名 任务内容
/批准 任务号
/拒绝 任务号
/文件 项目名 相对路径
/诊断
/绑定 6位码
/解绑 6位码
```

项目名含空格时支持中文和英文引号。

## 10. 普通 Work 任务流程

1. 校验绑定群、@、每日额度与附件限制。
2. 创建任务记录：id、提交人哈希/显示名、飞书 chat/message/thread、状态、Slack 根消息 ts、附件元数据、时间。
3. 下载飞书附件至该任务独立临时目录。
4. 上传 Slack；飞书回复任务编号。
5. Slack Socket Mode 只处理目标频道中以 `[FEISHU_RESULT]` 开头的线程回复。
6. 解析 task_id，校验线程映射，去重。
7. 稳定等待后用 `conversations.replies` 收集结果文件。
8. 下载到 `OUTPUT_ROOT\<task_id>\`。
9. 把摘要和允许大小的交付文件回传飞书原消息。
10. `/取消` 只阻止尚未提交或结果回传；已启动的 Work 任务可能仍消耗计划额度，必须如实提示。
11. 14 天后清理正文和临时文件，保留无正文审计元数据。

防循环与幂等：以飞书 event/message id、Slack event_id/ts、task_id 去重；同一结果最多回传一次；重启后恢复任务状态。

## 11. 本地 Codex 项目任务

成员发送：

```text
@AI实战助手 /执行 商图工厂 修复导出 ZIP 中文文件名乱码并运行测试
```

系统只创建 `approval_pending`，不执行；群里显示任务号、提交人、项目、解析目录、任务内容、风险和 `/批准`/`/拒绝` 命令。

只有绑定群主 sender_id 可以批准或拒绝。

项目白名单：

- `PROJECT_ROOT` 直接子目录自动成为项目；`config/projects.json` 可配置别名。
- 使用 realpath 与边界检查防止 `..`、绝对路径、junction、symlink 越界。
- `/文件` 禁止 `.env`、`.git`、私钥、证书、密码库、浏览器数据、飞书/Slack 配置及 Codex 凭据。
- 禁止关键根目录相互嵌套。

Codex：

- 安装官方 `@openai/codex@latest`。
- 创建隔离 `CODEX_HOME`，如 `%LOCALAPPDATA%\AI_ShiZhan\codex-owner`。
- `config.toml` 至少：

```toml
forced_login_method = "chatgpt"
cli_auth_credentials_store = "file"
```

- 安装流程让群主本人完成“使用 ChatGPT 登录”。
- 运行前 `codex login status`；无有效 ChatGPT 登录则停止，绝不回退 API Key。
- 根据当前 CLI `--help` 调整参数，但安全语义需等价：`codex exec`、`--ask-for-approval never`、`--sandbox workspace-write`、`--cd <项目>`、`--color never`、`--ephemeral`、`--ignore-user-config`、`--ignore-rules`、网络默认 false、`project_doc_max_bytes=0`、plugins=false、`--skip-git-repo-check`、`--output-last-message`。
- 禁止 `--dangerously-bypass-approvals-and-sandbox`、`--yolo`、`danger-full-access`。
- 超时后终止完整进程树。

高风险请求直接拒绝，不允许通过普通 `/批准` 绕过。

Codex 最终结果列出完成内容、修改文件、测试与结果、未验证事项、风险和交付相对路径，并回传飞书。

## 12. 安装器

`INSTALL_AND_CONFIGURE.cmd` 调用 `scripts/install.ps1`：

1. 检查 Node.js 22+；缺失/过旧时用 winget 安装或升级。
2. 安装项目依赖与官方 Codex CLI。
3. **不询问 API Key**。
4. 安全采集飞书 App ID/Secret、Slack xoxb/xapp、Slack Channel ID、项目/输出目录。
5. 生成飞书绑定码，收紧 ACL。
6. 创建 Windows 登录自启动。
7. 创建桌面快捷方式：配置、启动、停止、状态、闭环测试、飞书设置、Slack 设置、ChatGPT Work 设置、输出目录。
8. 运行静态检查与 smoke tests。
9. 闭环测试未通过时不得声称完成。

## 13. 闭环测试

`CHECK_CLOSED_LOOP.cmd`：

1. 检查飞书、Slack、Codex 配置。
2. 检查 Slack Socket Mode。
3. 向频道发布自测 `[FEISHU_TASK]`，要求只回复“AI实战共享工单中心闭环成功”。
4. 最多等待 5 分钟。
5. 仅收到匹配线程中的 `[FEISHU_RESULT] SELFTEST-... COMPLETED` 且正文含指定短语才成功。
6. 失败时明确区分 token/权限、频道 ID、机器人未入群、`@ChatGPT` 未入群、ChatGPT 未连接 Slack、Work 任务未创建/暂停、Slack 写动作等待批准、计划/地区不可用。
7. 绝不自动切换 OpenAI API。

## 14. 状态与日志

`CHECK_STATUS.cmd` 显示 Worker、飞书连接、Slack Socket Mode、遮罩后的群/频道 ID、最近闭环测试、Codex 版本/登录、队列、最近脱敏错误，以及醒目文本：`OpenAI API: 禁用`。

日志 JSONL，禁止记录 token、Secret、完整附件正文或 Codex auth。

## 15. 测试与验收

必须实际执行并修复全部失败：

```text
node --check src/*.mjs
node --check scripts/*.mjs
npm test
npm ls --depth=0
```

smoke tests 至少覆盖：命令解析、带空格项目名、群绑定和群主身份、未批准不启动 Codex、普通成员不能批准、危险任务拒绝、路径越界和敏感文件拒绝、Slack 任务/结果协议、task_id/线程映射、事件幂等与防循环、附件限制、取消后不回传、状态持久化/恢复、日志脱敏、package 不含 `openai`、源码不含 `api.openai.com`、子进程删除 API Key 环境变量。

不要只写方案。必须创建全部文件、安装依赖、运行测试并修复，直到静态检查与 smoke tests 通过。

## 16. 最终报告

最后输出：安装目录、文件清单、依赖版本、测试结果，并明确：

- `OpenAI API：未使用`
- `OPENAI_API_KEY：未收集`
- `普通任务：ChatGPT Work + Slack 事件触发`
- `本地项目任务：群主批准后使用 Codex ChatGPT 登录`

列出仍需用户本人完成的安全授权：Windows UAC、飞书扫码/发布、Slack App 与 token、ChatGPT 连接 Slack、Work 事件任务、Slack 写动作权限、Codex ChatGPT 登录。

最终给出飞书首条绑定命令、闭环测试步骤和：

```text
@AI实战助手 /问 只回复：AI实战工作站连接成功
```
