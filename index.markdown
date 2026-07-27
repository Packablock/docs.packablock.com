---
layout: page
title: Home
permalink: /
---

# Packablock Documentation

Packablock is a zero-trust package attestation registry. It generates and verifies cryptographically secured parallel package history chains to defend against software supply chain attacks and package tampering.

---

## 📦 Supported Manifests

Packablock natively parses lockfiles and packages to build and audit mathematical trust chains. It currently supports:

* **npm** (`package-lock.json` v1, v2, and v3)
* **Yarn** (`yarn.lock` v1 classic format)
* **Bun** (`bun.lockb` via yarn format, and Bun 1.2+ JSON lockfiles)
* **Ruby Bundler** (`Gemfile.lock`)

---

## 🛠️ Installation

Install the Packablock command-line client (`pkablk`) via the official installation script:

```bash
curl -fsSL https://raw.githubusercontent.com/Packablock/packablock-client/dev/scripts/install.sh | sh
```

### 🤖 GitHub Actions CI/CD Integration

To guarantee package integrity automatically on every build, run `pkablk check` inside your GitHub Actions workflows:

```yaml
name: Zero-Trust Supply Chain Verification

on:
  push:
    branches: [ main, dev ]
  pull_request:
    branches: [ main ]

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Install Packablock Client
        run: curl -fsSL https://raw.githubusercontent.com/Packablock/packablock-client/dev/scripts/install.sh | sh

      - name: Verify Dependency Chain Against Registry
        run: |
          pkablk check packablock.yaml \
            --server https://api.packablock.com \
            --token ${{ secrets.PACKABLOCK_REGISTRY_TOKEN }}
```

### 🌐 Verifying Against a Remote Registry

You can check the local chain locally, or anchor-verify it against a remote Packablock Trust Registry server:

```bash
pkablk check packablock.yaml --server https://api.packablock.com --token reg_token_123
```

---

## 🚀 Usage

Manage your trust chain using one of the three integration patterns below:

<div class="usage-tabs">
  <div class="tab-buttons">
    <button class="tab-button active" onclick="switchTab(event, 'trust-registry-api')">Trust Registry API</button>
    <button class="tab-button" onclick="switchTab(event, 'sentinel-mode')">Sentinel Mode</button>
    <button class="tab-button" onclick="switchTab(event, 'oci-mode')">OCI Mode</button>
  </div>

  <div id="trust-registry-api" class="tab-content active">
    <p>Manage your trust chain dynamically using local commands and verify dependency blocks against a centralized Packablock Trust Registry server.</p>

    <h3>1. Initialize the Trust Chain</h3>
    <p>Scan your existing project lockfile to initialize a new genesis block in <code>packablock.yaml</code>:</p>
    <pre><code class="language-bash">pkablk init packablock.yaml -l package-lock.json</code></pre>

    <h3>2. Update Your Dependencies</h3>
    <p>Install or upgrade packages as you normally would:</p>
    <pre><code class="language-bash">npm install lodash@4.17.21</code></pre>

    <h3>3. Append the Changes to the Chain</h3>
    <p>Capture the delta between the previous block and the updated lockfile, generating a new cryptographically linked block:</p>
    <pre><code class="language-bash">pkablk append packablock.yaml -l package-lock.json</code></pre>

    <h3>4. Verify Chain Integrity</h3>
    <p>Ensure no block in the historical chain has been altered or compromised against the remote registry:</p>
    <pre><code class="language-bash">pkablk check packablock.yaml --server https://api.packablock.com --token reg_token_123</code></pre>
  </div>

  <div id="sentinel-mode" class="tab-content">
    <p>Store and track your trust chain in an isolated, secure repository branch (e.g. <code>secops/manifest-chain</code>) to prevent developers from directly modifying the manifest files, and run validation gates on your main code branch.</p>

    <h3>1. Fetch and Checkout the Sentinel Branch Manifest</h3>
    <p>Retrieve the latest verified trust chain manifest from the isolated branch:</p>
    <pre><code class="language-bash">git fetch origin secops/manifest-chain:secops/manifest-chain
git show secops/manifest-chain:packablock.yaml > temp_manifest.yaml</code></pre>

    <h3>2. Verify Current Lockfile Against Manifest</h3>
    <p>Ensure your local branch lockfile matches the active Sentinel manifest chain:</p>
    <pre><code class="language-bash">pkablk check temp_manifest.yaml --compare-with package-lock.json</code></pre>

    <h3>3. Append Lockfile Updates</h3>
    <p>Append the package changes to your temporary manifest local file:</p>
    <pre><code class="language-bash">pkablk append temp_manifest.yaml -l package-lock.json</code></pre>

    <h3>4. Commit and Push Back to Sentinel Branch</h3>
    <p>Merge the updated trust chain block back into the secure side branch:</p>
    <pre><code class="language-bash">git checkout secops/manifest-chain
