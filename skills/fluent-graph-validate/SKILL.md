---
name: fluent-graph-validate
description: Check a whole ServiceNow Fluent (now-sdk) app for structural defects, or map everything it contains. Use when the user asks whether a Fluent app is healthy or has broken references, before a release or first deployment, when setting up a CI check for a Fluent repository, when taking over an unfamiliar app, or when asked for an inventory of its tables, scripts, ACLs, and dependencies. Runs `npx @yesprasad/fluent-graph@0.3.0 validate` (invalid field references, conflicting script order, duplicate definitions, active references to records marked for deletion; exits non-zero on errors) and `analyze` (the full dependency map). Local and read-only; no instance or credentials needed.
---

# Validate and map a whole Fluent app

`fluent-graph-verify` checks one change. This skill checks the **whole app as it
is now**. `validate` finds structural defects. `analyze` maps every artifact and
relationship.

## When to use it

- "Is this app healthy?", "are there broken references?", "anything wrong before we release?"
- Before a release or a first deployment to a new instance.
- Setting up CI for a Fluent repository (see below).
- Taking over an unfamiliar app: `analyze` gives the inventory, `validate` the defects.

## validate

From the project root (the folder with `now.config.json`):

```bash
npx -y @yesprasad/fluent-graph@0.3.0 validate --no-banner
```

- `--format json`: `{ valid, issueCount, errors[], warnings[], info[] }`. Each issue
  has `severity`, `code`, `message`, `artifact`, `table`, `file`, and sometimes `suggestion`.
- `--severity error|warning|info`: the lowest severity to show (default `info`).

Exit code: `0` no errors · `1` at least one error, or the command failed. Warnings
alone do not fail it.

| Code | Severity | Meaning |
| --- | --- | --- |
| `FG-001` | error | A script or policy references a field that does not exist on its table |
| `FG-005` | error | An active artifact still references a record marked for deletion; it breaks after deployment |
| `FG-002` | warning | Two scripts or rules with the same order fire on the same event and table, so the run order is undefined |
| `FG-003` | warning | A reference to a table that is neither in the project nor a known platform table |
| `FG-004` | warning | Two artifacts with the same name on the same table; the last one defined wins |

### Confirm each finding before you report it

Open the named file and confirm each finding before you pass it on. Version 0.3.0
reports some findings that are usually not real defects:

- `FG-002` on table `sys_scope` with event `unknown`. These group unrelated
  artifacts together. Treat `FG-002` as real only when it names a concrete table
  and event, for example two `onLoad` client scripts on `incident` at order 100.
- `FG-004` on `sys_dictionary`, `sys_choice`, or `sys_documentation`. A table's
  field, choice, and label records share the table's name.
- `FG-005` whose `table` is `sys_choice`, pointing at `src/fluent/generated/keys.ts`.
  These come from choice records marked for deletion in an earlier build, not
  from a table being deleted. Mention them in one line as pre-existing.

Report everything else plainly. An `FG-001` error is a real broken reference:
the script fails at runtime. Name the script, the missing field, and the table.

## analyze

```bash
npx -y @yesprasad/fluent-graph@0.3.0 analyze --no-banner
```

This prints the app's artifacts by type, the reference fields between tables, and
totals for artifacts, platform dependencies, and relationships. By default it also
writes `fluent-graph.json` in the project. To keep the project clean, write the
graph to a temporary file instead:

```bash
npx -y @yesprasad/fluent-graph@0.3.0 analyze --no-banner --output "${TMPDIR:-/tmp}/fluent-graph.json"
```

- `--format json`: JSON instead of tables · `--quiet`: no console output (file only)
- The graph file has `metadata`, `nodes`, and `edges`. `blast --graph <file>`
  reads it (see `fluent-graph-impact`).

## In CI

`validate` exits non-zero on errors, so it works as a gate:

```yaml
- run: npx -y @yesprasad/fluent-graph@0.3.0 validate --no-banner --severity error
```

Pin the version. Add this only when the user asks for it. Suggest
`fluent-graph review --base origin/main` as the pull request check for changes.

## What to report

Start with **"Checked with fluent-graph validate:"**. Then:

1. The error count and each real error in plain language: what breaks and where.
2. Real warnings, grouped by kind.
3. Pre-existing or likely false findings, counted in one line.
4. For `analyze`: what the app contains (tables, business rules, client scripts,
   ACLs, flows), and the tables most others depend on.

## Rules

- A clean `validate` means no structural defects were found. It does not cover
  logic, data, roles on the instance, or test results. Say so.
- Don't edit files to clear findings without the user's agreement.
- Never contacts an instance. Only `analyze` writes a file, and only where `--output` points.
