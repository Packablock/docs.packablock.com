---
layout: page
title: Web Dashboard Tutorial
permalink: /tutorial/
---

# Web Dashboard Walkthrough

The Packablock Web Console provides centralized governance, real-time cryptographic audit logging, and zero-trust identity verification across your software supply chain.

This tutorial guides you through the key features of the dashboard using live verification checkpoints, cryptographic chain trees, and package history explorer tooling.

---

## 1. Fleet Overview & Project Containers

The central landing console provides an immediate high-level summary of your fleet's supply chain health, system security status, and project groupings.

![Packablock Dashboard Fleet Overview]({{ site.baseurl }}/assets/images/tutorials/01-dashboard-overview.png)

### Key Concepts:
* **Secured System Status**: Confirms the Fastify trust registry is online and all local ledger blocks match their cryptographic signatures.
* **Access Tiers**:
  * <span class="tier-pill tier-prem">PREM</span>: Premium repositories enable upstream SemVer tracking, live drift detection alerts, and automated multi-ecosystem attestation gates.
  * <span class="tier-pill tier-std">STD</span>: Standard repositories provide core append-only ledger signing and local CLI integrity checks.
* **Logical Project Containers**: Group multiple polyglot repositories (e.g. Bun microservices, Rails backends, Python processors) under a single project boundary.

---

## 2. Logical Project Governance

Clicking **Manage** on any project container displays all repositories assigned to that functional team or business unit.

![Logical Project Governance View]({{ site.baseurl }}/assets/images/tutorials/02-project-view.png)

### Key Actions:
* **Repository Linkage**: Link or unlink microservice repositories to enforce team-specific policy boundaries.
* **Scoped Access Control**: Multi-tenant authorization ensures developers only see and manage ledgers belonging to their authenticated organization.

---

## 3. Zero-Trust Push Credentials & Key Pinning

Selecting an individual repository opens its audit control plane. The top section inspects cryptographic identities and push authorization.

![Zero-Trust Push Credentials and Trust Anchors]({{ site.baseurl }}/assets/images/tutorials/03-repo-audit-credentials.png)

### Key Elements:
* **Active Push Token**: A high-entropy bearer token required by the `pkablk` CLI or GitHub Actions runners (`pkablk push` / `pkablk check`). Tokens can be instantly invalidated via **Revoke Auth Token**.
* **ACME Verification Challenge**: Displays the active nonce challenge used to mathematically prove repository ownership before trust anchors are accepted.
* **Pinned GPG / Sigstore Trust Anchor**: Stores the raw cryptographic public key (SSH Ed25519, GPG, or Sigstore certificate) pinned in the registry database. Pushes signed by unauthorized actors are rejected before compilation.

---

## 4. Cryptographic Lineage Tree (DAG)

Packablock models package history as a tamper-evident Directed Acyclic Graph (DAG). Each node represents a cryptographically verified milestone in the repository's lifecycle.

![Interactive D3 Cryptographic DAG and Inspector]({{ site.baseurl }}/assets/images/tutorials/04-repo-lineage-dag.png)

### Navigating the Tree:
* **Genesis Anchor Point**: The initial trust root establishing the cryptographic baseline of the repository.
* **Block Checkpoints (Green Nodes)**: Sequential dependency commits containing verified manifests and lockfiles.
* **Epoch Rollover Nodes (Orange Nodes `[ROLLOVER]`)**: Occurs during annual key rotations or major dependency migrations, archiving older blocks into immutable storage while seeding a new root hash.
* **Interactive Ledger Inspector**: Click any block in the lineage tree to inspect its `Meta Hash`, `Data Hash`, and previous link reference (`prev_meta_hash`).

---

## 5. Signed YAML Block Payload Explorer & Minimap

The bottom panel provides a live inspection window into the exact raw cryptographically signed YAML payloads (both `Data` and `Metadata`) stored across ledger blocks.

![Signed YAML Block Payload Explorer and Density Minimap]({{ site.baseurl }}/assets/images/tutorials/05-yaml-block-explorer.png)

### Features:
* **Raw Payload Stream**: Inspect manifest additions across npm (`package-lock.json`), Bun (`bun.lockb`), and Ruby Bundler (`Gemfile.lock`).
* **Verification Metadata**: Expand `# view verification metadata` to review SLSA Provenance v1 attestations, CI runner OIDC claims, and Git author signatures.
* **Timeline Density Minimap**:
  * **Epoch Columns**: Visualizes blocks grouped by rollover epochs (`EPOCH 0`, `EPOCH 1`).
  * **Lockfile Badges**: Color-coded indicators identifying the package manager used in each commit.
  * **Line-Density Dots**: Click any dot slice to smoothly scroll the ledger viewer directly to that block.

---

## 6. Organization Settings & Subscription Tiers

The administration views allow organizations to configure global webhook alerts, define baseline security rules, and manage subscription tiers.

<div class="grid grid-cols-1 md:grid-cols-2 gap-6 my-6">
  <div>
    <h4>Organization Settings</h4>
    <p>Configure automated webhooks, audit log retention, and global security policies.</p>
    <img src="{{ site.baseurl }}/assets/images/tutorials/06-settings-configuration.png" alt="Organization Settings" />
  </div>
  <div>
    <h4>Billing & Tier Controls</h4>
    <p>Manage self-hosted standard vs. commercial enterprise features with direct Stripe customer portal access.</p>
    <img src="{{ site.baseurl }}/assets/images/tutorials/07-billing-tiers.png" alt="Billing and Subscription Tiers" />
  </div>
</div>

<div class="tutorial-cta-box">
  <h3>Ready to secure your software supply chain?</h3>
  <p>Start tracking deterministic dependency ledgers and blocking untrusted package tampering across your builds today.</p>
  <a href="https://packablock.com/signup" class="cta-button" target="_blank" rel="noopener">
    Get Started with Packablock
    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="5" y1="12" x2="19" y2="12"></line><polyline points="12 5 19 12 12 19"></polyline></svg>
  </a>
</div>
