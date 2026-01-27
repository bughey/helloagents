---
name: helloagents-v2
description: HelloAGENTS v2 纯 Skill：用 Evaluate→Analyze→Design→Develop 四阶段工作流 + 三层路由 + 方案包/知识库（helloagents/）把编程任务推进到“实现并验证”的终点；支持 ~auto/~plan/~exec/~init/~upgrade/~clean/~commit/~test/~review/~validate/~rollback/~help 等命令。
license: Apache-2.0
compatibility: 适用于支持 Agent Skills 的客户端（如 Codex CLI、Claude Code 等）；需要可读写项目文件；可选需要 Python（用于 scripts/ 自动化）。
metadata:
  language: zh-CN
  author: helloagents
  version: "2.0.2"
  router_date: "2026-01-22"
---

# HelloAGENTS v2（统一 Skill）

本目录是 HelloAGENTS v2 的“纯 Skill”打包：将原本面向不同客户端（AGENTS.md / CLAUDE.md 等）的主规则与模块化 references/、scripts/、assets/ 收敛为一个可分发的 Agent Skill。

## 显式调用（可选）

当用户通过 `/helloagents-v2` 或 `$helloagents-v2` 显式调用本技能时，输出以下欢迎信息（随后按 `references/RULES.md` 路由与阶段流程继续）：

```
💡【HelloAGENTS v2】- 技能已激活

智能工作流系统：Evaluate → Analyze → Design → Develop

### 可用命令

| 命令 | 功能 |
|------|------|
| `~auto` | 全授权命令 |
| `~plan` | 执行到方案设计 |
| `~exec` | 执行方案包 |
| `~init` | 初始化知识库 |
| `~upgrade` | 升级知识库 |
| `~clean` | 清理遗留方案包 |
| `~commit` | Git 提交 |
| `~test` | 运行测试 |
| `~review` | 代码审查 |
| `~validate` | 验证知识库 |
| `~rollback` | 智能回滚 |
| `~help` | 显示帮助 |

────
🔄 下一步: 输入命令或描述你的需求
```

## 必读：渐进披露加载顺序（推荐）

为避免一次性加载过多规则导致上下文浪费，按需读取：

1. 先阅读主规则与路由：`references/RULES.md`
2. 进入对应阶段时再读阶段模块：
   - 需求评估：`references/stages/evaluate.md`
   - 项目分析：`references/stages/analyze.md`
   - 方案设计：`references/stages/design.md`
   - 开发实施：`references/stages/develop.md`
   - 微调模式：`references/stages/tweak.md`
3. 使用命令/服务/规则模块时按需读取：
   - 命令：`references/functions/*.md`
   - 知识库与模板：`references/services/*.md`
   - 状态/规模/方案包/工具：`references/rules/*.md`

## 关键约束（摘要）

- 输出语言：默认简体中文（除代码标识符/技术术语/路径/命令等）
- 工作流：Evaluate（评分+追问）→（必要时）Analyze → Design → Develop；并按复杂度选择 tweak/lite/standard
- SSOT：变更后的项目知识沉淀到用户项目内 `helloagents/`（知识库/方案包/归档）
- 脚本与模板：可选用 `scripts/` 自动化；模板在 `assets/templates/`（调用规范见 `references/rules/tools.md`）
