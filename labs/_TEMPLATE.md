# Lab NN — [Attack Class] vs [Control]

**OWASP LLM:** LLMxx — [name]
**MITRE ATLAS:** AML.T00xx — [name] — verified against ATLAS v[version]
**Trust boundary crossed:** [A / B / C / D / E / F]
**Difficulty:** easy | medium | hard
**Estimated time:** build [N]m · attack [N]m · detect [N]m

---

## 1. Threat Model

**Asset at risk:** [system prompt | other users' docs | tool credentials | availability]

**Attack narrative:** [2–3 sentences in the voice of the adversary. What does the
attacker know, want, and do?]

**Preconditions:** [auth state, corpus contents, which tools are enabled]

**Controls already in place from prior labs:** [list them, or "none — this is baseline"]

---

## 2. Build Phase

**Goal:** [what this lab adds to the control surface]

**IaC diff:** `infra/bicep/deploy.vN.bicep` vs `deploy.v(N-1).bicep`

**App diff:** `app/src/guards/[guard-name].py`

**Config knobs touched:**
- temperature / top_k
- AI Search filter expression
- Content Safety category thresholds
- APIM rate limits

**Smoke test (confirms the build is functional before attacking):**
```bash
# fill in: curl or pytest invocation that returns 200 and a coherent answer
```

---

## 3. Attack Phase

**Objective:** [exfiltrate canary | bypass filter | consume $X | flip a tool call]

**Payload files:** `attacks/NN-[name]/`

**Execution:**
```bash
# fill in: exact command — curl, python attacks/NN-*/attack.py, etc.
```

**Success criteria:** [what observable output or side-effect confirms the attack worked]

**False-positive baseline:** re-run the benign query set (`tests/redteam/benign.json`)
and confirm no legitimate request is blocked or degraded.

---

## 4. Expected Telemetry

| Signal | Source | Field(s) |
|---|---|---|
| Prompt text | App Insights `chat.request` | `prompt_hash`, `user_id`, `session_id` |
| Guard block | App log `guard.verdict` | `guard`, `verdict`, `category`, `confidence` |
| Tool invocation | App log `tool.invocation` | `tool_name`, `args_redacted`, `allowed` |
| Egress attempt | NSG flow logs / DNS | `dst_ip`, `dst_fqdn` |

**Detection rule:** `detections/kql/NN-[name].kql`

**Pass condition:** rule fires on every attack replay, silent on 24-hour benign replay.

---

## 5. Hardening Applied

**Control:** [exact change — one sentence]

**Why it holds:** [reasoning grounded in how the attack works, not hand-waving]

**Residual risk — bypasses that still work:** [be specific and honest here]

---

## 6. Evidence Checklist

- [ ] Attack succeeded on v(N-1) — screenshot or log excerpt saved to `evidence/lab-NN/`
- [ ] Control applied — diff committed
- [ ] Attack fails on vN — screenshot or log excerpt saved
- [ ] Detection rule fired — alert ID recorded
- [ ] Benign regression suite passes
- [ ] `findings.md` written in `evidence/lab-NN/`

---

## 7. Debrief

**What the model did well:** [...]

**What the guardrail missed or nearly missed:** [...]

**Cost of the control:** latency added (ms), token overhead, $/1k requests, UX impact

**Portfolio takeaway:** [one line — what does this lab prove you understand?]
