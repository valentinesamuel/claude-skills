# Claude Skills

A curated library of Claude Code agents, reference skills, and an orchestration system for production-grade software engineering. Install into any project with a single `curl` command — no cloning required.

---

## What's in here

| Directory | What it is |
|---|---|
| `distinguished-engineer/` | Top-level conductor agent — the entry point for all work |
| `oracle/` | Planning and diagnostic agent — produces execution artifacts |
| `operator/` | Execution engine — runs the plan phase by phase |
| `agents/` | 28 domain-specialized agents across 4 categories |
| `skills/` | 11 reference pattern libraries (API design, auth, DB, etc.) |
| `vercel-react-best-practices/` | 57 Vercel-authored React/Next.js optimization rules |
| `agent-packs/` | Manifest files for bulk agent installation |
| `scripts/` | Setup and install scripts |

---

## Prerequisites

- [Claude Code](https://claude.ai/code) installed and authenticated
- `curl` (pre-installed on macOS and most Linux distros)
- A Claude account with access to Opus 4 (the agents are tuned for Opus-class models)

---

## Quickstart

### 1. Install into your project

Run the one-liner, passing the path to your project:

```bash
curl -fsSL https://raw.githubusercontent.com/valentinesamuel/claude-skills/main/scripts/install.sh | bash -s -- /path/to/your-project
```

Or omit the path to be prompted interactively:

```bash
curl -fsSL https://raw.githubusercontent.com/valentinesamuel/claude-skills/main/scripts/install.sh | bash
```

The installer will:

1. Always install `distinguished-engineer`, `oracle`, and `operator` into your project's `.claude/agents/`
2. Show an interactive menu — toggle which domain packs you want
3. Fetch the selected domain agents directly from GitHub into `.claude/agents/`
4. Fetch the relevant reference skills into `.claude/skills/`
5. Write an installation manifest at `.claude/agents/_setup-manifest.txt`

Example session:

```
Distinguished Engineer Setup  (remote install)
  Target: /path/to/your-project

Select domain packs  (toggle number, Enter to confirm)

  [ ] 1. Backend          (api-designer, backend-developer, microservices-architect ...)
  [ ] 2. Frontend         (fullstack-engineer, frontend-developer, nextjs-developer ...)
  [ ] 3. Infrastructure   (cloud-architect, database-admin, platform-engineer ...)
  [ ] 4. DevOps           (devops-engineer, deployment-engineer, sre-engineer)
  [ ] 5. Observability    (performance-engineer, error-detective)
  [ ] 6. Security         (security-engineer, security-auditor, penetration-tester ...)
  [ ] 7. Specialized      (architect-reviewer, debugger, docker-expert, typescript-pro)

  Enter numbers to toggle (e.g. 1 3), or press Enter to confirm:
  > 1 3 6
```

### 2. Start working

Open your project in Claude Code and call the distinguished engineer:

```
/distinguished-engineer <describe your problem, feature, or bug>
```

---

## Local / Development Install

If you are contributing to this repo or prefer a local workflow, clone and run the local setup script instead:

```bash
git clone https://github.com/valentinesamuel/claude-skills.git
cd claude-skills
./scripts/setup.sh /path/to/your-project
```

`setup.sh` and `install.sh` are functionally identical — the only difference is that `setup.sh` copies files from your local clone while `install.sh` fetches them from GitHub.

---

## How the orchestration system works

There are three agents that work in sequence. You only load two at a time, keeping token usage low.

```
You
 │
 └─▶  /distinguished-engineer  (loaded at start)
        │
        ├── Step 1: Interrogates you — asks every hard question before planning
        │
        ├── Step 2: Spawns /oracle as a subagent
        │              │
        │              ├── Interrogates further if needed
        │              ├── Writes .claude/artifacts/plan.md
        │              ├── Writes .claude/artifacts/state.md
        │              ├── Writes .claude/artifacts/invariants.md
        │              ├── Writes .claude/artifacts/dependency-graph.json
        │              ├── Writes .claude/artifacts/working-hypotheses.md
        │              └── Writes .claude/artifacts/agent-map.md  ← which agents to use per phase
        │
        ├── Step 3: Stress-tests all artifacts
        │           Challenges failure modes, weak decisions, missing invariants
        │           Routes back to Oracle if anything is weak
        │
        ├── Step 4: Validates all agents in agent-map.md are installed
        │
        └── Step 5: Issues final verdict
                     "Operator is clear to execute."

 └─▶  /operator execute phases 1,2,3 from plan.md  (you call this when ready)
        │
        ├── Reads agent-map.md — knows which agent handles each phase
        ├── Invokes assigned agents as subagents, passing rehydration context
        ├── Runs strict verification gate after each phase (zero TS errors, zero lint)
        ├── Updates .claude/artifacts/checkpoint.md with "Context for Next Phase"
        │     so the next agent doesn't re-investigate what was already resolved
        └── Escalates back to Distinguished Engineer on any failure
```

### Artifacts produced

All artifacts land in `.claude/artifacts/` inside your project:

| File | Owner | Purpose |
|---|---|---|
| `plan.md` | Oracle | Phased execution roadmap with full rehydration context per phase |
| `state.md` | Oracle / Operator | Current phase, dependencies, risks, open questions |
| `dependency-graph.json` | Oracle | Machine-readable phase dependency DAG |
| `invariants.md` | Oracle | Rules that must never be broken during execution |
| `working-hypotheses.md` | Oracle | Uncertain beliefs and suspected bugs being tracked |
| `agent-map.md` | Oracle | Which agents and skills are assigned to each phase |
| `diff.md` | Operator | Files added / modified / removed per phase |
| `checkpoint.md` | Operator | Verification results + context handoff for next phase |

---

## Agent directory

### Orchestration (always installed)

| Agent | Role |
|---|---|
| `distinguished-engineer` | Conductor — interrogates, coordinates, stress-tests, approves |
| `oracle` | Planner — never writes code, only designs and produces artifacts |
| `operator` | Executor — deterministic, never deviates from the plan |

### Core development

| Agent | Expertise |
|---|---|
| `api-designer` | REST / GraphQL API design, OpenAPI specs, versioning, pagination |
| `backend-developer` | Services, databases, business logic, data pipelines |
| `event-driven-architect` | Event streaming, async patterns, choreography vs orchestration |
| `fullstack-engineer` | End-to-end application development |
| `microservices-architect` | Service boundaries, decomposition, inter-service communication |
| `websocket-engineer` | Real-time bidirectional communication, heartbeats, reconnection |

### Infrastructure

| Agent | Expertise |
|---|---|
| `cloud-architect` | Cloud platforms, cost optimization, disaster recovery |
| `database-admin` | Schema design, indexing, replication, backup strategies |
| `deployment-engineer` | Release strategies, canary deploys, rollback automation |
| `devops-engineer` | CI/CD pipelines, Docker, Kubernetes, GitOps |
| `platform-engineer` | Internal developer platforms, service mesh, SLO/SLI |
| `security-engineer` | Infrastructure security, TLS, network policies, secrets management |
| `sre-engineer` | Reliability, incident response, postmortems, error budgets |

### Quality assurance

| Agent | Expertise |
|---|---|
| `chaos-engineer` | Failure injection, resilience testing, blast radius analysis |
| `code-reviewer` | Code quality, design patterns, security, performance review |
| `error-detective` | Bug root-cause analysis, debugging, log analysis |
| `performance-engineer` | Load testing, profiling, bottleneck identification |
| `security-auditor` | OWASP Top 10, dependency scanning, secrets detection |
| `test-architect` | Test strategy, coverage, automation frameworks |

### Specialized

| Agent | Expertise |
|---|---|
| `architect-reviewer` | Architecture review, design patterns, scalability assessment |
| `compliance-auditor` | SOC2, ISO27001, HIPAA, regulatory compliance |
| `debugger` | Interactive debugging, breakpoints, trace analysis |
| `docker-expert` | Docker optimization, layer caching, multi-stage builds |
| `frontend-developer` | Framework-agnostic frontend, accessibility, performance |
| `nextjs-developer` | Next.js patterns, SSR, App Router, API routes |
| `penetration-tester` | Offensive security, exploit validation, risk demonstration |
| `react-specialist` | React patterns, hooks, state management, rendering optimization |
| `typescript-pro` | TypeScript type system, advanced patterns, strict mode |

---

## Reference skills

Reference skills are pattern libraries, not executable agents. Oracle lists them in `agent-map.md` and agents read them during execution. They live in `.claude/skills/` after installation.

| Skill | Covers |
|---|---|
| `api-design-patterns` | REST naming, HTTP methods, status codes, pagination, versioning |
| `authentication-patterns` | JWT, OAuth2 PKCE, RBAC, session management, token refresh |
| `database-optimization` | Indexing, query patterns, schema design |
| `golang-idioms` | Go-specific patterns, error handling, concurrency |
| `microservices-design` | Service boundaries, communication, failure isolation |
| `monitoring-observability` | OpenTelemetry, Prometheus, Grafana, structured logging, alerting |
| `performance-optimization` | Algorithm efficiency, caching, profiling |
| `postgres-optimization` | PostgreSQL tuning, indexing, replication, vacuuming |
| `redis-patterns` | Redis data structures, caching, pub/sub, sessions |
| `security-hardening` | OWASP Top 10, input validation, secrets management |
| `websocket-realtime` | WebSocket patterns, heartbeats, reconnection, backpressure |
| `vercel-react-best-practices` | 57 Vercel-authored rules for React/Next.js performance |

---

## Advanced: granular agent pack installation

If you want to install specific domain packs without the interactive setup script, use the lower-level installer:

```bash
# List all available tier/domain combinations
./scripts/install-agent-pack.sh --list

# Install one domain from tier-1 (Opus-class agents)
./scripts/install-agent-pack.sh tier-1-opus backend /path/to/project

# Install all domains from tier-2 (Sonnet-class agents)
./scripts/install-agent-pack.sh tier-2-sonnet all /path/to/project
```

### Manifest presets

For common project archetypes, pre-built manifests are available in `agent-packs/manifests/`:

| Manifest | Best for |
|---|---|
| `startup-mvp-fast.txt` | Small teams, fast iteration, full-stack focus |
| `production-web-balanced.txt` | Balanced web app teams with backend, frontend, infra, and security |
| `enterprise-critical-opus.txt` | Large-scale systems requiring full compliance, security, and reliability coverage |

Install a manifest:

```bash
while IFS= read -r line; do
  [[ -z "$line" || "$line" == \#* ]] && continue
  cp "claude-skills/${line}" /path/to/project/.claude/agents/
done < claude-skills/agent-packs/manifests/production-web-balanced.txt
```

---

## Adding a new agent

1. Create a markdown file in the appropriate `agents/` subdirectory:

```markdown
---
name: your-agent-name
description: One sentence — what this agent does and when to use it.
tools: Read, Write, Edit, Bash, Glob, Grep
model: opus
---

# Agent Name

You are a [role] specializing in [domain]...
```

2. Add the file path to the relevant `agent-packs/skills/tier-1-opus/<domain>.txt` if it should be part of a domain pack.

3. If it belongs in the orchestration workflow, update `oracle/SKILL.md` to include it in the agent pool description so Oracle knows it exists when generating `agent-map.md`.

---

## How the engineering mindset is enforced

Every agent in the orchestration layer (distinguished engineer and oracle) operates under the same principal engineer rules:

- Never assume — if unclear, stop and interrogate
- Break every requirement into edge cases and gaps
- Think in failure modes first — what breaks under load, what if a dependency is down
- For every option: explicit pros/cons and one recommended choice with justification
- No silent progress on unclear auth, data ownership, or integration behavior
- Be opinionated — take a stance and defend it with reasoning
- Bias toward reliability, observability, and simplicity over cleverness

These rules are embedded directly in both SKILL.md files — no external files are loaded at runtime, keeping token usage minimal.

---

## Project layout reference

```
claude-skills/
├── distinguished-engineer/
│   └── SKILL.md                  # Conductor agent
├── oracle/
│   └── SKILL.md                  # Planning agent
├── operator/
│   └── SKILL.md                  # Execution agent
├── agents/
│   ├── core-development/         # 6 backend/fullstack agents
│   ├── infrastructure/           # 7 infra/cloud/ops agents
│   ├── quality-assurance/        # 6 QA/security/perf agents
│   └── specialized/              # 9 specialist agents
├── skills/
│   └── <skill-name>/
│       └── SKILL.md              # Reference pattern library
├── vercel-react-best-practices/
│   ├── SKILL.md                  # Summary + rule index
│   ├── AGENTS.md                 # LLM-optimized guidance
│   └── rules/                    # 57 individual rule files
├── agent-packs/
│   ├── manifests/                # Named project presets
│   └── skills/
│       ├── tier-1-opus/          # Domain packs for Opus-class models
│       ├── tier-2-sonnet/        # Domain packs for Sonnet-class models
│       └── tier-3-haiku/         # Domain packs for Haiku-class models
├── scripts/
│   ├── install.sh                # Remote one-liner installer (fetches from GitHub)
│   ├── setup.sh                  # Local installer (reads from cloned repo)
│   └── install-agent-pack.sh     # Granular pack installer
└── instructions.md               # Principal engineer mindset reference
```
