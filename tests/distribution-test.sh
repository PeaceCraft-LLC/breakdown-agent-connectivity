#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"

/usr/bin/python3 - "$ROOT" <<'PY'
import json
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
portable = json.loads((root / "plugin.json").read_text())
schema = json.loads((root / "tests/fixtures/agent-plugin-1.0.0.schema.json").read_text())
plugin = json.loads((root / ".claude-plugin/plugin.json").read_text())
marketplace = json.loads((root / ".claude-plugin/marketplace.json").read_text())
skill = (root / "skills/breakdown-connectivity/SKILL.md").read_text()
readme = (root / "README.md").read_text()


def validate(value, rule, path="plugin.json"):
    types = {
        "array": list,
        "object": dict,
        "string": str,
    }
    if "type" in rule:
        assert isinstance(value, types[rule["type"]]), f"{path}: expected {rule['type']}"
    if "const" in rule:
        assert value == rule["const"], f"{path}: expected {rule['const']!r}"
    if isinstance(value, str):
        assert len(value) >= rule.get("minLength", 0), f"{path}: string is too short"
        assert len(value) <= rule.get("maxLength", len(value)), f"{path}: string is too long"
        if "pattern" in rule:
            assert re.fullmatch(rule["pattern"], value), f"{path}: does not match schema pattern"
    if isinstance(value, list) and "items" in rule:
        for index, item in enumerate(value):
            validate(item, rule["items"], f"{path}[{index}]")
    if isinstance(value, dict):
        for required in rule.get("required", []):
            assert required in value, f"{path}: missing required field {required!r}"
        properties = rule.get("properties", {})
        if rule.get("additionalProperties") is False:
            unknown = value.keys() - properties.keys()
            assert not unknown, f"{path}: unknown fields {sorted(unknown)!r}"
        for key, item in value.items():
            child_rule = properties.get(key)
            if child_rule is None and isinstance(rule.get("additionalProperties"), dict):
                child_rule = rule["additionalProperties"]
            if child_rule is not None:
                validate(item, child_rule, f"{path}.{key}")


assert schema["$id"] == "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json"
validate(portable, schema)
assert portable["name"] == "breakdown-connectivity"
assert plugin["name"] == "breakdown-connectivity"
assert portable["version"] == plugin["version"]
assert re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", portable["version"])
assert marketplace["name"] == "breakdown"
assert len(marketplace["plugins"]) == 1
entry = marketplace["plugins"][0]
assert entry["name"] == plugin["name"]
assert entry["source"] == "./"
assert not pathlib.PurePosixPath(entry["source"]).is_absolute()
assert ".." not in pathlib.PurePosixPath(entry["source"]).parts

for manifest in (portable, plugin):
    assert manifest["author"]["name"] == "Breakdown"
    assert manifest["homepage"] == "https://breakdown.live/for-agents/"
    assert manifest["repository"] == "https://github.com/PeaceCraft-LLC/breakdown-agent-connectivity"
    assert manifest["license"] == "Apache-2.0"
    assert isinstance(manifest["description"], str)
    assert isinstance(manifest["keywords"], list)
    assert all(isinstance(keyword, str) for keyword in manifest["keywords"])

assert isinstance(entry["description"], str)
assert isinstance(entry["tags"], list)
assert all(isinstance(tag, str) for tag in entry["tags"])

skill_paths = sorted(path.relative_to(root).as_posix() for path in root.rglob("SKILL.md"))
assert skill_paths == ["skills/breakdown-connectivity/SKILL.md"]
assert re.search(r"^name: breakdown-connectivity$", skill, re.MULTILINE)

commands = (
    "npx skills add PeaceCraft-LLC/breakdown-agent-connectivity",
    "claude plugin marketplace add PeaceCraft-LLC/breakdown-agent-connectivity",
    "claude plugin install breakdown-connectivity@breakdown",
    "https://cursor.com/docs/reference/plugins#submitting-a-plugin",
)
for command in commands:
    assert command in readme
PY

if command -v claude >/dev/null 2>&1; then
    claude plugin validate "$ROOT" --strict
fi

printf 'distribution tests passed\n'
