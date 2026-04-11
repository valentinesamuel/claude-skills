# Claude Agent Skills Catalog (Tier + Domain)

This directory reorganizes agents into a predictable structure so you can choose by:

1. **Tier** (model class)
2. **Domain** (frontend, backend, observability, infrastructure, devops, security)

## Folder structure

```text
agent-packs/
  skills/
    tier-1-opus/
      frontend.txt
      backend.txt
      observability.txt
      infrastructure.txt
      devops.txt
      security.txt
    tier-2-sonnet/
      frontend.txt
      backend.txt
      observability.txt
      infrastructure.txt
      devops.txt
      security.txt
    tier-3-haiku/
      frontend.txt
      backend.txt
      observability.txt
      infrastructure.txt
      devops.txt
      security.txt
```

Each `*.txt` file contains newline-separated source agent files from this repository.

## Install into a project

List available tier/domain combinations:

```bash
./scripts/install-agent-pack.sh --list
```

Install one domain from one tier:

```bash
./scripts/install-agent-pack.sh tier-1-opus frontend /path/to/project
```

Install all domains from one tier:

```bash
./scripts/install-agent-pack.sh tier-2-sonnet all /path/to/project
```

Installed destination:

`/path/to/project/.claude/agents/`

Install metadata file:

`/path/to/project/.claude/agents/_installed-pack.txt`

## Notes

- Tier-3 currently has limited domain coverage because only a few tier-3 agents are available in the source set.
- Lines starting with `#` in manifest files are treated as comments and skipped.
