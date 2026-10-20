# Fluent-Graph for Claude

Verify ServiceNow Fluent (now-sdk) changes before you commit or deploy.

A diff shows which lines changed. It doesn't show which ServiceNow records change, what
else depends on them, or whether your deployment deletes records. With this plugin, Claude
checks that for you whenever it works on a Fluent app.

## Install

In Claude Code:

```
/plugin install fluent-graph --marketplace yesprasad/fluent-graph-plugin
```

Or add **Fluent-Graph** from the plugin directory on claude.ai.

## What it adds

- **`fluent-graph-verify` skill.** Claude uses it after editing `*.now.ts` or
  `now.config.json`, before a commit, pull request, or `now-sdk deploy`, and when you ask
  whether a Fluent change is safe or what its blast radius is. Claude runs
  `fluent-graph review` and reports, in plain language:
  - every changed ServiceNow record across the app, not just the edited file
  - everything each change can reach
  - DELETE instructions in the deployment, and which ones the change introduced
  - SDK and configuration changes
  - rule findings for risky changes: ACL role grants and condition changes, business rule
    trigger changes, broken references, and new deletes
  - what the check could not assess
- **A reminder after Fluent edits.** When Claude edits a `*.now.ts` or `now.config.json`
  file, a hook reminds it to verify the change before it finishes.
- **The fluent-graph MCP server**, so Claude can look up a record's dependencies and blast
  radius before it changes it.

## What it runs and sends

Everything runs on your machine.

- The skill runs `npx -y @yesprasad/fluent-graph@0.3.0 review --details --no-banner` in
  your project. `npx` downloads that package from the public npm registry the first time.
  The review reads your project files and git history, builds the app locally, and prints a
  report. It does not modify your project and does not contact a ServiceNow instance.
- The MCP server runs `npx -y @yesprasad/fluent-graph-mcp@0.1.0 --project-root .`,
  downloaded from the public npm registry the same way. It answers dependency questions
  from your local project.
- The hook (`hooks/fluent-change-reminder.sh`) reads the edit event Claude Code passes to it,
  checks the file name, and prints a reminder. It makes no network calls.
- The plugin sends no data to the author or to any other service. Fluent-Graph's optional
  AI summary is off unless you configure your own provider, and the plugin never turns it
  on. Reviewing a GitHub pull request with `--pr` contacts GitHub, and only when you ask for it.

## Requirements

Node.js 20 or later and a ServiceNow Fluent project (a folder with `now.config.json`).

## License

MIT. See [LICENSE](LICENSE).

ServiceNow is a trademark of ServiceNow, Inc. Fluent-Graph is an independent project by
Eshwar Yaddanapudi, not affiliated with or endorsed by ServiceNow.
