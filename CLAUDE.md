# HELPDESK-RAG-PURPLE — Agent Context

## Folder Purpose

This is a purple-team lab program: build an Azure RAG chatbot that is
intentionally insecure, then attack and harden it one lab at a time. The
work produces a reusable KQL detection pack, a hardened reference
architecture in Bicep, and lab write-ups as portfolio artifacts.

---

## Authorship

Do not add yourself as a contributor, co-author, or collaborator anywhere in
this repository. This includes commit messages, git trailers, AUTHORS files,
README attribution, and any other form of credit. All commits are authored
solely by the repository owner. Claude is a tool, not a contributor.

---

## Memory and Architectural Source of Truth

The Obsidian vault (allowed root: /home/splayingcow/Obsidian) is the
persistent external memory bank and architectural source of truth.

Canonical project note: `03_Security/00_active/helpdesk-rag-purple/`

Always consult the relevant Obsidian note before planning or modifying
infrastructure or application code. Treat constraints, schemas, and design
decisions found there as hard requirements.

**Write protocol:** Every time a lab, code change, or test suite completes,
append a dated entry to the implementation log at:
`03_Security/00_active/helpdesk-rag-purple/01_implementation_log.md`

Every log entry documents: files created or modified, Azure resources
touched, test results, security scan findings, and any remaining open items
or residual risks.

---

## Stack

| Layer | Technology |
|---|---|
| App | Python 3.12, FastAPI, openai SDK |
| Orchestration | LangChain or plain Python (no framework lock-in in v0) |
| Infra | Azure Bicep (primary), Terraform equivalents optional |
| Retrieval | Azure AI Search (vector + keyword hybrid) |
| Model | Azure OpenAI gpt-4o (chat) + text-embedding-3-small |
| Guardrails | Azure Content Safety, Prompt Shield |
| Observability | App Insights, Log Analytics, Defender for Cloud AI |
| Secrets | Azure Key Vault + Managed Identity |

---

## External Documentation

Use the fetch MCP tool whenever dealing with unfamiliar API behavior,
Azure Bicep resource schema updates, or OpenAI SDK changes. When live
vulnerability lookups or CVE advisories are required for a lab's threat
model, search before drafting mitigations.

---

## Verification, Testing, and Security Analysis

Before declaring any lab complete or committing:

1. Run the Python unit tests:
   ```bash
   cd app && python -m pytest tests/unit/ -v
   ```
2. Validate Bicep templates:
   ```bash
   az bicep build --file infra/bicep/deploy.v0.bicep
   ```
3. Run a static security audit on the Python app:
   ```bash
   semgrep scan --config auto app/src/
   ```
4. Run Bandit for Python-specific issues:
   ```bash
   bandit -r app/src/ -ll
   ```
5. If any scan flags issues, resolve them before declaring the lab done.
6. Update the Obsidian implementation log once all checks pass.

---

## GitHub Protocol

Once a lab passes all checks and the vault is updated:

```bash
git status --short
git add <changed files — never .env, never real credentials>
git commit -m "feat: lab-NN <summary>"
git push origin HEAD
```

Never commit: `.env` files, Azure credentials, real API keys, or the
tracking spreadsheet. Canary tokens (`CANARY-4f9a…`) are synthetic and
safe to commit.

Never leave a finished lab uncommitted once verification passes.

---

## Lab Execution Rules

Each lab has three phases in sequence: Build, Attack, Detection. Complete
each phase fully before starting the next. Do not harden the control before
confirming the attack succeeds against the unpatched build. Do not declare
a detection rule passing until the benign replay runs clean.

Every attack phase must produce telemetry. If the attack does not show
up in App Insights or the OT sensor equivalent, the lab is incomplete.

Always document residual risk. A lab that claims "fully hardened" without
naming a bypass that still works is not credible.

---

## Safety Constraints

Work exclusively in the isolated lab Azure subscription. Synthetic corpus
only — no real employee data, no real credentials, no production APIs.
Exfil endpoints resolve to a sink you control, not the public internet.
No jailbreak payloads against third-party production models. No novel bypass
disclosures without responsible disclosure to the vendor first.

---

## Prose Standard

All documentation, lab write-ups, findings.md files, and commit messages
follow these rules.

Active voice by default. Passive only when the agent is genuinely unknown.
Concrete nouns and strong verbs — never "is performed" when "rejects" works.
No em dashes, en dashes, or hyphens used as clause separators. Restructure
the sentence instead. No filler openers. Begin with the substance. Short
paragraphs; three sentences is a paragraph.

Cut every word that restates what the sentence before it already said.

These rules apply to: lab write-ups, architecture docs, findings.md, and
any prose generated on request. They do not apply to inline code comments
whose audience is the linter, or to structured data formats.

---

## Execution Rules

Execute tool calls autonomously without asking for routine permissions. When
presenting completed work, state which files were written, which Azure
resources were touched, cite Semgrep and Bandit scan results, and report
the resulting GitHub commit hash and push status.

When an attack phase is required, explicitly confirm the attack succeeded
on v(N-1) before applying the hardening. Do not declare an attack blocked
without running the same payload against vN.
