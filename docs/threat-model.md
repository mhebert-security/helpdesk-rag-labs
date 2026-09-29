# Threat Model

STRIDE maps each trust boundary to the attacker goals the labs exercise. The
boundary descriptions come from README.md. Attack paths are stubbed to their
lab until that lab is written.

| Boundary | Description | STRIDE | Attack path |
|---|---|---|---|
| A | Internet to App: unauthenticated users and bots | Spoofing, Information Disclosure, DoS | see lab-00 |
| B | App to Session: session fixation, IDOR | Information Disclosure, Elevation of Privilege | see lab-00 |
| C | App to Index: tenant/role filter bypass | Information Disclosure | see lab-05 |
| D | Unvetted docs to Index: indirect prompt injection | Tampering, Spoofing | see lab-02 |
| E | Model to Tools/Plugins: excessive agency | Elevation of Privilege | see lab-07 |
| F | Model output to Browser/Downstream: improper output handling | Tampering, Information Disclosure | see lab-06 |
