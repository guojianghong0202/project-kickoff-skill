# AI实战飞书 GPT 工作站：Codex 本机部署任务书

你正在一台由用户本人授权的 Windows 10/11 台式机上工作。请在当前工作目录创建一个可运行、可审计的公司内部飞书机器人工作站。目标群名称固定为“AI实战”，机器人名称建议为“AI实战助手”。

## 最终目标

三位内部成员只需在飞书群里明确 `@AI实战助手`，即可：

1. 使用 OpenAI Responses API 做中文问答、文案、方案和文件理解；
2. 使用 `/执行 项目名 任务内容` 调用本机 Codex CLI，在白名单项目目录内检查、修改、测试和打包项目；
3. 查询项目、任务状态、额度，取消自己的任务，并把项目内交付文件发回飞书群；
4. 不需要公网 IP、域名、端口映射或云服务器，飞书事件通过 WebSocket 长连接由本机主动连接。

## 不可违反的边界

- 不把 ChatGPT 个人登录态共享给群成员。群内普通问答必须使用公司自己的 `OPENAI_API_KEY`，API 费用与 ChatGPT 套餐分开。
- 不把 API Key、飞书 App Secret、Cookie、浏览器凭据或密码写入源码、日志、Git 或群消息。
- 不允许群成员提交任意 CMD、PowerShell 或管理员命令。
- Codex 只能在配置的项目根目录及其项目子目录内写入；默认禁用任务网络访问。
- 不自动执行付款、转账、生产发布、对外群发、账号权限变更、关闭安全软件、大范围删除等高风险操作。
- 只服务可信内部成员。普通成员只能查看/取消自己提交的任务；首次绑定人可以看全部任务和诊断信息。
- 安装器不得读取或修改本任务无关的个人文件。

## 技术要求

- Node.js 22 或更高版本，ESM。
- 使用官方 `openai` Node SDK 和 Responses API；默认模型 `gpt-5.6-terra`，但允许通过 `.env` 修改。
- 飞书优先使用官方 `@larksuiteoapi/node-sdk`。可以先执行 `npm view @larksuite/channel version`；若该高层 Channel SDK 可正常安装并且其 API 与类型可用，可使用它简化 WebSocket、消息归一化、媒体下载、回复、重连和安全策略。若不可用，必须直接使用官方 node-sdk 的 `WSClient`、`EventDispatcher` 和 `Client` 实现同等能力。
- 依赖必须采用当前 npm 注册表可安装的稳定版本。不要写入不存在的版本号；生成 `package-lock.json`。
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
scripts/run-codex.ps1
scripts/run-worker.ps1
scripts/stop.ps1
scripts/status.mjs
scripts/start-hidden.vbs
src/index.mjs
src/config.mjs
src/openai-service.mjs
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

安装脚本以安全输入方式采集并写入：

```env
FEISHU_APP_ID=""
FEISHU_APP_SECRET=""
OPENAI_API_KEY=""
BIND_CODE="随机6位数字"
OPENAI_MODEL="gpt-5.6-terra"
OPENAI_REASONING="medium"
OPENAI_VERBOSITY="medium"
MAX_OUTPUT_TOKENS="12000"
PROJECT_ROOT="D:\公司项目"
CODEX_ENABLED="true"
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

没有 D 盘时，项目根目录默认 `%USERPROFILE%\公司项目`。

用 `icacls` 将 `.env`、`data` 和 `logs` 权限限制为当前 Windows 用户、SYSTEM 和 Administrators。日志必须对 Key、Secret 和绑定码做脱敏。

## 飞书应用与长连接

需要的最小租户权限：

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

`CREATE_FEISHU_APP.cmd` 应优先尝试使用当前可用 SDK 的设备码/二维码注册能力创建企业自建应用，预设名称“AI实战助手”。若当前 SDK 或租户不支持自动创建，则打开飞书开发者后台并生成清晰的 `SETUP_FEISHU_MANUAL.md`，引导用户创建应用、录入 App ID/App Secret、选择“使用长连接接收事件”、发布版本并把机器人加入群。

运行时要求：

- WebSocket 长连接；15 秒握手超时；断线自动重连；应用级保活；REST 请求超时。
- 私聊默认禁用，群消息必须明确 @机器人。
- 初次未绑定时，仅接受 `/绑定 6位码`；也可在群名精确等于“AI实战”时，由首个明确 @机器人的真人消息自动绑定。
- 绑定后只处理唯一群，其他群静默拒绝。
- 忽略机器人自己和其他机器人的消息，防止机器人循环。

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
/绑定 6位码
/解绑 6位码
/诊断
```

