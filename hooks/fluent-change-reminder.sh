#!/bin/sh
# After Claude edits a ServiceNow Fluent file, add a reminder to verify the change before finishing.
# Reads the hook event from stdin. Prints nothing for any other file. Makes no network calls.
file=$(sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)
case "$file" in
  *.now.ts|*now.config.json) ;;
  *) exit 0 ;;
esac
file=$(printf '%s' "$file" | tr -d '"\\')
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"A ServiceNow Fluent file changed (%s). Before you finish, commit, or deploy, verify the change with the fluent-graph-verify skill: run npx -y @yesprasad/fluent-graph@0.3.0 review --details --no-banner from the project root and report its findings."}}\n' "$file"
