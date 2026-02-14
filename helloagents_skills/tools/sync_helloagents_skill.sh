#!/usr/bin/env bash
set -euo pipefail

SOURCE_DEFAULT="/Users/hey/dev/code/vibe/helloagents"
TARGET_DEFAULT="/Users/hey/dev/code/vibe/myhelloagents/helloagents_skills/helloagents_v22"

SOURCE="$SOURCE_DEFAULT"
TARGET="$TARGET_DEFAULT"
DRY_RUN=0
NO_VALIDATE=0
SYNC_TOOL_VERSION="1.0.0"

usage() {
  cat <<'EOF'
Usage: sync_helloagents_skill.sh [--source <path>] [--target <path>] [--dry-run] [--no-validate]

Options:
  --source <path>      Source helloagents repository path.
  --target <path>      Target skill directory path.
  --dry-run            Preview rsync operations without writing files.
  --no-validate        Skip validate_helloagents_skill.sh after sync.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      SOURCE="${2:-}"
      shift 2
      ;;
    --target)
      TARGET="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --no-validate)
      NO_VALIDATE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

for cmd in rsync python3; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
done

if [[ ! -d "$SOURCE" ]]; then
  echo "Source path does not exist: $SOURCE" >&2
  exit 1
fi

if [[ ! -f "$SOURCE/AGENTS.md" ]]; then
  echo "Source AGENTS.md not found: $SOURCE/AGENTS.md" >&2
  exit 1
fi

mkdir -p "$TARGET/references" "$TARGET/helloagents" "$TARGET/scripts/rlm"

RSYNC_FLAGS=(-a --delete)
if [[ "$DRY_RUN" -eq 1 ]]; then
  RSYNC_FLAGS+=(--dry-run)
fi

sync_dir() {
  local src="$1"
  local dst="$2"
  mkdir -p "$dst"
  rsync "${RSYNC_FLAGS[@]}" "$src" "$dst"
}

echo "[sync] source: $SOURCE"
echo "[sync] target: $TARGET"

# AGENTS router
rsync "${RSYNC_FLAGS[@]}" "$SOURCE/AGENTS.md" "$TARGET/references/AGENTS.md"

# Core markdown modules
for sub in functions stages services rules templates user; do
  sync_dir "$SOURCE/helloagents/$sub/" "$TARGET/helloagents/$sub/"
done

# RLM resources
sync_dir "$SOURCE/helloagents/rlm/roles/" "$TARGET/helloagents/rlm/roles/"
sync_dir "$SOURCE/helloagents/rlm/schemas/" "$TARGET/helloagents/rlm/schemas/"

# Python scripts
sync_dir "$SOURCE/helloagents/scripts/" "$TARGET/scripts/"
mkdir -p "$TARGET/scripts/rlm"
rsync "${RSYNC_FLAGS[@]}" "$SOURCE/helloagents/rlm/session.py" "$TARGET/scripts/rlm/session.py"
rsync "${RSYNC_FLAGS[@]}" "$SOURCE/helloagents/rlm/shared_tasks.py" "$TARGET/scripts/rlm/shared_tasks.py"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "[sync] dry run complete (no files written)."
  exit 0
fi

echo "[sync] applying pure-skill path rewrites..."
python3 - "$TARGET" <<'PY'
import json
import re
import sys
from pathlib import Path

target = Path(sys.argv[1])

agents_path = target / "references" / "AGENTS.md"
tools_path = target / "helloagents" / "rules" / "tools.md"
template_utils_path = target / "scripts" / "template_utils.py"


