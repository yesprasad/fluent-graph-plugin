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
- **`fluent-graph-impact` skill.** Before Claude changes a table, field, ACL, business
  rule, or client script, it looks up what depends on it: the table's fields, attached
  scripts and rules, references, and every dependent artifact hop by hop
  (`fluent-graph context` and `fluent-graph blast`, or the MCP tools).
- **`fluent-graph-validate` skill.** When you ask whether an app is healthy, before a
  release, or when setting up CI, Claude checks the whole app for structural defects:
  fields that don't exist, scripts with an undefined run order, duplicate definitions,
  and references to records marked for deletion (`fluent-graph validate`). It can also map
  everything the app contains (`fluent-graph analyze`).
- **A reminder after Fluent edits.** When Claude edits a `*.now.ts` or `now.config.json`
  file, a hook reminds it to verify the change before it finishes.
- **The fluent-graph MCP server**, with four tools: `list_artifacts`, `get_artifact`,
  `blast_radius`, and `refresh`. Claude uses them to look up an artifact and its
  dependencies without running a command each time.

## What it runs and sends

Everything runs on your machine.

- The skills run `npx -y @yesprasad/fluent-graph@0.3.0` in your project, with `review`,
  `context`, `blast`, `validate`, or `analyze`. `npx` downloads that package from the public
  npm registry the first time. The commands read your project files (and, for `review`, git
  history), build the app locally, and print a report. They do not change your source files
  and do not contact a ServiceNow instance. When a skill runs `analyze`, it writes the graph
  file to your temporary folder, not into the project.
- The MCP server runs `npx -y @yesprasad/fluent-graph-mcp@0.1.0 --project-root .`,
  downloaded from the public npm registry the same way. It answers dependency questions
  from your local project. On startup it saves the app's graph as `fluent-graph.json` in the
  project root. Add that file to `.gitignore`.
- The hook (`hooks/fluent-change-reminder.sh`) reads the edit event Claude Code passes to it,
  checks the file name, and prints a reminder. It makes no network calls.
- The plugin sends no data to the author or to any other service. Fluent-Graph's optional
  AI summary is off unless you configure your own provider, and the plugin never turns it
  on. Reviewing a GitHub pull request with `--pr` contacts GitHub, and only when you ask for it.
- The plugin collects no personal data. It has no telemetry, no accounts, and no server, so
  nothing you do with it reaches the author.

Questions about this section or about privacy: open an issue at
https://github.com/yesprasad/fluent-graph-plugin/issues.

## Requirements

Node.js 20 or later and a ServiceNow Fluent project (a folder with `now.config.json`).

## License

MIT. See [LICENSE](LICENSE).

ServiceNow is a trademark of ServiceNow, Inc. Fluent-Graph is an independent project by
Eshwar Yaddanapudi, not affiliated with or endorsed by ServiceNow.
