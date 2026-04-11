# Claude Agent Packs by Project Type

This folder reorganizes the existing agent library into **ready-to-install packs** so you can quickly pick a model mix based on the project you are building.

## What this gives you
- A simple way to choose agents by **project type** and **model budget/quality tradeoff**.
- A repeatable installer script that copies the selected agents into your project.
- Manifests you can edit to build your own packs.

## Pack catalog

### 1) `startup-mvp-fast`
Best for: early MVPs, prototyping, and rapid iteration.

Model strategy:
- Mostly **Sonnet** agents for speed/cost balance.
- Includes one **Haiku** deployment helper.

### 2) `production-web-balanced`
Best for: shipping full-stack products with good quality + throughput.

Model strategy:
- Mix of **Opus** (architecture/review/security) and **Sonnet** (implementation velocity).
- Includes one **Haiku** accessibility tester.

### 3) `enterprise-critical-opus`
Best for: regulated, security-heavy, or high-risk systems.

Model strategy:
- Primarily **Opus** agents for depth and reliability.
- Minimal supporting specialists from other tiers.

## Install a pack into a project

From this repo:

```bash
bash scripts/install-agent-pack.sh <pack-name> /path/to/your/project
```

Example:

```bash
bash scripts/install-agent-pack.sh production-web-balanced ~/code/my-app
```

This installs agent markdown files into:

`/path/to/your/project/.claude/agents/`

and writes an inventory file:

`/path/to/your/project/.claude/agents/_installed-pack.txt`

## See available packs

```bash
bash scripts/install-agent-pack.sh --list
```

## Customize

Edit files in `agent-packs/manifests/*.txt`.
Each line is a source path to an agent file in this repository.