def append_skill_overrides(agents_file: Path) -> None:
    text = agents_file.read_text(encoding="utf-8")
    marker = "## G0 | Pure Skill Mode Overrides (CRITICAL)"
    block = """
---

## G0 | Pure Skill Mode Overrides (CRITICAL)

在纯 Skill 部署中，下列路径变量覆盖 G7 中的安装器路径说明：

```yaml
{HELLOAGENTS_ROOT}: 当前 Skill 根目录（即包含 SKILL.md 的目录）
{CWD}: 当前工作目录
{KB_ROOT}: 知识库根目录（默认 {CWD}/.helloagents）
{TEMPLATES_DIR}: {HELLOAGENTS_ROOT}/helloagents/templates
{SCRIPTS_DIR}: {HELLOAGENTS_ROOT}/scripts
```

脚本路径覆盖：
- session.py: `python -X utf8 '{SCRIPTS_DIR}/rlm/session.py' --info|--list|--cleanup [<hours>]`
- shared_tasks.py: `python -X utf8 '{SCRIPTS_DIR}/rlm/shared_tasks.py' --status|--list|--available|--claim <id> --owner <sid>|--complete <id>|--add '<subject>' [--blocked-by <ids>]`
""".strip()

    if marker in text:
        text = re.sub(
            r"\n---\n\n## G0 \| Pure Skill Mode Overrides \(CRITICAL\).*?\Z",
            "\n\n" + block + "\n",
            text,
            flags=re.DOTALL,
        )
    else:
        text = text.rstrip() + "\n\n" + block + "\n"

    agents_file.write_text(text, encoding="utf-8")


def patch_tools_md(tools_file: Path) -> None:
    text = tools_file.read_text(encoding="utf-8")
    text = text.replace(
        "python -X utf8 '{HELLOAGENTS_ROOT}/rlm/session.py' --info|--list|--cleanup [<hours>]",
        "python -X utf8 '{SCRIPTS_DIR}/rlm/session.py' --info|--list|--cleanup [<hours>]",
    )
    text = text.replace(
        "python -X utf8 '{HELLOAGENTS_ROOT}/rlm/shared_tasks.py' --status|--list|--available|--claim <id> --owner <sid>|--complete <id>|--add '<subject>' [--blocked-by <ids>]",
        "python -X utf8 '{SCRIPTS_DIR}/rlm/shared_tasks.py' --status|--list|--available|--claim <id> --owner <sid>|--complete <id>|--add '<subject>' [--blocked-by <ids>]",
    )
    tools_file.write_text(text, encoding="utf-8")


def patch_template_utils(template_file: Path) -> None:
    text = template_file.read_text(encoding="utf-8")
    old = 'return Path(__file__).parent.parent / "templates"'
    new = (
        'base = Path(__file__).resolve().parent.parent\n'
        '    skill_templates = base / "helloagents" / "templates"\n'
        '    if skill_templates.exists():\n'
        '        return skill_templates\n'
        '    return base / "templates"'
    )
    if old in text:
        text = text.replace(old, new)
    template_file.write_text(text, encoding="utf-8")


append_skill_overrides(agents_path)
patch_tools_md(tools_path)
patch_template_utils(template_utils_path)
PY

find "$TARGET/scripts" -type d -name "__pycache__" -prune -exec rm -rf {} +

SOURCE_REPO="$SOURCE"
SOURCE_COMMIT="unknown"
SOURCE_BRANCH="unknown"

if command -v git >/dev/null 2>&1 && git -C "$SOURCE" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  SOURCE_REPO="$(git -C "$SOURCE" config --get remote.origin.url || echo "$SOURCE")"
  SOURCE_COMMIT="$(git -C "$SOURCE" rev-parse HEAD || echo unknown)"
  SOURCE_BRANCH="$(git -C "$SOURCE" rev-parse --abbrev-ref HEAD || echo unknown)"
fi

FILE_COUNT="$(find "$TARGET" -type f | wc -l | tr -d ' ')"

python3 - "$TARGET" "$SOURCE_REPO" "$SOURCE_COMMIT" "$SOURCE_BRANCH" "$FILE_COUNT" "$SYNC_TOOL_VERSION" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

target = Path(sys.argv[1])
source_repo = sys.argv[2]
source_commit = sys.argv[3]
source_branch = sys.argv[4]
file_count = int(sys.argv[5])
sync_tool_version = sys.argv[6]

manifest = {
    "source_repo": source_repo,
    "source_commit": source_commit,
    "source_branch": source_branch,
    "synced_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "file_count": file_count,
    "sync_tool_version": sync_tool_version,
}

(target / ".sync-manifest.json").write_text(
    json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)
PY

if [[ "$NO_VALIDATE" -eq 0 ]]; then
  "$(dirname "$0")/validate_helloagents_skill.sh" --target "$TARGET"
fi

echo "[sync] complete."