项目名含空格时支持中文或英文引号。

## 普通 GPT 问答

- 使用 Responses API；默认中文；每个“群 + 成员 + 话题”独立上下文。
- 使用 `previous_response_id` 延续会话；失效时自动重建一次。
- 图片以内联 data URL 发送；PDF、Word、Excel、PPT、文本和常见代码文件通过 Files API 以 `purpose: user_data` 上传，并作为 `input_file` 使用。
- 临时文件和远端文件 ID 定期清理；7 天无活动的会话清理。
- 使用发送者 ID 的 SHA-256 作为匿名化 `safety_identifier`。
- 回复过长时安全分片，不能因飞书单条消息限制而丢失结果。

## 本地 Codex 执行

`/执行` 只能解析为“白名单项目 + 自然语言任务”，绝不能提供裸 shell 命令入口。

项目白名单规则：

- `PROJECT_ROOT` 下的直接子文件夹自动成为项目；`config/projects.json` 可增加别名；
- 使用 `realpath` 和目录边界检查，防止 `..`、绝对路径、junction/symlink 越界；
- `/文件` 阻止 `.env`、`.git`、私钥、证书、密码库、凭据和浏览器数据。

调用 Codex CLI 时使用当前项目为工作目录，并采用：

```text
--ask-for-approval never
--sandbox workspace-write
exec
--cd <项目目录>
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

网络开关由 `.env` 控制，默认 false。不要使用 `--dangerously-bypass-approvals-and-sandbox`。

Codex 系统约束写入 `config/codex_instructions.md`：只读写当前项目、不读取密钥、不做高风险动作、先检查再修改、运行最相关测试、未验证必须明确、最终列出完成内容/修改文件/验证结果/风险/交付相对路径。

任务队列：

- 默认最大并发 2；同一个项目串行锁；同一 GPT 会话串行；
- 任务有 queued/running/completed/failed/cancelled；状态持久化；进程重启时把未完成任务标记失败；
- 支持 AbortController 取消和超时后终止完整进程树；
- 每人每日默认 50 个任务；保留最近 300 条任务；
- 任务完成后回复原消息，失败时给出可理解的原因，不把密钥或完整内部日志发群。

## Windows 安装与运行

`INSTALL_AND_CONFIGURE.cmd` 调用 `scripts/install.ps1`：

1. 检查 Node.js 22+；缺失时用 winget 安装，旧版本时用 winget upgrade；任何失败都必须停止并解释；
2. `npm install --omit=dev --ignore-scripts --no-audit --no-fund`；
3. 安全采集 OpenAI API Key、项目根目录、已有飞书凭据；
4. 生成随机绑定码并写 `.env`；
5. 收紧 ACL；
6. 创建 Windows 登录启动快捷方式；
7. 运行 smoke tests；
8. 创建桌面“启动、停止、查看状态、打开项目目录”快捷方式。

后台运行可用 VBS 隐藏窗口和一个带自动重启的 loop。电脑关机、断网或 Windows 用户注销时停止；显示器可以关闭。

## 测试和验收

必须实际执行：

```text
node --check src/*.mjs
node --check scripts/*.mjs
npm test
npm ls --depth=0
```

`tests/smoke.mjs` 至少覆盖：命令解析、带空格项目名、路径越界、敏感文件、危险任务拦截、任务队列锁/取消、状态持久化和中断恢复。

最终不要只写方案。必须创建所有文件、安装本地依赖、运行测试并修复失败，直到本地静态检查和 smoke tests 通过。最后输出：

1. 安装目录；
2. 生成文件清单；
3. 依赖版本；
4. 测试结果；
5. 用户仍需本人完成的动作（OpenAI API Key、飞书扫码/发布、Windows UAC）；
6. 飞书群首条测试命令：`@AI实战助手 /问 只回复：AI实战工作站连接成功`。
