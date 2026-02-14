---
name: helloagents_v22
description: High-fidelity HelloAGENTS workflow skill for complex engineering tasks with staged routing, RLM sub-agent orchestration, knowledge-base maintenance, and safety rules. Use when users want HelloAGENTS-style process control in pure skill form.
---

# HelloAGENTS v2.2 Skill

This skill ports HelloAGENTS v2.2 into a pure-skill layout.

## When to use

Use this skill when the user wants:
- HelloAGENTS-style staged workflow (evaluate/analyze/design/develop/verify)
- RLM role orchestration and task decomposition
- structured KB and plan package operations
- strict safety and routing rules

## Pure Skill mode boundaries

- This skill includes rules, templates, role definitions, and scripts.
- Installer features from the package version are out of scope here:
  - automatic CLI hook injection
  - package install/update lifecycle commands

If a workflow needs hooks, configure them manually in the target CLI.

## Skill resources

- Main router/rules reference:
  - `references/AGENTS.md`
- Modular docs loaded on demand:
  - `helloagents/functions/`
  - `helloagents/stages/`
  - `helloagents/services/`
  - `helloagents/rules/`
  - `helloagents/rlm/roles/`
  - `helloagents/templates/`
- Script tools:
  - `scripts/*.py`
  - `scripts/rlm/session.py`
  - `scripts/rlm/shared_tasks.py`

## Path conventions in this skill

- `{HELLOAGENTS_ROOT}`: this skill root directory (the folder that contains this `SKILL.md`)
- `{TEMPLATES_DIR}`: `{HELLOAGENTS_ROOT}/helloagents/templates`
- `{SCRIPTS_DIR}`: `{HELLOAGENTS_ROOT}/scripts`

For path specifics and routing details, load `references/AGENTS.md` first.