cp temp_manifest.yaml packablock.yaml
git add packablock.yaml
git commit -m "chore(attestation): append dependency updates to Sentinel chain"
git push origin secops/manifest-chain</code></pre>
  </div>

  <div id="oci-mode" class="tab-content">
    <p>Treat your dependency trust chain as a secure OCI artifact and publish it directly to a container registry like GitHub Container Registry (GHCR) to enforce decentralized package trust gates across multiple environments.</p>

    <h3>1. Authenticate with GitHub Container Registry</h3>
    <p>Login to GHCR using your secure deployment credentials:</p>
    <pre><code class="language-bash">echo ${GITHUB_TOKEN} | oras login ghcr.io -u ${GITHUB_ACTOR} --password-stdin</code></pre>

    <h3>2. Pull the Latest Trust Chain Artifact</h3>
    <p>Download the latest verified manifest chain from your GHCR repository:</p>
    <pre><code class="language-bash">oras pull ghcr.io/your_github_org/my-repo/manifest-chain:latest</code></pre>

    <h3>3. Audit Local Lockfile and Append Changes</h3>
    <p>Audit your local project status against the OCI manifest, and write the updated block:</p>
    <pre><code class="language-bash">pkablk check manifest_chain.yaml --compare-with package-lock.json
pkablk append manifest_chain.yaml -l package-lock.json</code></pre>

    <h3>4. Push the Updated Manifest to GHCR</h3>
    <p>Publish the new trust chain artifact back to your OCI repository registry:</p>
    <pre><code class="language-bash">oras push ghcr.io/your_github_org/my-repo/manifest-chain:latest manifest_chain.yaml:application/yaml</code></pre>
  </div>
</div>

### 💻 CLI Visualizations & Audit Reports

Running an audit check on your dependencies with the `--visualize` flag renders a detailed **SemVer Candle Chart** mapping pinned versions against constraints and upstream releases, highlighting security warnings and policy violations:

<div class="terminal-mockup">
  <div class="terminal-header">
    <div class="terminal-buttons">
      <span class="btn close"></span>
      <span class="btn minimize"></span>
      <span class="btn expand"></span>
    </div>
    <div class="terminal-title">bash — pkablk audit</div>
  </div>
  <div class="terminal-body">
    <pre><code><span class="term-bold">🔍 Packablock Supply Chain Velocity Audit</span>
Target: /home/aaron/dev/my-project
Registry Anchor: https://api.packablock.com
Status: <span class="term-green term-bold">SECURELY ANCHORED (14 Blocks Aligned)</span>

<span class="term-bold">## SemVer Candle Analysis (Lockfile Lifecycle)</span>
Legend:
  | : Min/Max Constraint Boundary   ░ : Historical Drift (First seen -> Pinned)
  ● : Current Pinned Version        ═ : Unused Allowed Range (Upstream Available)
  ► : Extension to Infinity (>=)

### Manifest: package.json
<span class="term-dim">--------------------------------------------------------------------------------</span>
Package Name      Tracked  Constraint  Timeline (Low -> Pinned -> Upstream -> Max)
<span class="term-dim">--------------------------------------------------------------------------------</span>
lodash            <span class="term-green">Yes</span>      ^4.17.0     <span class="term-cyan">|</span><span class="term-dim">░░░░░</span><span class="term-yellow">●</span><span class="term-dim">════════════════════════════════════</span><span class="term-cyan">|</span>
fastify           <span class="term-green">Yes</span>      ^4.20.0     <span class="term-cyan">|</span><span class="term-dim">-----░░░</span><span class="term-yellow">●</span><span class="term-dim">════════════════════════════════</span><span class="term-cyan">|</span>
typescript        <span class="term-green">Yes</span>      >=5.0.0     <span class="term-cyan">|</span><span class="term-dim">-----░░░░░░</span><span class="term-red">●</span><span class="term-dim">============================</span><span class="term-red">►</span>
eslint            <span class="term-red">No</span>       ^8.40.0     <span class="term-cyan">|</span><span class="term-dim">░░░░░░░░░░░░░</span><span class="term-green">●</span><span class="term-dim">══════════════════════════</span><span class="term-cyan">|</span>
<span class="term-dim">--------------------------------------------------------------------------------</span>

<span class="term-bold term-yellow">Warn:</span>
  <span class="term-red">Open Fuse (>= Risk):</span> typescript
  <span class="term-yellow">Technical Debt Wall:</span> lodash, fastify

<span class="term-bold">Info:</span>
  <span class="term-green">Fully Up-To-Date:</span> eslint

<span class="term-yellow">Tip: Register this log to a Packablock registry to enable automated enterprise security policies and webhook alerts.</span></code></pre>
  </div>
</div>

---

## 🤝 Contributing

Packablock is an open-source standard. We welcome specifications feedback, parser improvements, and registry suggestions. 

Please read the **Call for Community Contributions** section in our [Continuous Attestation Specification]({{ site.baseurl }}/spec/) to learn about the current active feedback areas and how you can get involved.

---

## 👥 Team

Packablock is created and maintained by:

* **Aaron Bronow**
  * [GitHub](https://github.com/aaronbronow)
  * [LinkedIn](https://www.linkedin.com/in/aaronbronow)
