# Secrets & Key Management for a Solo, Unattended Crypto Trading System

Researched: 2026-08-01, by Sonnet 5 subagent, live doc fetches (Binance support docs, Coinbase CDP docs, HashiCorp Vault docs, getsops.io docs). WebSearch unavailable this session; some Kraken/GNOME fetches 404'd/blocked — flagged inline.
Part of a 6-agent parallel sweep on ML infra + operational discipline for a solo autonomous crypto trading system.

---

## 1. Where to actually store the secrets

### OS keyring / Secret Service (gnome-keyring, KWallet)
UNVERIFIED via live fetch this session (Wikipedia/Arch Wiki fetches blocked/empty) — otherwise well-established architecture knowledge, high confidence. The Secret Service API is built around a D-Bus session bus normally spun up by a graphical login (PAM unlocks the keyring using the login password). A headless cloud VM has no login session, no D-Bus session bus by default. You *can* fake one (`dbus-run-session`, manually starting `gnome-keyring-daemon --unlock`), but the unlock secret then has to live somewhere on disk/boot-script for the unattended process — collapsing the security model to "a file the process can read" with a heavier, more fragile dependency chain than encrypting the file directly.

**Verdict: don't bother.** Desktop-session tooling wearing a server costume. Skip entirely for a headless VM.

### Plain environment variables loaded from an encrypted file
This is really "sops+age" or "a hand-rolled worse version of it." Env vars are a delivery mechanism, not storage — the question is what encrypts the source file. Don't hand-roll `openssl enc` + shell-script wrapper; you'll reinvent sops badly (no per-key granularity, easy to leak passphrase into shell history, no clean git-diffability).

### HashiCorp Vault (self-hosted)
VERIFIED (developer.hashicorp.com/vault/docs/concepts/seal): *"unsealing it using Shamir seals is a manual process"* and this *"make[s] automating a Vault installation difficult."* Auto-unseal (via cloud KMS) removes the manual-unseal problem but creates a hard dependency: *"If a seal mechanism such as the Cloud KMS key becomes unavailable or is deleted before you migrate the seal, you cannot recover access to the Vault cluster until the mechanism is available again."* Running Vault means: a server process to patch/monitor, TLS certs, an audit/storage backend (Raft/Consul) to keep healthy, policy/token lifecycle management — and Vault itself becomes a second thing that can go down and take the bot's ability to authenticate with it down too.

**Verdict: overkill for one person.** Vault's value is dynamic secrets, fine-grained per-team policy, audit trails across many consumers, lease/revocation at scale — none pays for itself with one operator, one bot, a handful of exchange keys. Self-hosting Vault *adds* a component that itself needs securing/keeping-alive, cutting against the actual goal (fewer things that can silently fail unattended). If already running Vault for other reasons, fine to reuse; standing it up *for this* is not worth the surface.

### Cloud provider secrets managers (AWS Secrets Manager / GCP Secret Manager)
Solve Vault's auto-unseal problem without running the Vault server — the cloud provider IS the auto-unseal KMS and storage backend. Store the API key as a secret, grant the VM's IAM role/service account `secretsmanager:GetSecretValue` (AWS) or `secretmanager.versions.access` (GCP), the bot fetches over an authenticated call using the VM's instance identity at startup — no long-lived credential needs to sit on disk to *get* the trading key. AWS Secrets Manager supports automatic rotation via Lambda. Cost trivial at this scale (AWS: $0.40/secret/month + $0.05/10k calls; GCP similar). Legitimate, low-effort, high-quality option **if the VM is already on that cloud** — KMS-grade encryption at rest, access logging, rotation tooling, zero operated infrastructure.

### sops + age (Mozilla SOPS)
VERIFIED (getsops.io usage docs). Concrete workflow:

1. Generate an age keypair on the VM (or offline, then copy the private key over):
   ```
   age-keygen -o /root/.config/sops/age/keys.txt
   # Public key: age1s3cq...
   ```
2. `.sops.yaml` specifying which files encrypt to which recipients:
   ```yaml
   creation_rules:
     - path_regex: secrets/.*\.env$
       age: age1s3cqcks5genc6ru8chl0hkkd04zmxvczsvdxq99ekffe4gmvjpzsedk23c
   ```
3. Encrypt and commit ciphertext:
   ```
   sops encrypt secrets/prod.env > secrets/prod.enc.env
   git add secrets/prod.enc.env   # ciphertext only — safe to commit, even to a public repo
   ```
4. At runtime, decrypt straight into the process environment, no plaintext file ever touches disk:
   ```
   export SOPS_AGE_KEY_FILE=/root/.config/sops/age/keys.txt
   sops exec-env secrets/prod.enc.env 'python trading_bot.py'
   ```
   (`sops -d file.enc.env > file.env` also works but reintroduces a plaintext file to handle carefully — prefer `exec-env`.)

The one thing still needing protection is the age private key file itself — the actual root secret. Options: (a) baseline — `chmod 600`, root-owned; (b) better — use sops's **KMS-backed recipient** instead of a bare age key, so decryption authority is enforced by cloud IAM (tied to VM identity) rather than a static key file sitting on the box at all.

