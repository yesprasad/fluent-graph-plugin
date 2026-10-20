---
name: fluent-graph-impact
description: Look up what a ServiceNow Fluent (now-sdk) table touches before changing it. Use before editing, renaming, or deleting a table, field, ACL, business rule, client script, or flow in *.now.ts files, and whenever the user asks what uses a table, what depends on it, what breaks if it changes, or what its blast radius is. Gives the fields, attached scripts and rules, references, and every artifact that depends on the table, hop by hop, using the fluent-graph MCP tools (blast_radius, get_artifact, list_artifacts, refresh) or the CLI commands `npx @yesprasad/fluent-graph@0.3.0 context <table>` and `blast <table>`. Local and read-only; no instance or credentials needed.
---

# Look up impact before changing a Fluent table

Before you change something in a Fluent app, find out what depends on it.
Fluent-Graph maps the app as a graph of ServiceNow records and the
references between them. This skill answers "what does this touch?" *before*
an edit. After the edit, verify it with the `fluent-graph-verify` skill.

## When to use it

- Before editing, renaming, or deleting a table, a field, or anything attached to a table.
- When the user asks "what uses `x_bank_account`?", "what breaks if I change this?",
  or "what's the blast radius?" for something that is not yet changed.
- When you need to understand an unfamiliar Fluent app quickly: start with `context`.

For a change that is already made, use `fluent-graph-verify` (`review`) instead:
it compares before and after and catches DELETEs and risky rule changes.

## Targets are table names

`blast` and `context` take a **table name**, such as `x_acme_account` or `incident`,
not a file, a business rule name, or a sys_id. To check a business rule, ACL, or
client script, use the table it runs on. If you pass something else, the command
exits `1` and lists the valid custom and platform tables; pick one from that list.

## Option 1: the MCP tools (fastest, if the fluent-graph MCP server is connected)

| Tool | Use it to | Arguments |
| --- | --- | --- |
| `list_artifacts` | See what the app contains, optionally for one ServiceNow table (`sys_script`, `sys_security_acl`, …) | `table` (optional) |
| `get_artifact` | See one artifact: its table, action, source file, properties, and what it points to | `name` |
| `blast_radius` | See everything that depends on a table, grouped by hop | `artifact_name` (a table name), `depth` (default 5) |
| `refresh` | Reload the graph after you edit files | none |

The server loads the graph once at startup. **Call `refresh` after every edit**
before you query again, or the answers describe the old code.

`blast_radius` on a business rule, script, or ACL usually returns "No dependents
found … It is safe to change." That only means nothing *references* it. It does
not mean the change is safe. Check the table it runs on instead, and never repeat
"safe to change" to the user.

## Option 2: the CLI (always available)

Run from the project root (the folder with `now.config.json`).

**Context for one table.** It shows the fields, scripts and rules attached to the table,
its references, and a blast radius summary, sized to fit an agent's context:

```bash
npx -y @yesprasad/fluent-graph@0.3.0 context <table> --no-banner --format json
```

- `--depth 0|1|2`: the table only, direct neighbours (default), or two hops
- `--no-fields`, `--no-scripts`, `--no-blast`: leave sections out
- `--show-metrics`: token counts for each section

**Blast radius for one table.** `blast` reads a saved graph, so map the app first.
Write the graph to a temporary file, not into the project:

```bash
npx -y @yesprasad/fluent-graph@0.3.0 analyze --no-banner --quiet --output "${TMPDIR:-/tmp}/fluent-graph.json"
npx -y @yesprasad/fluent-graph@0.3.0 blast <table> --no-banner --graph "${TMPDIR:-/tmp}/fluent-graph.json"
```

- `--format json` (or `csv`): machine-readable output, including each dependency path
- `--direct-only`: hop 1 only · `--depth <n>`: limit the hops (default 10)
- `--show-paths`: the full chain for each transitive dependency
- `--include-deleted`: also include artifacts already marked for deletion

If `blast` says the graph file was not found, you skipped `analyze` or used a
different path. Re-run `analyze` after editing files, before you run `blast` again.

## How to read the output

- **Direct impact (hop 1)**: artifacts that reference the table directly, and
  *via* which field or relation (for example, `account (ref field)`).
- **Transitive impact (hop 2+)**: artifacts reached through those, such as ACLs,
  business rules, and client scripts on a table that references yours.
- **Risk level** (LOW / MEDIUM / HIGH): based on how many artifacts are reached.
  It measures reach, not whether the change is correct.
- **State**: `ACTIVE` artifacts are deployed. Artifacts marked for deletion are
  left out unless you pass `--include-deleted`.
- ACLs and some other records appear by sys_id. Find the record in the named
  file and describe it by its purpose (for example, "the write ACL on fraud alerts").

## What to report

Start with **"Checked with fluent-graph:"**. Then:

1. What depends on the target directly, and through which field or relation.
2. What it reaches further out, grouped by kind (ACLs, business rules, client scripts, flows).
3. Which of those your planned change could break, and how you will avoid it.

Then make the change and verify it with `fluent-graph-verify`.

## Rules

- No dependents does not mean the change is safe. Report what was checked.
- These commands read the project and never contact an instance. The MCP server
  saves `fluent-graph.json` in the project root. If git shows it as a new file,
  tell the user and suggest adding it to `.gitignore`. Don't commit it.
