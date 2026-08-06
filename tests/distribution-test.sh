#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"

/usr/bin/python3 - "$ROOT" <<'PY'
import json
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
plugin = json.loads((root / ".claude-plugin/plugin.json").read_text())
marketplace = json.loads((root / ".claude-plugin/marketplace.json").read_text())
skill = (root / "skills/breakdown-connectivity/SKILL.md").read_text()
readme = (root / "README.md").read_text()

assert plugin["name"] == "breakdown-connectivity"
assert marketplace["name"] == "breakdown"
assert len(marketplace["plugins"]) == 1
entry = marketplace["plugins"][0]
assert entry["name"] == plugin["name"]
assert entry["source"] == "./"
assert re.search(r"^name: breakdown-connectivity$", skill, re.MULTILINE)

commands = (
    "npx skills add PeaceCraft-LLC/breakdown-agent-connectivity",
    "claude plugin marketplace add PeaceCraft-LLC/breakdown-agent-connectivity",
    "claude plugin install breakdown-connectivity@breakdown",
)
for command in commands:
    assert command in readme
PY

if command -v claude >/dev/null 2>&1; then
    claude plugin validate "$ROOT"
fi

printf 'distribution tests passed\n'