**Direct recommendation: sops + age, with the age key optionally swapped for cloud KMS as the sops backend, is the right answer at solo scale.** Encrypted-at-rest, diffable/git-trackable ciphertext (version history, review "what changed" on a key rotation), zero servers, decrypt-into-memory runtime pattern. If the VM is AWS/GCP, prefer sops with the cloud KMS recipient over a bare age key file — removes "a key file on disk is the master secret" as a single point of failure, free IAM-level audit logging of every decrypt. Don't self-host Vault. Cloud Secrets Manager used directly (no sops) is also fine and simpler if you don't care about git-tracking ciphertext — sops's edge is specifically that encrypted secrets live in the repo next to the code that uses them, versioned together.

---

## 2. Exchange-side key scoping (the highest-leverage mitigation)

### IP allowlisting
- **Binance: VERIFIED** (binance.com/en/support/faq/how-to-create-api-360002502072). Not just supported — IP restriction is **mandatory** for anything beyond read-only: *"Unrestricted-IP-Access HMAC API Key(s) won't have any permission other than reading. If you'd like to enable other permissions, please add IP access (IPv4 format) restrictions."* A Binance key with trading enabled *must* be IP-locked — Binance forces the good practice.
- **Coinbase: VERIFIED** (docs.cdp.coinbase.com). *"For enhanced API Key security, we recommend that you allowlist IP addresses that are permitted to make requests with a particular API Key,"* configurable at key creation/edit time in the CDP portal. (Recommended, not forced, unlike Binance.)
- **Kraken: UNVERIFIED** — live fetches to Kraken's docs/support 404'd, WebSearch quota exhausted so no cross-check possible. From training knowledge: Kraken's API key settings historically did **not** offer per-key IP allowlisting the way Binance/Coinbase do — commonly cited gap. **Verify directly against your actual Kraken account's API key creation screen before relying on this.** If genuinely absent, that's a real reason to prefer Binance/Coinbase-style exchanges for the automated trading key, or compensate with host-level egress control since the exchange won't enforce IP-side for you.

**Implication**: since the bot runs from one VM with a knowable egress IP, IP-lock the trading key everywhere supported. Defeats the most common leak scenario (key exfiltrated via dependency-confusion, scraped GitHub secret, compromised laptop with a testing `.env`) because a stolen key is useless from any IP but yours. Doesn't protect against compromise of the VM itself (attacker calls from your allowed IP) — that's §4.

### Disabling withdrawal permission on the trading key
**VERIFIED for Binance**: withdrawal is a separate, explicit permission, off by default, requiring IP restriction to even enable. **VERIFIED-implied for Coinbase**: docs explicitly warn *"if someone obtains an api_secret with transfer permission, they will be able to send all the digital currency out of your account,"* confirming transfer/withdrawal is a distinct, separately-grantable scope. **UNVERIFIED for Kraken** — historically a checkbox permission list (Query Funds, Query Orders, Trade, Withdraw Funds, etc.) with Withdraw Funds off by default — verify directly.

This is the single highest-leverage control, more than IP allowlisting: **never grant withdrawal permission to the key that lives on the trading VM, full stop.** The bot needs to place/cancel orders and read balances, not move funds off-exchange.

**If a trading-only, no-withdrawal key leaks**: attacker can place trades on the account — dump the position into an illiquid pair, front-run against a counterparty wallet they control, spam-trade for fees — but cannot extract funds from the exchange. Worst case bounded to "value destroyed via bad trades," not "capital gone" — recoverable-in-kind (still hold *something*), not total silent irreversible loss.

**If withdrawal IS accidentally left enabled and the key leaks**: funds move to an attacker-controlled address, typically routed through a mixer/bridge within minutes. No on-chain clawback. Only recourse is fast exchange-support contact to freeze the destination if same-exchange (rare) — assume this fails, capital is gone. This is why every major exchange treats withdrawal as a separate, harder-to-enable permission — it's the actual blast-radius boundary that determines whether a leak is a bad day or the end of the fund.

### Separate keys by function
Standard, low-cost, do it: a read-only key for market-data/balance polling (if a monitoring/dashboard component doesn't need to trade, it shouldn't hold a trading-capable key), a separate trade-execution key scoped to trading only, IP-locked, no withdrawal. Limits exposure if a *component* (dashboard, logging pipeline, notification bot) is what gets compromised rather than the core trading process.

---

## 3. Key rotation

**Realistic cadence**: rotate on a fixed calendar schedule of roughly **60-90 days**, not more aggressively. Exchange API keys aren't short-lived cloud IAM credentials — rotating touches a live authenticated connection the bot depends on every trading cycle, so rotation itself is a risk window. Rotating more often mostly adds operational risk (botched rotation halting trading) without matched reduction in exposure, given the key is already IP-locked and withdrawal-disabled. Rotate immediately, out-of-cycle, on any compromise signal (unexpected trades, VM intrusion indicators, a secret-scanner hit, a compromised upstream dependency).

