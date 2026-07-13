# Breakdown connectivity for AI agents

Give AI agents local evidence for Internet, DNS, Wi-Fi, packet loss, latency, endpoint, browser, API, upload, download, MCP, and cloud-tool failures.

This repository contains the public Agent Skill and setup helpers for [Breakdown](https://breakdown.live/), a Mac menu-bar network health application. Breakdown separates LAN, Internet path, and app/service health and exposes bounded evidence through a local MCP server.

## Use the skill

The portable skill is at [`skills/breakdown-connectivity`](skills/breakdown-connectivity). Add that directory through the skill installation mechanism supported by your agent environment.

Once loaded, the skill can:

- Recognize tasks where connectivity evidence may be useful.
- Work with an already connected Breakdown MCP server.
- Download and open the signed Breakdown installer when the app is absent.
- Open Breakdown and configure its installed MCP bridge for Codex or Claude Code.
- Provide a configuration fragment for other stdio MCP clients.

Breakdown requires macOS 13 or later. The application must be running when an MCP client uses its installed bridge.

## Links

- [Download Breakdown](https://breakdown.live/download/mac)
- [Breakdown for AI agents](https://breakdown.live/for-agents/)
- [Privacy](https://breakdown.live/privacy/)
- [Terms](https://breakdown.live/terms/)
