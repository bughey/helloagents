#!/usr/bin/env bash
set -euo pipefail

TARGET_DEFAULT="/Users/hey/dev/code/vibe/myhelloagents/helloagents_skills/helloagents_v22"
TARGET="$TARGET_DEFAULT"

usage() {
  cat <<'EOF'
Usage: validate_helloagents_skill.sh [--target <path>]
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET="${2:-}"
      shift 2
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

errors=0

fail() {
  local msg="$1"
  echo "[validate][FAIL] $msg" >&2
  errors=$((errors + 1))
}

pass() {
  local msg="$1"
  echo "[validate][OK] $msg"
}

require_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    pass "file exists: $path"
  else
    fail "missing file: $path"
  fi
}

require_dir() {
  local path="$1"
  if [[ -d "$path" ]]; then
    pass "directory exists: $path"
  else
    fail "missing directory: $path"
  fi
}

if [[ ! -d "$TARGET" ]]; then
  echo "Target directory does not exist: $TARGET" >&2
  exit 1
fi

require_file "$TARGET/SKILL.md"
require_file "$TARGET/references/AGENTS.md"

require_dir "$TARGET/helloagents/functions"
require_dir "$TARGET/helloagents/stages"
require_dir "$TARGET/helloagents/services"
require_dir "$TARGET/helloagents/rules"
require_dir "$TARGET/helloagents/rlm/roles"
require_dir "$TARGET/helloagents/templates"
require_dir "$TARGET/scripts"
require_dir "$TARGET/scripts/rlm"

require_file "$TARGET/helloagents/templates/INDEX.md"
require_file "$TARGET/helloagents/templates/context.md"
require_file "$TARGET/helloagents/templates/CHANGELOG.md"
require_file "$TARGET/helloagents/templates/plan/proposal.md"
require_file "$TARGET/helloagents/templates/plan/tasks.md"
require_file "$TARGET/scripts/rlm/session.py"
require_file "$TARGET/scripts/rlm/shared_tasks.py"

if grep -q "Pure Skill Mode Overrides" "$TARGET/references/AGENTS.md"; then
  pass "AGENTS skill override section found"
else
  fail "AGENTS skill override section missing"
fi

if grep -q "{SCRIPTS_DIR}/rlm/session.py" "$TARGET/helloagents/rules/tools.md" && \
   grep -q "{SCRIPTS_DIR}/rlm/shared_tasks.py" "$TARGET/helloagents/rules/tools.md"; then
  pass "rules/tools.md script paths patched"
else
  fail "rules/tools.md script paths not patched"
fi

if grep -q 'skill_templates = base / "helloagents" / "templates"' "$TARGET/scripts/template_utils.py"; then
  pass "template_utils.py skill template lookup patched"
else
  fail "template_utils.py skill template lookup missing"
fi

echo "[validate] compiling python scripts..."
while IFS= read -r py_file; do
  if python3 - "$py_file" <<'PY' >/dev/null 2>&1
from pathlib import Path
import sys

path = Path(sys.argv[1])
source = path.read_text(encoding="utf-8")
compile(source, str(path), "exec")
PY
  then
    pass "python syntax ok: $py_file"
  else
    fail "python syntax error: $py_file"
  fi
done < <(find "$TARGET/scripts" -type f -name "*.py" | sort)

echo "[validate] checking AGENTS module path references..."
python3 - "$TARGET" <<'PY'
import re
import sys
from pathlib import Path

target = Path(sys.argv[1])
agents = (target / "references" / "AGENTS.md").read_text(encoding="utf-8")

matches = sorted(set(re.findall(
    r"(?:functions|services|rules|stages|templates|rlm/roles)/[A-Za-z0-9_\-{}./]+\.md",
    agents,
)))

missing = []
for rel in matches:
    if "{" in rel:
        continue
    path = target / "helloagents" / rel
    if not path.exists():
        missing.append(rel)

if missing:
    print("[validate][PY][FAIL] missing AGENTS references:")
    for item in missing:
        print(f"- {item}")
    sys.exit(2)

print("[validate][PY][OK] AGENTS static references resolved")
PY
py_status=$?
if [[ $py_status -ne 0 ]]; then
  errors=$((errors + 1))
fi

if [[ $errors -gt 0 ]]; then
  echo "[validate] failed with $errors issue(s)." >&2
  exit 1
fi

echo "[validate] success."
