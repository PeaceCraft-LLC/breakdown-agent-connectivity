#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
SCRIPT="$ROOT/skills/breakdown-connectivity/scripts/setup-breakdown.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT HUP INT TERM

FAKE_BIN="$TMP/bin"
mkdir -p "$FAKE_BIN" "$TMP/Applications/Breakdown/Breakdown.app/Contents/MacOS" "$TMP/home/Downloads" "$TMP/home/Library/Application Support/Breakdown"
touch "$TMP/Applications/Breakdown/Breakdown.app/Contents/MacOS/BreakdownMCPBridge"
cat >"$TMP/home/Library/Application Support/Breakdown/local-mcp-server.json" <<'EOF'
{"url":"http://127.0.0.1:30577/mcp","headers":{"Authorization":"Bearer fixture"}}
EOF
chmod +x "$TMP/Applications/Breakdown/Breakdown.app/Contents/MacOS/BreakdownMCPBridge"

cat >"$FAKE_BIN/uname" <<'EOF'
#!/bin/sh
printf 'Darwin\n'
EOF

cat >"$FAKE_BIN/sw_vers" <<'EOF'
#!/bin/sh
printf '%s\n' "${FAKE_MACOS_VERSION:-15.5}"
EOF

cat >"$FAKE_BIN/curl" <<'EOF'
#!/bin/sh
output=""
while [ "$#" -gt 0 ]; do
    if [ "$1" = "--output" ]; then
        output="$2"
        shift 2
    else
        shift
    fi
done
printf '%s\n' "$output" >>"$FAKE_CURL_LOG"
printf 'signed package fixture\n' >"$output"
EOF

cat >"$FAKE_BIN/pkgutil" <<'EOF'
#!/bin/sh
if [ "${FAKE_BAD_SIGNATURE:-0}" = "1" ]; then
    printf 'Package "Developer ID Installer: Joel Mulkey (J7JF4A4BQ3).pkg":\n'
    printf '   1. Developer ID Installer: Someone Else (AAAAAAAAAA)\n'
else
    printf 'Package "Breakdown.pkg":\n'
    printf '   1. Developer ID Installer: Joel Mulkey (J7JF4A4BQ3)\n'
fi
EOF

cat >"$FAKE_BIN/open" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$FAKE_LOG"
EOF

cat >"$FAKE_BIN/pgrep" <<'EOF'
#!/bin/sh
[ "$1" = "-U" ] && [ "$3" = "-x" ] && [ "$4" = "BreakdownMenuBarApp" ]
EOF

cat >"$FAKE_BIN/codesign" <<'EOF'
#!/bin/sh
case "$1" in
    --verify)
        exit 0
        ;;
    -dv)
        printf 'Identifier=com.breakdown.menu\n' >&2
        if [ "${FAKE_BAD_APP_TEAM:-0}" = "1" ]; then
            printf 'TeamIdentifier=AAAAAAAAAA\n' >&2
        else
            printf 'TeamIdentifier=J7JF4A4BQ3\n' >&2
        fi
        ;;
esac
EOF

cat >"$FAKE_BIN/spctl" <<'EOF'
#!/bin/sh
exit 0
EOF

cat >"$FAKE_BIN/codex" <<'EOF'
#!/bin/sh
printf 'codex %s\n' "$*" >>"$FAKE_LOG"
EOF

