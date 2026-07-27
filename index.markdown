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

Manage your trust chain directly alongside your codebase using the following workflow:

### 1. Initialize the Trust Chain
Scan your existing project lockfile to initialize a new genesis block in `packablock.yaml`:

```bash
pkablk init packablock.yaml -l package-lock.json
```

### 2. Update Your Dependencies
Install or upgrade packages as you normally would:

```bash
npm install lodash@4.17.21
```

### 3. Append the Changes to the Chain
Capture the delta between the previous block and the updated lockfile, generating a new cryptographically linked block:

```bash
pkablk append packablock.yaml -l package-lock.json
```

### 4. Verify Chain Integrity
Ensure no block in the historical chain has been altered or compromised:

```bash
pkablk check packablock.yaml
```

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
