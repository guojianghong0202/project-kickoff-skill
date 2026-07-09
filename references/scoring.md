# 候选项目评分模型

用法：当用户给出多个候选项目、趋势条目、GitHub/Hacker News/Product Hunt/arXiv/RSS 内容，并问“哪个值得做”“哪个适合启动”“帮我排序/打分”时使用。本模型只负责筛选优先级，选出候选后仍要走项目启动流程。

## 目录

1. 总分
2. 维度解释
3. 示例
4. 报告 limit 分配规则
5. 输出格式

## 总分

```text
总分 = freshness + relevance + velocity + discussion + novelty
```

满分 100：

| 维度 | 分值 | 含义 |
|---|---:|---|
| freshness | 20 | 时间分。越新越高，刚发布接近 20 分，25 小时后基本 0 分。 |
| relevance | 25 | AI/agent 相关性。标题、摘要、tags 命中 AI、LLM、agent、RAG、MCP、inference、copilot 等关键词就加分。 |
| velocity | 30 | 热度分。GitHub 看 stars/forks，HN 看 points，Product Hunt 看 votes。使用 log 思路，避免大项目碾压小而新的项目。 |
| discussion | 15 | 讨论分。主要看 comments、issues、HN comments、PH comments 等。 |
| novelty | 10 | 高价值方向分。命中 agent、MCP、local、open source、developer tool、benchmark 等方向给高分。 |

## 维度解释

### freshness，0-20

- 1 小时内：18-20
- 3 小时内：16-18
- 6 小时内：12-16
- 12 小时内：8-12
- 24 小时内：1-8
- 超过 25 小时：0-1

如果没有发布时间，用“最近更新时间”“首次发现时间”或用户提供的上下文估算，并标注依据不足。

### relevance，0-25

高分关键词：

- ai
- llm
- agent
- coding agent
- rag
- mcp
- inference
- copilot
- model
- eval
- benchmark
- local ai

评分原则：

- 命中多个核心词且主题就是 AI/agent：20-25
- 只命中 AI 周边或开发者工具：10-20
- 和 AI 基本无关：0-8

### velocity，0-30

按来源取不同热度信号：

- GitHub：stars、forks、issues、watchers。
- Hacker News：points。
- Product Hunt：votes。
- arXiv：通常没有热度，除非用户提供转发、讨论、引用信号。
- RSS：用来源权威性、转发量或用户提供的热度信号估算。

使用 log 思路，不要线性比较。1000 stars 不等于 100 stars 的 10 倍价值。

参考锚点：

- GitHub 100+ stars 且刚发布：20-30
- GitHub 10-100 stars：10-22
- GitHub 低 stars 但方向极强：5-15
- 无热度信号：0-5

### discussion，0-15

- 讨论很活跃，评论多且有实质问题：10-15
- 有少量评论或 issue：4-10
- 没有 comments：0

注意：GitHub 项目没有 comments 时可以给 0，不要硬补。

### novelty，0-10

高价值方向：

- agent
- MCP
- local
- open source
- developer tool
- benchmark
- eval
- workflow automation
- coding agent

评分原则：

- 命中多个高价值方向且组合新：8-10
- 命中一个高价值方向：5-8
- 常规应用层包装：2-5
- 与高价值方向无关：0-2

## 示例

### 高分例子

```text
标题：local MCP coding agent
stars：120
forks：10
发布时间：3 小时前
comments：无
```

参考评分：

- freshness：17.6 / 20
- relevance：25 / 25，命中 MCP、coding agent、agent
- velocity：28 / 30，120 stars + 10 forks，且很新
- discussion：0 / 15，GitHub 没 comments
- novelty：10 / 10，命中 MCP、local、agent

总分：约 80+

### 反例

```text
标题：CSS button library
stars：300
发布时间：1 小时前
```

参考判断：

- freshness 高
- velocity 高
- relevance 低
- novelty 低

它不是 AI/agent/MCP/RAG 方向，即使 stars 高，也不应排在 AI 项目启动候选前面。

## 报告 limit 分配规则

当用户要求 `--limit 30` 或“给我 Top 30”时，不要直接取全局最高 30 个。先按来源分组，再平均分配名额。

常见分组：

- GitHub 核心项目
- GitHub 趋势
- Hacker News
- Product Hunt
- arXiv
- RSS 官方资讯
- RSS 二级站点聚合

示例：

```text
--limit 30
当天有 6 个分组有内容
30 / 6 = 每组 5 条
```

输出结构：

- GitHub 核心项目 Top 5
- GitHub 趋势 Top 5
- Hacker News Top 5
- Product Hunt Top 5
- arXiv Top 5
- RSS 官方资讯 Top 5

这样避免单一来源霸榜。打分层决定每条内容在自己组里谁排前；报告层决定每个来源组展示多少条。

## 输出格式

```md
| 排名 | 候选 | 来源 | 总分 | freshness | relevance | velocity | discussion | novelty | 为什么值得/不值得启动 |
|---:|---|---|---:|---:|---:|---:|---:|---:|---|
| 1 | local MCP coding agent | GitHub | 80.6 | 17.6 | 25 | 28 | 0 | 10 | 新、强 AI 相关、命中 MCP/local/agent |
```

输出后补一句：

```text
建议优先对 Top 1-3 进入项目启动流程，下一步判断 S/M/L，并用两轮访谈补齐目标、范围、成功指标和 owner。
```
