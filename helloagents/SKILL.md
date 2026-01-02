---
name: helloagents
description: HelloAGENTS：通过统一复杂度路由 + 三阶段工作流（需求分析→方案设计→开发实施），把 AI 编程任务转为结构化、可追溯、生产就绪的交付；适用于需要需求评分、方案包/知识库管理与安全防护（EHRB）的代码变更。
compatibility: 适用于支持 Agent Skills 的客户端（如 Codex CLI、Claude Code）；需要可读写项目文件、可运行 shell 命令（可选）与可访问互联网（可选，用于查询文档）。
metadata:
  language: zh-CN
  version: "2025-12-18.2"
  architecture: Unified Complexity Router + Multi-Stage Skills
---

# HelloAGENTS（统一 Skill）

本 Skill 是 HelloAGENTS 的“统一入口”：将原本基于 `AGENTS.md` / `CLAUDE.md` + 多子技能的规则集，收敛为一个 Agent Skills 规范的单 Skill，并通过 `references/` 做渐进披露，保持功能一致。

## 使用时机

- 需要对代码库做变更（修复/迭代/重构/新功能）且希望有可追溯工作流
- 需求可能模糊，需要先评分与追问再落地实现
- 需要自动识别风险（EHRB）并在必要时升级流程
- 需要把项目知识沉淀到 `helloagents/` 知识库（SSOT）

## 必读：渐进披露加载顺序

为避免一次性加载超大规则集导致上下文浪费，按下列顺序读取：

1. 先阅读完整规则集：`references/RULES.md`
2. 进入对应阶段时再阅读阶段细则：
   - 需求分析：`references/analyze.md`
   - 方案设计：`references/design.md`
   - 开发实施：`references/develop.md`
3. 涉及知识库/模板时按需阅读：
   - 知识库：`references/kb.md`
   - 文档模板：`references/templates.md`

## 统一映射（与原库行为一致）

本统一 Skill 已将原规则中对子 Skill 的引用统一为 `references/*.md`。若你在旧版内容中仍看到 “读取 `analyze`/`design`/`develop`/`kb`/`templates` Skill” 的表述，可按下列映射理解：

- `analyze` → `references/analyze.md`
- `design` → `references/design.md`
- `develop` → `references/develop.md`
- `kb` → `references/kb.md`
- `templates` → `references/templates.md`

## 关键约束（摘要）

- 输出语言：默认简体中文（除代码标识符/技术术语等例外）
- 工作流：路由判定 →（必要时）需求分析 → 方案设计 → 开发实施
- 文档与知识库：代码变更后必须同步更新 `helloagents/` 下的知识库（SSOT）
- 安全：检测到 EHRB 信号时采用更保守路径，禁止高风险无确认操作
- 输出格式：阶段完成/异常/问答均使用统一模板（详见 `references/RULES.md`）