chmod +x "$FAKE_BIN"/*

export PATH="$FAKE_BIN:/usr/bin:/bin"
export HOME="$TMP/home"
export FAKE_LOG="$TMP/actions.log"
export FAKE_CURL_LOG="$TMP/curl-paths.log"
export BREAKDOWN_APP_PATH="$TMP/Applications/Breakdown/Breakdown.app"

status="$($SCRIPT status)"
printf '%s\n' "$status" | grep -F 'platform=macos' >/dev/null
printf '%s\n' "$status" | grep -F 'platform_supported=true' >/dev/null
printf '%s\n' "$status" | grep -F 'app_installed=true' >/dev/null
printf '%s\n' "$status" | grep -F 'app_running=true' >/dev/null
printf '%s\n' "$status" | grep -F 'bridge_installed=true' >/dev/null
printf '%s\n' "$status" | grep -F 'mcp_discovery_status=configured' >/dev/null
printf '%s\n' "$status" | grep -F 'codex_available=true' >/dev/null
printf '%s\n' "$status" | grep -F 'codex_configured=true' >/dev/null

printf '{"disabled": true}\n' >"$HOME/Library/Application Support/Breakdown/local-mcp-server.json"
disabled_status="$($SCRIPT status)"
printf '%s\n' "$disabled_status" | grep -F 'mcp_discovery_status=disabled' >/dev/null
printf '{}\n' >"$HOME/Library/Application Support/Breakdown/local-mcp-server.json"
invalid_status="$($SCRIPT status)"
printf '%s\n' "$invalid_status" | grep -F 'mcp_discovery_status=invalid' >/dev/null
printf 'not json\n' >"$HOME/Library/Application Support/Breakdown/local-mcp-server.json"
malformed_status="$($SCRIPT status)"
printf '%s\n' "$malformed_status" | grep -F 'mcp_discovery_status=invalid' >/dev/null
: >"$HOME/Library/Application Support/Breakdown/local-mcp-server.json"
empty_status="$($SCRIPT status)"
printf '%s\n' "$empty_status" | grep -F 'mcp_discovery_status=invalid' >/dev/null
cat >"$HOME/Library/Application Support/Breakdown/local-mcp-server.json" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict>
<key>url</key><string>http://127.0.0.1:30577/mcp</string>
<key>headers</key><dict><key>authorization</key><string>Bearer fixture</string></dict>
</dict></plist>
EOF
xml_status="$($SCRIPT status)"
printf '%s\n' "$xml_status" | grep -F 'mcp_discovery_status=invalid' >/dev/null
cat >"$HOME/Library/Application Support/Breakdown/local-mcp-server.json" <<'EOF'
{"url":"http://127.0.0.1:30577/mcp","headers":{"authorization":"Bearer fixture"},}
EOF
trailing_comma_status="$($SCRIPT status)"
printf '%s\n' "$trailing_comma_status" | grep -F 'mcp_discovery_status=invalid' >/dev/null
cat >"$HOME/Library/Application Support/Breakdown/local-mcp-server.json" <<'EOF'
{"url":"http://127.0.0.1:99999/mcp","headers":{"authorization":"Bearer fixture"}}
EOF
invalid_port_status="$($SCRIPT status)"
printf '%s\n' "$invalid_port_status" | grep -F 'mcp_discovery_status=invalid' >/dev/null
cat >"$HOME/Library/Application Support/Breakdown/local-mcp-server.json" <<'EOF'
{"url":"http://127.0.0.1:30577/mcp","headers":{"authorization":"junk"}}
EOF
invalid_auth_status="$($SCRIPT status)"
printf '%s\n' "$invalid_auth_status" | grep -F 'mcp_discovery_status=invalid' >/dev/null
printf '{"url":"http://127.0.0.1:30577/mcp","headers":{"Authorization":"Bearer abc\\tdef"}}\n' >"$HOME/Library/Application Support/Breakdown/local-mcp-server.json"
whitespace_auth_status="$($SCRIPT status)"
printf '%s\n' "$whitespace_auth_status" | grep -F 'mcp_discovery_status=invalid' >/dev/null
rm "$HOME/Library/Application Support/Breakdown/local-mcp-server.json"
missing_status="$($SCRIPT status)"
printf '%s\n' "$missing_status" | grep -F 'mcp_discovery_status=missing' >/dev/null
cat >"$HOME/Library/Application Support/Breakdown/local-mcp-server.json" <<'EOF'
{"url":"http://127.0.0.1:30577/mcp","headers":{"Authorization":"Bearer fixture"}}
EOF

unsupported_status="$(FAKE_MACOS_VERSION=12.7 "$SCRIPT" status)"
printf '%s\n' "$unsupported_status" | grep -F 'platform_supported=false' >/dev/null
if FAKE_MACOS_VERSION=12.7 "$SCRIPT" download "$TMP/downloads/unsupported.pkg" >"$TMP/unsupported.out" 2>"$TMP/unsupported.err"; then
    echo "download unexpectedly accepted unsupported macOS" >&2
    exit 1
fi
grep -F 'requires macOS 13 or later' "$TMP/unsupported.err" >/dev/null

downloaded="$($SCRIPT download "$TMP/downloads/Breakdown.pkg")"
[ "$downloaded" = "$TMP/downloads/Breakdown.pkg" ]
grep -F 'signed package fixture' "$downloaded" >/dev/null
second_download="$($SCRIPT download "$TMP/downloads/Breakdown-2.pkg")"
[ "$second_download" = "$TMP/downloads/Breakdown-2.pkg" ]
[ "$(sort -u "$FAKE_CURL_LOG" | wc -l | tr -d ' ')" -eq 2 ]

if FAKE_BAD_SIGNATURE=1 "$SCRIPT" download "$TMP/downloads/bad.pkg" >"$TMP/bad.out" 2>"$TMP/bad.err"; then
    echo "download unexpectedly accepted the wrong signer" >&2
    exit 1
fi
grep -F 'signer did not match' "$TMP/bad.err" >/dev/null
[ ! -e "$TMP/downloads/bad.pkg" ]

$SCRIPT install "$downloaded" >/dev/null
grep -F "$downloaded" "$FAKE_LOG" >/dev/null

$SCRIPT open-app
grep -F "$BREAKDOWN_APP_PATH" "$FAKE_LOG" >/dev/null

$SCRIPT configure-codex
grep -F "codex mcp add breakdown -- $BREAKDOWN_APP_PATH/Contents/MacOS/BreakdownMCPBridge" "$FAKE_LOG" >/dev/null

if FAKE_BAD_APP_TEAM=1 "$SCRIPT" configure-codex >"$TMP/bad-app.out" 2>"$TMP/bad-app.err"; then
    echo "configure-codex unexpectedly accepted the wrong app team" >&2
    exit 1
fi
grep -F 'identity did not match' "$TMP/bad-app.err" >/dev/null

BREAKDOWN_APP_PATH="$TMP/Applications/Breakdown \"Beta\"\\Test/Breakdown.app"
export BREAKDOWN_APP_PATH
config="$($SCRIPT print-config)"
printf '%s\n' "$config" | grep -F '"mcpServers"' >/dev/null
printf '%s\n' "$config" | /usr/bin/python3 -m json.tool >/dev/null

BREAKDOWN_APP_PATH="$(printf '%s\n%s' "$TMP/Applications/Breakdown" "Beta/Breakdown.app")"
export BREAKDOWN_APP_PATH
if "$SCRIPT" print-config >"$TMP/newline.out" 2>"$TMP/newline.err"; then
    echo "print-config unexpectedly accepted a newline in the app path" >&2
    exit 1
fi
grep -F 'unsupported control characters' "$TMP/newline.err" >/dev/null

printf 'setup-breakdown tests passed\n'