**Safe rotation procedure (never a zero-valid-key window):**
1. Create the **new** key on the exchange (trading-only, no withdrawal, IP-locked to the same VM IP) — old key stays active throughout.
2. Store the new key encrypted (sops re-encrypt, or update Secrets Manager with a new version) — don't overwrite the old key's storage yet.
3. Deploy the new key and verify it works from the actual running process before cutover — a dry-run/read-only call (fetch balance, fetch open orders) from the production process, since IP-locking means "works from your laptop" doesn't prove "works from the VM."
4. Only once confirmed live and functioning from production, restart/reload the bot to use it as primary. Prefer hot-swap over full restart if the process supports it — a restart window is its own risk for a market-making/leveraged strategy.
5. Only **after** confirming the bot trades successfully on the new key (at least one full order-placement cycle), revoke the old key.
6. Keep a rollback path documented (old key details, not deleted early) until step 5 in case the new key is misconfigured (wrong permission set, wrong IP) after cutover — this is the actual failure mode that causes "botched rotation halts trading," and the fix is: don't revoke old until new is *proven*, not just *deployed*.

Automate steps 2-4 (secret storage update + scripted verification call) so rotation is a single reviewed script run — manual UI rotation on a schedule is the kind of chore a solo operator quietly stops doing after month three.

---

## 4. What changes specifically because there's no human in the loop

The generic checklist (encrypt secrets, scope keys, rotate) is necessary but doesn't address what's actually different about *unattended*: no one to notice something's wrong in the gap between "anomaly starts" and "capital is meaningfully gone." For a leveraged/fast-moving strategy, that gap can be minutes. Compensating controls have to be automated systems substituting for human judgment/reaction speed.

**Anomaly-triggered automatic kill, not just an alert.** A 3am page is not a control at solo-unattended scale — by the time you wake up and get to a laptop, an automated exploit or runaway bug can have done most of its damage. The control has to *act* before you're awake: hard caps on order rate, position size, per-trade notional enforced by a **separate watchdog process** (not the trading bot itself — if the bot's logic is compromised/bugged, it can't be trusted to police itself) that kills the bot process the moment a cap is breached.

On "auto-revoke the API key via the exchange's own API if a limit is breached" — **UNVERIFIED, likely not available**: none of the exchange docs reachable this session (or recalled) expose a self-service API endpoint to revoke/delete your own API key programmatically; revocation is typically gated behind the web UI with 2FA/email confirmation, specifically *because* letting a key revoke itself (or letting API access revoke keys) would be its own attack surface. **Verify directly against current Binance/Coinbase/Kraken API references before designing a kill-switch around this capability** — if it exists, nice-to-have; if not, don't build the kill-switch's core assumption on it.

Given that, the reliable kill mechanisms are things you control, not things you ask the exchange to do:
- Watchdog process kills the trading bot's process/container instantly on cap breach (fast, local, no exchange dependency).
- Watchdog also revokes network-level ability to reach the exchange — drop outbound to the exchange's API hosts via `iptables`/security group rule — so even a stuck/respawned bot process can't place another order. More reliable than hoping a process kill stops a stuck thread or retry loop.
- On AWS/GCP, the watchdog can additionally revoke the VM's IAM role / rotate the Secrets Manager secret to something invalid, so a restarted bot can't even re-fetch working credentials on reboot.

None require exchange API cooperation — all levers already available as the VM operator, strictly more trustworthy than "call the exchange's API to disable itself" would be even if it existed.

**Secrets never sitting unencrypted longer than necessary.** With a human operator, a plaintext key briefly in shell history is a small, bounded, noticed exposure. Unattended, "briefly" can mean "for the entire process uptime, indefinitely, because no one's looking." Concrete argument for `sops exec-env` over `sops -d > file.env`: the former never writes plaintext to disk (decrypts straight into the child process's environment); the latter leaves a plaintext file outliving the decrypt command unless cleanup is explicit — and unattended, nothing notices if that cleanup silently fails.

**Blast-radius containment: the trading key should never share reach with treasury/cold-storage.** The point that most directly answers "what changes with no human in the loop": with a human watching, a compromised trading VM doing something weird to a *linked* cold-storage account would likely be noticed and stopped before it mattered. Unattended, the VM's compromise and the cold-storage account's compromise happen in the same automated instant — no detection gap to exploit in your favor. Concretely: the trading key must live on a different exchange sub-account (Binance and Coinbase support sub-accounts/portfolios with independently scoped keys) or a wholly separate account from any treasury holdings, with **no API key on the trading VM ever having read or transfer access to the treasury side**, and ideally treasury/cold-storage held with no API surface at all (hardware wallet, exchange account with zero API keys issued). A compromised trading VM should be able to lose, at absolute worst, the working capital actually allocated to the strategy — never the whole fund.

**Net effect of no-human-in-the-loop**: doesn't change *what* the controls are (scoped keys, encrypted secrets, rotation) — changes which controls you can lean on. Anything assuming a person reacts to a signal (an alert, a "does this look right" check, a manual revoke) stops counting as a control and becomes, at best, a forensic record after the fact. The controls that still hold are the ones that act automatically and locally, without waiting on you or the exchange's own protective machinery — why the watchdog-process-plus-network-kill design matters more here than for a system a human is actively watching.
