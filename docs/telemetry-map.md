# Telemetry Map

One row per attack class. Maps from the attack technique to the OWASP
category, ATLAS technique, log source, KQL stub, and expected alert.
Keep this file in sync as labs are completed.

| Lab | Attack class | OWASP | ATLAS | Log source | KQL file | Alert condition |
|---|---|---|---|---|---|---|
| 00 | Unauthenticated API access | all | — | Entra sign-in logs | `00-unauth.kql` | Anonymous call reaches chat endpoint |
| 01 | Direct prompt injection | LLM01 | AML.T0051 | App Insights `guard.verdict` | `01-direct-injection.kql` | `verdict=block` AND `category=injection` |
| 02 | Indirect injection via corpus | LLM01, LLM04 | AML.T0051, AML.T0043 | App Insights `retrieval.result` | `02-indirect-injection.kql` | Chunk flagged at ingest; provenance tag missing |
| 03 | Jailbreak | LLM01 | AML.T0054 | App Insights `guard.verdict` | `03-jailbreak.kql` | `verdict=block` AND `guard=prompt_shield` |
| 04 | System prompt extraction | LLM07 | AML.T0056 | App Insights `model.completion` | `04-prompt-leakage.kql` | Canary string in completion output |
| 05 | Cross-user data access | LLM02 | AML.T0057 | AI Search diagnostics | `05-acl-bypass.kql` | Query returns chunks outside caller's ACL filter |
| 06 | Output injection (XSS/SSRF) | LLM05 | — | App log `output.render` | `06-output-injection.kql` | `contains_html=true` OR unsanitized link rendered |
| 07 | Unauthorized tool invocation | LLM06 | AML.T0053 | App log `tool.invocation` | `07-tool-abuse.kql` | `allowed=false` OR tool called outside approved set |
| 08 | Embedding / index poisoning | LLM08 | AML.T0043 | AI Search diagnostics | `08-embedding.kql` | Chunk score anomaly; duplicate provenance |
| 09 | Markdown data exfil | LLM02, LLM01 | AML.T0024, AML.T0025 | NSG flow logs / DNS | `09-exfil.kql` | Egress to non-allowlisted IP from app subnet |
| 10 | Token flood / DoS | LLM10 | AML.T0034 | APIM `AzureMetrics` | `10-consumption.kql` | Token rate > threshold per user per minute |
| 11 | Supply chain | LLM03 | AML.T0010 | Container registry / SBOM | `11-supply-chain.kql` | Unsigned image or unpinned dependency in deploy |
| 12 | Hallucination / overreliance | LLM09 | — | App Insights `model.completion` | `12-groundedness.kql` | Groundedness score below threshold |
| 13 | Agentic escalation chain | LLM06, LLM01 | AML.T0051, T0053 | All of the above | `13-agentic.kql` | Injection → tool call → egress in same session |
| 14 | Full kill chain | all | all | All of the above | `14-capstone.kql` | Sentinel incident with all six boundaries crossed |

Verify ATLAS IDs against the current ATLAS matrix version before
finalizing any lab report. Record the matrix version in the lab file.
