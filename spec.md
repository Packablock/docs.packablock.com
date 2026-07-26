---
layout: page
title: Continuous Attestation Specification
nav_title: Specification
permalink: /spec/
---

# Continuous Attestation

## *Specification v1 DRAFT June 26 2026*

*A standard for tracking how software components change over time. It defines a portable history of dependency package versions that is easily readable by both human auditors and automated tools. Because every update is mathematically linked to the one before it via SHA256 hash, the framework guarantees that any attempt to alter the software's history is immediately exposed.*

*This specification essentially describes a log file format with advanced capabilities. Its guiding principles include easy adoption, rapid risk identification, continuous improvement, and high degrees of automation and extensibility.*

## Table of Contents
{: .no_toc}

* TOC
{:toc}

# 1\. Introduction and Architectural Concepts

Modern software supply chains rely heavily on isolated, point-in-time attestations. Attestation is provenance of an action performed on a digital artifact (like source code, build logs, dependencies, or final binaries). The current standards in traditional Continuous Integration / Continuous Delivery (CI/CD) environments for build artifacts do not include the history of dependency changes and who approved them. To address this gap, we must integrate Continuous Attestation (CA)—a practice that maintains a consistent history of changes over time—expanding the delivery pipeline into a unified Continuous Integration / Continuous Delivery / Continuous Attestation (CI/CD/CA) framework.

While generating a static Software Bill of Materials (SBOM) or cryptographically signing a single artifact has become an industry standard, this approach natively lacks chronological state. Adversaries can exploit this disconnect by executing split-timeline or rollback attacks—resurrecting older, mathematically valid, but fundamentally compromised configurations to bypass static security checks. Furthermore, as these disconnected logs multiply, they scale beyond the capacity of human auditors to manually triage. Even LLM agents with large context windows frequently fail to deterministically find changes in the middle of a large dataset, creating a critical blind spot for enterprise compliance.

With coding agents producing more code than humans, the CI/CD/CA gatekeeper has never been more important. The industry standard response has been to add more gates to build pipelines. However, a hard assertion that the build may only pass if a version is “equal to or greater than” is overly simplistic and will negatively impact productivity by blocking legitimate changes some of the time. CI/CD/CA pipelines must become smarter and more aware of package manager criteria rules (like SemVer) and how to continuously log not only current version but version drift over time.

Afterall, “when data is easy to view and understand, programming becomes a simpler task.”

The Continuous Attestation Specification addresses these gaps by defining a portable, mathematically verifiable, continuous log. Rather than implicitly trusting disconnected static snapshots, this specification defines the interaction between four modular system components to create an unbroken, sequentially linked audit trail designed for automated enforcement:

1. **Manifest Chain:** `manifest_chain.yaml` The manifest chain stores the content of a tracked file (package.lock for example) and sequential difference for each change to that file. There may be many tracked files and many diffs appended to the manifest chain as blocks (YAML document segments). After every block the chain stores a metadata document. The metadata contains cryptographic hashes joining the previous block to the current block. The manifest chain acts as a transactional delta log, storing a permanent timeline of the modifications up to the most recent anchor point.  
2. **Chain Anchor (Detached or Registry):** The chain anchor represents a fingerprint of the manifest chain at a point in time. This spec describes a system in which there can be only one anchor per manifest chain and it will store the cryptographic hash of the most recent block, the full chain, and the signature of the attestor. This is maintained either through a portable, detached chain anchor file (e.g., `chain_sig.yaml`) paired with the manifest chain file, or in an external registry database.  
3. **Registry:** A cryptographically secure, immutable transparency log for storing dependency package change events. The registry accepts manifest chain updates, processes client signatures, and serves as a permanent audit log accessible by API or web interface. Registries may be centralized or self-hosted depending on the resources available to the maintainer or the security needs of the enterprise.  
4. **CLI Management Tool:** The maintainer client responsible for initializing tracked files into the manifest chain, calculating deltas, and hashing the content blocks into cryptographic metadata. The CLI enables standalone, constant-memory offline verification for isolated environments, or online verification against the registry. It also provides methods for orchestrating key rotation and rollover when files get too large.

By standardizing the flow of data between the manifest chain, the anchor, the registry, and the CLI tooling, this specification provides maintainers with a deterministic, AI-readable framework that bridges high-velocity development with rigorous supply chain compliance.

## 1.1 Scope and Goals

This specification establishes the requirements for Continuous Attestation using change tracking decoupled from the repository. Tracking changes using this standard provides a continuous, cryptographically consistent lineage of software artifacts. The framework seeks to ensure that there is no possibility of tampering, rollback, or insertion of compromised artifacts. This process, paired with the steps laid out in SLSA allows automated systems and human auditors to trace the provenance of the change history. Because the complete change history of tracked files (like package.lock) is securely stored in the manifest chain and registry auditors can quickly report on what changed and when using a single query. Because the manifest chain must be cryptographically consistent on every update, maintainers can configure the build pipeline to fail early if a tracked file changed without adhering to a defined process. Because the CLI can efficiently validate a manifest chain and search for semantic changes within the tracked files, AI agents can use tool calls to deterministically answer questions about what changed without context window collapse. 

To smooth the friction between high-velocity deployments and rigorous compliance auditing, implementations of this specification shall adhere to the following core design goals:

* **Do-No-Harm:** First and foremost, implementing Continuous Attestation as defined in this spec shall not slow down productivity or introduce false-positives.  
* **Be Open-Minded but Opinionated:** The CLI shall accept any format of text file as full document or diff for tracking changes to the subject file either manifest (like package.json) or lockfile (like package.lock). The CLI shall parse and securely store the content in either raw (byte-for-byte) format or semantic (cleaned, normalized, sorted) format. Although the manifest chain can store any textual content, the reporting tools prefer SemVer format versions stored in semantic content format.  
* **AI and Machine Readability:** As software supply chains scale beyond human capacity to manually triage, the specification shall provide a deterministic, structured schema optimized for artificial intelligence. This spec describes how a tool can produce a portable record of changes to the software that is cryptographically consistent and can be published to a trusted 3rd party registry. The fact that the record was written successfully, signed, and published can be deterministically verified at build time. Auditors can use AI with tools to read the record and report the state of the software with little risk of hallucination.  
* **Human-Friendly Reviewability:** While cryptographic metadata inherently requires tooling to compute hashes and verify signatures, the underlying attestation payloads must remain structurally transparent. Leveraging the core design goals of YAML to be easily readable by humans, developers and compliance auditors shall be able to visually inspect the exact delta of a transaction as it is stored in the manifest chain. This ensures that the semantic intent of a modification is always obvious to a human operator before automated tooling mathematically seals the block. Once the block is stored you can’t rewrite history.  
* **Ecosystem Compatibility and Timeline Continuity:** Modern supply chain environments—such as GitHub's native signing infrastructure and Sigstore's Rekor—excel at providing isolated, point-in-time build signatures and writing them to immutable transparency logs. However, isolated point-in-time attestations natively lack chronological state, leaving consumers vulnerable to adversaries who might replace a current artifact and its valid attestation with an older, mathematically valid but fundamentally compromised version. This spec defines a framework that coexists beneficially with GitHub, Sigstore, and enhances SLSA process. The stand-alone nature of the manifest chain as a secure and complete historical change log hopefully allows new maintainers to achieve enterprise-grade supply chain security without complex integrations. The open nature of the manifest chain format ensures simple adaptation into existing infrastructure.  
* **Incremental, Diff-Only State:** Supply chain metadata must not require monolithic, full-file overwrites for minor dependency updates. Taking inspiration from Git's version control architecture which records incremental changes to branch tips, the manifest chain shall act as a transactional delta log. By appending only the exact filesystem event (delete) or line-level modifications, the specification guarantees a reliable, sequentially auditable change history without inflating file sizes. Concise and chronological change history promotes readability by AI agents without overwhelming context.

### 1.1.1 Comparison with Github and Rekor

Here is the architectural breakdown comparing the security postures and vulnerability profiles of four common deployment scenarios.

| Scenario | \+ Security & Benefits \- Vulnerabilities & Limitations |
| :---- | :---- |
| **1\. Rekor / GitHub Attestations Only** (No Manifest Chain) | **\+ Immutable Point-in-Time Auditing:** Excels at minting isolated build signatures and writing them to highly scalable, publicly auditable certificate transparency logs. **\+ No Key Management:** Leverages OpenID Connect (OIDC) to issue short-lived, ephemeral certificates, eliminating the risk of stolen long-lived keys. |
|  | **\- Chronological Blindspot:** Isolated point-in-time attestations fundamentally lack chronological state. Consumers are vulnerable to adversaries who might replace a current artifact and its valid attestation with an older, mathematically valid, but fundamentally compromised version.  **\- Opacity of Deltas:** Provides a snapshot of an artifact but cannot incrementally log the discrete dependency additions or removals that led to that state. |
| **2\. Only CLI with Manifest Chain** (Standalone / Offline Mode) | **\+ Offline Integrity:** Enables standalone, constant-memory verification for isolated environments. **\+ Tamper-Evidence:** Mathematically guarantees the sequence of operations by verifying `data_hash` and `meta_hash` links from the genesis block forward. |
|  | **\- Open ended manifest chains:** Because validation is strictly local and offline, a parser cannot detect if the timeline has been superseded. An attacker can execute a rollback attack by providing a historically valid (but outdated and vulnerable) version of the chain. **\- Lack of Identity:** Raw YAML chains verify *what* changed, but without signatures, they cannot prove *who* authorized the change. |
| **3\. Manifest Chain with Detached Anchor File** (e.g., `chain_sig.yaml`) | \+ **Identity & Non-Repudiation:** Cryptographically binds the `meta_hash` of the latest block to a developer's identity using GPG or SSH signatures via a lightweight detached manifest. **\+ Anchor Singularity:** Establishes a single, absolute target for CI/CD/CA pipelines to verify the latest timeline state, preventing naive rollback attacks. |
|  | **\- Repository-Level Compromise:** Susceptible to key theft. If an attacker gains force-push access *and* compromises a maintainer's signing key, they can rewrite history and forge a new detached anchor. **\- Enforcement Reliance:** Relies entirely on the CI/CD/CA pipeline to strictly verify the signature; without mandatory remote gating, the local files could still be bypassed. |
| **4\. Manifest Chain with Sovereign Registry** (e.g., Packablock Registry) | **\+ Continuous Truth Anchor:** Provides a centralized, immutable ingestion endpoint that absolutely guarantees timeline continuity, preventing split-timeline and downgrade attacks. **\+** **Agentic Automation:** Triggers real-time SemVer webhooks and interactive telemetry to automatically gate CI/CD/CA pipelines based on chronological state. |
|  | **\- Network & Availability Dependency:** Introduces a strict external network dependency; if the registry goes offline, deployments and verifications may halt. **\-** **Infrastructure Trust:** Requires trusting the registry's control plane administrators to not abuse privileges or tamper with the database storage, as the registry acts as the ultimate gatekeeper. |

### Use Case 1: No Attestation

1. **Download Request:** The developer initiates a download of a binary (e.g., "bun") from a domain they trust over a secure SSL/HTTPS connection.  
2. **File Delivery:** The hosting server (such as GitHub) returns the requested binary file to the developer.  
3. **Checksum Request:** The developer fetches the published static SHA checksum associated with that specific binary.  
4. **Checksum Delivery:** The server returns the static SHA checksum to the developer.  
5. **Static Verification:** The developer locally computes the hash of the downloaded file and verifies that it matches the provided SHA checksum.  
6. **Execution (Implicit Trust):** Assuming that everything prior to the download was trustworthy, the developer executes the binary, which represents a security posture with "no guarantees" except that the file saved is the byte-for-byte match to the file requested (equivalent to SLSA Build Level 0).

![][use-case-1-no-attestation]




### Use Case 2: Validate Continuous Attestation Artifacts

1. **Download:** The developer requests an OCI Image Artifact from the registry.  
2. **Receive Artifacts:** The registry returns the software binary alongside its dependency change history (`manifest_chain.yaml`) and detached anchor (`chain_sig.yaml`) inside the image.  
3. **Initiate Validation:** The developer executes the `pkablk check` command via their CLI. The offline operation validates the internal consistency of the manifest chain and the anchor links the signature to the chain in its current state.  
4. **Verify Provenance:** In online mode the CLI automatically queries the GitHub Attestation API or Sigstore Rekor transparency log.  
5. **Verify Build Identity:** The system verifies the OpenID Connect (OIDC) build identity and execution environment confirming that the signer of the chain was present at build time.  
6. **Verify Manifest Chain:** The full scan mode CLI sequentially evaluates the `manifest_chain.yaml` file, checking the `data_hash` and `prev_meta_hash` links to ensure no malicious dependencies were added, changed, or removed.  
7. **Verify Anchor:** The CLI validates the detached anchor (`chain_sig.yaml`) to check the author's identity signature and prevent rollback attacks.  
8. **Report Success:** The CLI outputs a success report to the developer.

![][use-case-2-validate-ca-artifacts]


### Use Case 3: Package Manager Verification

1. **Initiate Install:** The developer executes the standard `npm install` command, which is intercepted by the `pkablk` CLI wrapper or called as a helper.  
2. **Fetch Dependency Graph:** The package manager queries the registry to retrieve the entire graph of required dependencies.  
3. **Download Artifacts:** The registry returns the package binaries alongside their basic static SHAs, `manifest_chain.yaml` dependency change history, and `chain_sig.yaml` detached anchor.  
4. **Perform Static SHA Check:** For every dependency, the `npm` locally verifies that the downloaded file matches the basic transport SHA.  
5. **Validation:** The developer executes the `pkablk check` command via their CLI. It validates the internal consistency of the dependency change history in the Manifest Chain,  
6. **Verification:** The system verifies the OpenID Connect (OIDC) build provenance via the Attestation API, and verifies the author signature.  
7. **Graceful Degradation:** If a package matches the static SHA but lacks a Manifest Chain or Attestation API record, the system does not halt the build. Instead, it flags the dependency with a warning (Implicit Trust) to signal an unverified history.  
8. **Output Consolidated Report:** The terminal displays a report of all dependencies validated or implicitly trusted, allowing the developer to safely proceed with building the application while providing actionable security debt information.

![][use-case-3-package-manager-verification]


### Use Case 4: The CI/CD/CA Builder Pipeline

1. **Initialize Build Environment:** The GitHub runner establishes an ephemeral, isolated execution environment to satisfy SLSA Build Level 3 requirements.  
2. **Diff Manifest:** The runner evaluates the tracked package manifests (e.g. package.json and package-lock.json) and detects a version change for an upstream dependency.  
3. **Download Upstream Binary:** The runner fetches the newly updated upstream binary from the package registry.  
4. **Validate Transport SHA:** The runner locally confirms that the downloaded file matches the expected static SHA checksum.  
5. **Verify Build Provenance:** The runner queries the Attestation API (or transparency log) to validate the OpenID Connect (OIDC) identity of the upstream build.  
6. **Check Manifest Chain:** The runner attempts to fetch the upstream package's `manifest_chain.yaml`.  
7. **Degradation Warning:** Upon finding the upstream dependency change history missing, the runner gracefully degrades the trust level by logging a warning, but permits the build to continue.  
8. **Compute Diff:** To record its own state change, the runner uses tooling to parse the version change. The tool looks for SemVer (`>=8.0.0`) criteria and calculates the `data_hash` of the local manifest's content.  
9. **Append to Dependency Change History:** The diff of the package manifest (package.json) and lockfile (package-lock.json) are tracked and appended to the dependency change history. The runner generates a new `$manifest-chain-link` block, binding it to the timeline using the `prev_meta_hash` link.   
10. **Sign Block:** The runner authenticates and cryptographically signs the new block using its short-lived OIDC identity.  
11. **Push to Enterprise Registry:** The runner sends the appended, signed chain to the Enterprise Registry, to validate the chronological sequence and record it in the internal transparency log.  
12. **Release Bundled OCI Artifact:** The runner compiles the application and packages the final binary, the updated `manifest_chain.yaml`, and the logged warnings into a synchronized OCI Artifact for downstream consumption.

![][use-case-4-builder-pipeline]

### Use Case 5: CVE Impact Audit with AI

1. **Initiate Audit:** The Incident Response team prompts the AI auditor agent with the specific CVE and the vulnerable package version range.  
2. **Fetch Production Evidence:** The agent pulls the latest Bundled OCI Artifact (the synchronized compiled binaries and `manifest_chain.yaml`) from all multi-tenant production environments.  
3. **Evaluate Point-in-Time State:** The agent parses the final block of each dependency change history to generate a current SBOM snapshot (or uses a static SBOM if present), flagging any tenants that are actively running the vulnerable version. The agent infers from the report that one environment is vulnerable (Tenant A).  
4. **Detect Safe Environments:** For tenants not currently vulnerable (Tenant B), the agent confirms that the final block contains a newer, unimpacted version of the dependency.  
5. **Traverse Historical Lineage:** The agent sequentially parses the dependency change history backwards for these safe tenants to verify if the vulnerable package was ever historically used in their environment. This is nearly instant because manifest\_chain.yaml contains the diff of every version change in the tracked files.  
6. **Extract Remediation Proof:** The agent identifies the specific historical semantic diff block where the package was patched to the safe version, extracting the timestamp and author `signature_auth`.  
7. **Compile Forensic Report:** The agent consolidates this evidence into a final audit report that proves which tenants are currently vulnerable, which tenants were vulnerable and for what timespan, and exactly when the others were safely upgraded.

![][use-case-5-cve-impact-audit]

### Use Case 6: Build Sentinel

1. **Initialize Sentinel Environment:** The SecOps team creates an isolated, dedicated Git branch (e.g., `secops/manifest-chain`) containing the initial `manifest_chain.yaml` and detached signature (chain\_sig.yaml), keeping it separate from the developers' workspace.  
2. **Developer Push:** A developer pushes code and lockfile changes to the `main` branch normally, blissfully unaware of the automated security mechanisms.  
3. **Action Trigger & Dual Checkout:** A GitHub Action triggers automatically with an ephemeral OIDC identity and checks out both the `main` source branch and the `secops` manifest branch.  
4. **Compute Diff & Append:** The runner evaluates the developer's new lockfile, checks SemVer criteria, computes the `data_hash` of the semantic delta, and appends a new block to the manifest chain using the `pkablk` CLI.  
5. **Push to Enterprise Registry:** The runner sends the appended chain to the Enterprise Registry, to validate the chronological sequence and store the record.  
6. **Commit:** The runner pushes the updated `manifest_chain.yaml` and `chain_sig.yaml` files back to the `secops` branch, leaving the `main` branch unmodified.  
7. **Attest:** The runner uses the GitHub Attestation API to mint an unfalsifiable OpenID Connect (OIDC) build provenance attestation.  
8. **Publish to Transparency Log:** The signature event is published to Sigstore's Rekor transparency log, publicly recording the chronological timeline to prevent rollback attacks.  
9. **Package Bundled OCI Artifact:** The pipeline copies the compiled binary and the shadow chain files into an empty `scratch` container and pushes it to an OCI registry as a synchronized, content-addressable unit.

![][use-case-6-build-sentinel]

### Use Case 7: AI Hallucinates Changes in a PR

1. **AI Task:** An autonomous coding agent makes sweeping changes to a repository, burying a vulnerable dependency update inside a massive, 10,000-line pull request.  
2. **Version Drift Introduced:** Attempting to resolve a version conflict, the agent hallucinates an open-ended constraint, replacing a strictly pinned version with an unbounded descriptor (e.g., `>=1.2.0`).  
3. **Draft State:** Because the agent lacks a specific Machine Identity (like an ephemeral OIDC token), it does not have the authorization to sign the change, leaving the manifest in a "Draft State".  
4. **Deterministic Circuit Breaker:** The CI/CD/CA pipeline intercepts the pull request using the `pkablk` wrapper to mathematically evaluate the semantic diff, completely avoiding the expensive, non-deterministic loop of using another AI scanning tool to grade the first AI.  
5. **Automated Rejection:** The gateway immediately halts the pipeline and rejects the commit for two deterministic reasons: it proves the agent lacked the permission to sign the change, and it explicitly catches the unbounded descriptor as an Open Fuse (version promiscuity) policy violation.  
6. **Granular Audit Log Output:** Instead of forcing compliance managers and developers to manually decipher the massive PR, the system outputs an instantly readable, isolated transaction block detailing exactly what the agent hallucinated and when (e.g., *Block 43: Agent-XYZ updated package 'X' to \>=1.2.0 at 14:22 UTC*). The job summary also clearly states the manifest\_chain.yaml was not signed by a valid signer.

![][use-case-7-ai-pr-hallucination]

## 1.2 Normative References

The following documents are referred to in the text in such a way that some or all of their content constitutes requirements of this document.

* IETF RFC 2119: Key words for use in RFCs to Indicate Requirement Levels.  
* IETF RFC 3339: Date and Time on the Internet: Timestamps.  
* IETF RFC 3629: UTF-8, a transformation format of ISO 10646\.  
* YAML 1.2.2: YAML Ain't Markup Language (YAML™) revision 1.2.2.  
* NIST FIPS 180-4: Secure Hash Standard (SHS), specifically defining the SHA-256 algorithm required for payload and metadata hashing.  
* SLSA Specification: Supply chain Levels for Software Artifacts (v1.2), detailing the requirements for provenance generation and build environment isolation.  
* OCI Image Spec: Open Container Initiative Image Format Specification, defining the architecture for the Bundled OCI Artifact.  
* ORAS Artifact Manifest: OCI Registry As Storage Artifact Manifest Specification, defining the artifactType and subject properties for supply chain graph linking.

## 1.3 Terminology

### 1.3.1 Normative Conventions 

The keywords “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” are used as defined in RFC 2119\.

### 1.3.2 Core Architectural Concepts 

The following definitions apply throughout this specification:

* **Continuous Attestation (CA):** A software engineering practice that maintains a sequentially linked, cryptographically consistent history of software changes over time. It functions as a deterministic integration and deployment circuit breaker through the following mechanisms:  
  * An authenticated, machine-readable statement (metadata) generated continuously about a software artifact or collection of artifacts.  
  * Granular Change Logging: It records changes to files (like dependency lockfiles) as isolated, append-only events in a manifest chain decoupled from the code repository, ensuring complete visibility of "what changed, when, and where".  
  * Sequential Cryptographic Lineage: Each block in the chain is mathematically bound to its predecessor to prevent tampering, insertion of compromised artifacts, or history-rollback attacks.  
  * Deterministic CI/CD/CA Gating: Pipelines are configured to automatically verify the manifest chain on every update, instantly halting and failing the build if a tracked file changes without adhering to authorized procedures.  
  * Agent-Safe Provenance Queries: Because the semantic history is highly structured, auditors and automated systems can query the exact change lineage efficiently, ensuring full visibility into automated modifications without risking context window limitations.  
* **CLI:** runs in build environment or maintainer/dev environment or user environment and writes/updates/verifies Manifest Chain file and detached Manifest Anchor (file or registry entry) using the content in subject manifests.  
* **Subject:** Every Manifest Chain MUST contain one or more subjects. Subject attribute defines an association to another manifest. The subject is usually a file like package.json but can also be a blob of text like output from diff.  
* **Manifest Chain File:** `manifest_chain.yaml` A multi-document YAML file that serves as a continuous, immutable audit trail. It strictly alternates between format-agnostic data payloads and cryptographic metadata validation blocks (`$manifest-chain-link`). Because it acts as a chronological log of subject file changes, a chain file MUST be processed sequentially block by block to recreate (checkout or rebuild) a manifest file. Specific blocks may be read to discover a change that occurred at a specific time.  
  * **Diff Strategy:** The method used to compare two subjects to be stored in the content block. The two methods defined in this spec are Line and Semantic. **`Line`**, like Git changesets, represent the raw text difference. **`Semantic`** represents the difference between versions assuming they can be parsed using SemVer standards.  
  * **Content Block:** The chronological sequence of discrete dependency modifications (additions, removals, upgrades) recorded as individual semantic or line-based diff blocks. This provides the verifiable lineage of exactly how an application's dependencies evolved over time.  
  * **Validation Block (`$manifest-chain-link`):** The structural object within the YAML chain responsible for chronological linking. It enforces software sequence integrity by permanently binding a payload's `data_hash` to a `meta_hash`, anchored chronologically by the `prev_meta_hash`. Can be referenced by Manifest Chain Anchor.  
* **Manifest Chain Anchor:** A lightweight, secondary schema (e.g., `chain_sig.yaml`) that captures the absolute latest block anchor from the chain. It is used to enforce mandatory signed Git commits and non-repudiation without requiring parsing engines to manage large inline cryptographic signatures. Can be stored in OCI or Registry.  
* **Registry:** A cryptographically secure, immutable, and multi-tenant ledger that acts as a continuous truth anchor for the software supply chain. The Registry serves as an authoritative verification and distribution endpoint to satisfy compliance across both the SLSA Build and Source Tracks:  
  * SLSA Build Track Alignment (Build L2/L3): The Registry acts as a trusted verifier or distribution platform. It ingests the Manifest Chain (manifest\_chain.yaml) alongside the Detached Anchor (chain\_sig.yaml), verifies the cryptographic signatures, and validates the chronological sequence to prevent split-timeline and history-rollback attacks. By validating that the signed build provenance matches established producer expectations, it mitigates tampering during and after the build (SLSA Build L2/L3). It may also generate and issue a Verification Summary Attestation (VSA) to downstream consumers to optimize verification performance.  
  * SLSA Source Track Alignment (Source L2/L3/L4): The Registry programmatically ingests and cross-checks the Source Verification Summary Attestations (Source VSAs) and Source Provenance issued by the Source Control System (SCS). It verifies that the source revisions are immutable, that branch history has remained continuous, and that required organizational technical controls (Source L3) or two-party reviews (Source L4) were successfully enforced prior to build execution.  
* **SLSA Compliance:** Adherence to the Supply chain Levels for Software Artifacts (SLSA) framework. Within this specification, compliance is understood as achieving SLSA Build Track Level 2—which requires organizations to protect against software tampering after the build and generate authenticated provenance—and establishing the architectural foundation for Build Track Level 3 by utilizing hardened, isolated CI/CD/CA execution environments to ensure provenance cannot be forged or altered during the build. The SLSA standard complements and can generate an SBOM.  
* **Software Bill of Materials (SBOM):** A static file providing a single, point-in-time snapshot of an environment. Because an SBOM is designed to be parsed *in-toto*, it offers a distinct operational advantage in parsing speed and immediate readability. An SBOM is complementary to the dependency change history; an auditor or user can generate a point-in-time SBOM directly from the chain file if they wish to.  
* **Bundled OCI Artifact:** A content-addressable packaging architecture (such as an OCI Artifact) that freezes a compiled release binary, the manifest chain, the chain anchor together into an all in one OCI manifest. Any alteration to the compiled binary instantly breaks the signature verification of the entire package.

## 1.4 Call for Community Contributions

The Continuous Attestation specification relies on a modular, decentralized architecture that is designed to grow through community contribution. To guide open source contributors, tool builders, and security auditors, this section outlines the unresolved architectural questions that are actively open for discussion and development. According to Nadia Asparouhova’s book *Working in Public,* “more people should contribute to open source.”

### 1.4.1 Active Community Contribution Areas

We explicitly invite contributions, draft proposals, and prototype implementations in three key areas:

**A. Pluggable Semantic AST Adapters (Section 4.1.4)**

The Semantic Diff Strategy requires parsing language-specific dependency lockfiles (such as npm's JSON, Cargo's TOML, or Poetry's lock format) into a standard, sorted, abstract syntax tree (AST).

**The Technical Challenge:** Designing a lightweight, pluggable interface that allows developers to publish custom AST parsers.

**Open Questions:**

* Should we standardize on a Unix-style execution model (accepting raw lockfiles on stdin and returning a standardized JSON schema representing the semantic diff on stdout)?  
* What are the minimal required schemas for the standard upgraded, added, and removed dependency arrays across different packaging ecosystems?

**B. SCM Shadow Branch Concurrency Resolvers (Section 5.2.5)**

Enforcing continuous attestation by writing transaction logs to a protected shadow branch (e.g., secops/manifest-chain) introduces concurrency conflicts when multiple CI/CD pipelines run in parallel.

**The Technical Challenge:** When parallel build runners attempt to append a new block to manifest\_chain.yaml simultaneously, the prev\_meta\_hash on one of them will become stale.

**Open Questions:**

* How can we specify an automated, optimistic rebase-and-retry mechanism inside the CLI client (pkablk)?  
* How do we securely re-sign and validate updated Validation Blocks on the fly using short-lived OIDC machine tokens without introducing manual review loops?

**C. Federated Registry Equivocation and Split-View Gating**

When software is distributed across federated or mirrored registries, a compromised registry could execute a "split-view" attack (serving a valid timeline to auditors while deploying outdated or manipulated chains to victims).

**The Technical Challenge:** Ensuring global state consensus without the overhead of smart contracts or transaction mining.

**Open Questions:**

* Can we define a pluggable ledger type for Sigstore's Rekor to record terminal manifest chain state signatures (chain\_sig.yaml)?  
* How should downstream verification clients cross-verify the local registry's state height against the public Rekor transparency log?

# 2\. Basic Format and Grammar

## 2.1 File Naming and MIME Types

To ensure cross-platform compatibility and immediate recognition by standard software development tools, Continuous Attestation manifest chains adhere to strict naming and typing conventions.

* **File Extension:** The manifest chain file MUST use the `.yaml` file extension.  
* **Default Manifest Chain Name:** The primary continuous chain file SHOULD be named `manifest_chain.yaml` to establish a recognizable convention within a repository.  
* **Detached Anchor Name:** As defined in Section 5.2.4 (The Anchor Singularity Rule), the detached anchored manifest MUST be housed in a separate file, which SHOULD be named `chain_sig.yaml`. However, the anchor may also be stored in a database in a registry.  
* **MIME Type:** When transferring the manifest chain over HTTP or packaging it within an OCI registry, implementations MUST utilize the `application/vnd.packablock.manifest-chain+yaml` MIME type (as defined in Section 5.3) rather than the generic `text/yaml`.

## 2.2 Character Set and Encodings

Because the Manifest Chain relies on exact byte streams to calculate and verify cryptographic hashes (e.g., `data_hash`, `meta_hash`), any ambiguity in character encoding will result in verification failures. Failures can be interpreted as either invalid content or as valid content with invalid Verification Block.

* **UTF-8 Enforcement:** While the official YAML 1.2.2 specification permits UTF-16 and UTF-32, a Continuous Attestation file MUST be a valid, strictly UTF-8 encoded Unicode document. According to the IETF RFC 3629,  "SHOULD forbid use of U+FEFF as a signature." Implementations MUST NOT emit a Byte Order Mark (BOM), and parsers MUST reject streams encoded in UTF-16 or UTF-32 to prevent hash mismatches.  
* **Allowed Characters:** To ensure readability and parsing consistency, streams MUST use only the printable subset of the Unicode character set. The allowed character range explicitly excludes the C0 control block (except for TAB `x09`, LF `x0A`, and CR `x0D`), DEL `x7F`, and the C1 control block.  
* **Line Breaks:** YAML 1.2 strictly recognizes only ASCII line break characters (specifically Line Feed `0x0A` and Carriage Return `0x0D`). To ensure strict compatibility with JSON, non-ASCII line breaks—such as next line (`0x85`), line separator (`0x2028`), and paragraph separator (`0x2029`)—are treated as regular non-break characters. Line breaks inside scalar content MUST be normalized by the processor to a single line feed (LF, `x0A`).

## 2.3 Syntax Conventions and Structural Productions

The Continuous Attestation software engineering practice leverages the native features of YAML to create a sequential, multi-document manifest chain.

* **Multi-Document Streams:** The manifest chain is structured as a continuous YAML stream containing multiple sequential documents. Each transaction or block MUST be separated by the explicit document marker consisting of three dashes (`---`). A single logical transaction consists of two paired documents: the data payload followed immediately by the `$manifest-chain-link` verification block.  
* **Indentation:** Structure MUST be determined strictly by indentation using zero or more space characters. To maintain absolute portability across CI/CD/CA environments, tab characters MUST NOT be used for indentation.  
* **Literal Block Scalars for Foreign Data:** When using the manifest chain to track configurations written in foreign formats (such as embedded JSON, TOML, or raw text), the data MUST be wrapped using the YAML literal block scalar style (denoted by the `|` indicator). Inside literal scalars, all characters, spaces, and line breaks are considered literal content. This strictly forbids the parser from folding lines or stripping spaces, ensuring the underlying file's exact byte stream remains perfectly intact for `data_hash` verification.


# 3\. Core Structures and Types

To maintain structural clarity and interoperation standard parity, the key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this section are to be interpreted as described in RFC 2119\.

## 3.1 Possible Value Types / Primitives

To maintain structural clarity and interoperation standard parity, the key words "MUST" and "MUST NOT" in this section are to be interpreted as described in RFC 2119\.

Within the structural boundaries of the Manifest Chain validation block (such as the `$manifest-chain-link`), parsers MUST natively recognize and support the following core scalar primitives:

### 3.1.1 String 

A String represents a sequence of zero or more Unicode characters. All strings MUST be valid UTF-8 character encodings. Within the `$manifest-chain-link`, strings are the primary data type used for all cryptographic hashes (e.g., `data_hash`, `meta_hash`), cryptographic keys/signatures (`git_signature`), and structural identifiers (`version`, `hashing_strategy`).

### 3.1.2 Integer 

An Integer represents arbitrary sized finite mathematical integers. Integers are strictly whole numbers; they MUST NOT contain fractional parts or decimal points. Within the Manifest Chain, integers are explicitly required for the `block_index` to maintain mathematical chronological sequencing.

### 3.1.3 Offset Date-Time (RFC 3339 String) 

While technically evaluated as a string by standard JSON or YAML processors, the Manifest Chain elevates the timestamp into a strictly evaluated primitive. To unambiguously represent a specific instant in time, any time value (such as the `timestamp` key) MUST strictly conform to the `date-time` format specified in RFC 3339\. Fractional seconds (millisecond precision) are permitted, but if the value contains greater precision than the parsing implementation can support, the additional precision MUST be truncated, not rounded.

### 3.1.4 Boolean 

A Boolean represents a `true` or `false` logic value. The values MUST always be lowercase.

### 3.1.5 Null 

A Null represents the intentional lack of a value. Parsers MUST distinguish between a mathematically `null` value and an empty string (`""`); they are evaluated differently during the hash serialization phase.

## 3.2 Collections, Arrays, and Objects

While the Manifest Chain is designed to encapsulate format-agnostic data payloads, the structural boundaries of the manifest chain—namely the `$manifest-chain-link` validation block and any detached external manifests—rely on standardized collection types to organize data.

To ensure deterministic hashing across discrete CI/CD/CA/CA systems, parsers MUST evaluate collections according to the following strict constraints:

### 3.2.1 Mappings (Objects / Dictionaries) 

A Mapping represents a collection of key-value pairs.

* Key Constraints: All keys within a mapping MUST be strictly evaluated as Strings.  
* Uniqueness: A mapping's keys MUST be unique; no two keys within the same mapping can be equal to each other. Parsing engines MUST NOT instantiate an error-free representation if duplicate keys are detected, as ambiguity in key resolution is a critical vector for supply chain tampering.  
* Ordering: In the abstract representation model, mapping keys do not have an inherent mathematical order. While the Raw Byte Parser will naturally capture the literal written order of the bytes, Semantic AST Parsers MUST evaluate mapping equivalence without relying on key order.

### 3.2.2 Sequences (Arrays / Lists) 

A Sequence represents an ordered collection of zero or more values.

* Data Types: Sequences MAY contain values of mixed data types, including other collections or primitive scalars.  
* Order Significance: Unlike mappings, the order of elements within a sequence is strictly mathematically significant. Any change to the sequential order of elements within a `$manifest-chain-link` or a detached anchored manifest MUST fundamentally alter the resulting cryptographic hash, breaking the verification of the manifest chain.

## 3.3 Content Block Schemas and Examples

A **Content Block** represents the raw or semantic changes made to a tracked manifest file (such as a dependency lockfile). It MUST be structured according to one of the two defined strategies: **Semantic Diff** or **Line-Based Diff**.

### 3.3.1 Semantic Diff Strategy Example

This strategy captures precise, structured changes to package dependencies. It is highly readable by automated systems and AI agents.

```yaml
# Document 1: Content Block (Semantic Diff Payload)
subject: package-lock.json
diff_strategy: semantic
event: update
changes:
  upgraded:
    - name: lodash
      from: 4.17.21
      to: 4.17.22
  added:
    - name: ms
      version: 2.1.3
  removed: []

```
### 3.3.2 Line-Based Diff Strategy Example

This strategy records raw line-level changes, matching the classic unified patch layout seen in version control tools. It MUST use a **YAML Literal Block Scalar (`|`)** to guarantee the preservation of line endings and whitespace for exact cryptographic hashing.

```yaml
# Document 1: Content Block (Line-Based Diff Payload)
subject: package-lock.json
diff_strategy: line
patch: |
  --- package-lock.json
  +++ package-lock.json
  @@ -4,4 +4,4 @@
   "dependencies": {
  -  "lodash": "4.17.21"
  +  "lodash": "4.17.22"
   }

```
## 3.4 Validation Block Schema and Example

Every Content Block appended to the stream MUST be immediately followed by a **Validation Block** (using the `$manifest-chain-link` key). This document permanently seals the state transition, linking the mathematical hash of the preceding payload to the metadata of the preceding link to guarantee chronological sequence integrity.

### 3.4.1 JSON Schema Definition (Normative)

The schema defines the strict type requirements for each primitive value in the `$manifest-chain-link`:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "Continuous Attestation Validation Block Schema",
  "type": "object",
  "required": [
    "$manifest-chain-link"
  ],
  "properties": {
    "$manifest-chain-link": {
      "type": "object",
      "required": [
        "version",
        "block_index",
        "timestamp",
        "hashing_strategy",
        "data_hash",
        "prev_meta_hash",
        "meta_hash"
      ],
      "properties": {
        "version": {
          "type": "string",
          "pattern": "^+\\.+\\.+$"
        },
        "block_index": {
          "type": "integer",
          "minimum": 0
        },
        "timestamp": {
          "type": "string",
          "format": "date-time"
        },
        "hashing_strategy": {
          "type": "string",
          "enum": ["raw", "semantic"]
        },
        "data_hash": {
          "type": "string",
          "pattern": "^[a-f0-9]{64}$"
        },
        "prev_meta_hash": {
          "type": "string",
          "pattern": "^[a-f0-9]{64}$"
        },
        "meta_hash": {
          "type": "string",
          "pattern": "^[a-f0-9]{64}$"
        },
        "signature_auth": {
          "type": "object",
          "required": [
            "provider",
            "signer_identity",
            "git_signature"
          ],
          "properties": {
            "provider": {
              "type": "string"
            },
            "signer_identity": {
              "type": "string",
              "format": "email"
            },
            "git_signature": {
              "type": "string"
            }
          }
        }
      }
    }
  }
}

```
### 3.4.2 Complete Transaction Log Example (Multi-Document YAML)

Here is a complete, compliant YAML stream displaying a single transaction (Content Block followed by its Validation Block):

```yaml
subject: package-lock.json
diff_strategy: semantic
event: update
changes:
  upgraded:
    - name: lodash
      from: 4.17.21
      to: 4.17.22
---
$manifest-chain-link:
  version: "1.0.0"
  block_index: 12
  timestamp: "2026-06-26T19:55:24.000Z"
  hashing_strategy: raw
  data_hash: "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
  prev_meta_hash: "8c7dd922ad47494fc02c38863c18dc4074a91e5c1fa7425e73043362938b9824"
  meta_hash: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  signature_auth:
    provider: "github-ssh"
    signer_identity: "dev@enterprise.corp"
    git_signature: |
      -----BEGIN SSH SIGNATURE-----
      U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAg9Sbb88Fz/w0FvD8N4P6U7XmH9W
      ...
      -----END SSH SIGNATURE-----

```
### 3.4.3 Required Protocol Context Fields

* `version`: (String) MUST specify the protocol version of the chain schema (e.g., `"1.0.0"`) to ensure forward compatibility for parsers.  
* `block_index`: (Integer) MUST represent the absolute chronological sequence number of the current transaction. The index MUST begin at `0` for the origin block and increment by exactly `1` for each subsequent block.  
* `timestamp`: (String) The date and time when the link was generated. To guarantee correct time zone offset processing across discrete CI/CD/CA systems, the value MUST strictly conform to the `date-time` format as specified in RFC 3339\.

### 3.4.4 Cryptographic Links and Hashing 

The chain relies on strict mathematical linking. The hashing algorithm utilized MUST be a secure hash algorithm, such as SHA-256, as specified in NIST FIPS 180-4.

* `hashing_strategy`: (String) MUST declare the strategy used to serialize the payload (e.g., `"raw"`).  
* `data_hash`: (String) MUST contain the calculated hash digest of the strictly preceding data payload document.  
* `prev_meta_hash`: (String) REQUIRED for all blocks. MUST contain the exact `meta_hash` of the immediately preceding `$manifest-chain-link` validation block to enforce sequence integrity. For the origin block (`block_index: 0`), this MUST be represented as a 64-character zeroed-out string.  
* `meta_hash`: (String) MUST contain the calculated hash digest of the current `$manifest-chain-link` object itself.

### 3.4.5 Identity and Non-Repudiation (`signature_auth`) 

To satisfy continuous zero-trust attestation, the `$manifest-chain-link` MAY include a `signature_auth` block to establish exactly who authorized the modification. If present, it MUST include:

* `provider`: (String) Identifies the mechanism or toolset used for the signature (e.g., `"github-ssh"`, `"gpg"`).  
* `signer_identity`: (String) The email address, handle, or URI identifying the actor.  
* `git_signature`: (String) The raw cryptographic signature string. To ensure interoperable parsing, the signature MUST be represented in either the OpenPGP Message Format per RFC 4880 (RFC 9580\) or the OpenSSH `PROTOCOL.sshsig` (OpenSSH Signature Format) (RFC 4716).

# 4\. Processing and Implementation

To maintain structural clarity and interoperation standard parity, the key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this section are to be interpreted as described in RFC 2119\.

## 4.1 Parsers and Generators

Because a Continuous Attestation environment bridges the gap between high-velocity development workflows and strict regulatory audits, the Manifest Chain specification deliberately supports different levels of parsing strictness. Implementations MUST adhere to the behavioral instructions defined within the `$manifest-chain-link` trailer to accurately evaluate the format-agnostic Data Payload.

### 4.1.0 Parsing subjects

File content awareness: a compliant parsing engine MUST analyze dependency version constraints  
Warning rules: It MUST define the precise conditions that trigger a warning  
. For example, if a version constraint uses an unbounded operator (like \>= or \>), the parser MUST instantiate a policy warning state (formally defined as the "Open Fuse" state)  
Verification Rules: It SHOULD specify how client tools recursively evaluate dependency trees and report these warnings during a build.

### 4.1.1 Parsing and Evaluation Engines 

Implementations of the Manifest Chain SHOULD define their parsing engine's behavior according to one or both of the following two methods:

* **Raw Text Parser (e.g., `node-parser`, `bash-parser`):** A parser designed for strict regulatory compliance audits. It MUST evaluate the payload strictly as a raw byte stream. In this mode, not even a cosmetic formatting adjustment or an extra space can go unflagged without breaking the cryptographic hash sequence.  
* **Semantic AST Parser (e.g., `yaml-parser`, `ys-parser`):** A parser preferred for development environments. It calculates hashes based on the parsed Abstract Syntax Tree (AST), tolerating cosmetic modifications (such as developer spacing updates or benign comments) while strictly verifying the semantic core of the supply chain manifests.

TODO: New section about evaluating the content at hash time

Every `$manifest-chain-link` trailer MUST provide explicit instructions on how the parsing engine evaluates the preceding payload block.

* **`hashing_strategy`**: (String) Declares how the parser MUST serialize the payload bytes prior to executing the hash function. For example, a value of `raw` dictates that the exact byte stream MUST be used without normalization.

### 4.1.2 Generating Content Evaluation Strategies 

Describe this section about how to generate a presentation in semantic or line strategy. format?

* **`diff_strategy`**: (String) Instructs the parser on how the payload modifies the target manifest file. The specification supports two primary values:  
  * `semantic`: Indicates that the payload block contains structural object resolution data (e.g., explicit `old` and `new` keys mapping to specific dependency versions or exact line location markers like `loc: 15,10`).  
  * `line`: Indicates that the payload block contains line-based string modifications (e.g., `-eslint: "8.0.0"`, `+eslint: "8.50.0"`).

### 4.1.3 Generating Foreign Format Embedding and Literal Scalars 

To maintain strict structural compliance with the YAML 1.2.2 specification, the Manifest Chain file MUST remain a well-formed YAML document at all times, regardless of the underlying `diff_strategy` or the target manifest's native format.

* When a generator utilizes `diff_strategy: line` to append or evaluate foreign file formats (such as JSON, XML, or TOML), or when it encapsulates a complete multi-line unified diff, the generator MUST encapsulate the payload within a **Literal Block Scalar** (denoted by the `|` indicator).  
* Because literal scalars do not evaluate escape characters or structural indicators from other languages, parsers MUST extract the exact character string from the literal block without attempting to resolve internal foreign syntax as YAML mappings or sequences.

## 4.2 The Bundled OCI Artifact (OCI Integration)

To maintain structural clarity and interoperation standard parity, the key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this section are to be interpreted as described in RFC 2119\.

While the Manifest Chain provides internal chronological integrity, absolute supply chain security requires binding the manifest chain directly to the compiled software it describes. To accomplish this, implementations SHOULD package the Manifest Chain alongside its target binaries inside an Open Container Initiative (OCI) image format. This creates a "Bundled OCI Artifact."

### 4.2.1 OCI Artifact Binding 

The OCI Image Format Specification defines a standard for packaging executable software and its dependencies. When utilizing the Bundled OCI Artifact architecture:

* The Manifest Chain file (e.g., `manifest_chain.yaml`) MUST be included as a distinct layer or blob within the OCI Image Manifest.

When not using the Bundled OCI Artifact architecture:

* By leveraging the ORAS (OCI Registry As Storage) Artifact Manifest Spec, the Manifest Chain MAY be defined as an independent artifact that explicitly references the target software image via the `subject` property. This enables a graph of independently linked artifacts, allowing registries to establish a cryptographic relationship between the binary and the manifest chain. In other words the Manifest Chain is stored in the registry and points to the binary.

### 4.2.2 Lifecycle and Registry Verification 

When pushed to an OCI-compliant or ORAS-compliant distribution registry, the registry MAY treat the lifecycle of the Manifest Chain as being tied to its `subject` binary.

* If the target binary is deleted or marked for garbage collection, the associated Manifest Chain SHOULD be subject to deletion as well.  
* Continuous Integration (CI) and Continuous Deployment (CD) pipelines MUST verify the `meta_hash` of the final `$manifest-chain-link` in the attached manifest chain before granting authorization to execute or unpack the associated OCI binary.

## 4.3 Error Handling and Failure States

To maintain structural clarity and interoperation standard parity, the key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this section are to be interpreted as described in RFC 2119\.

Implementations processing a Manifest Chain MUST implement strict error handling to guarantee supply chain integrity. Parsers MUST NOT attempt to guess, infer, or automatically correct invalid manifest chain states. When a parser encounters a violation of this specification, it MUST immediately halt evaluation and instantiate a critical error condition.

TODO: Add section for max file size

When pushing manifests, many clients and registries have size limits to prevent various resource exhaustion attacks. The distribution specification now clarifies that a registry seeing its limit exceeded SHOULD return a 413 (payload too large) response to clients. And the specification also recommends that registries SHOULD support up to a 4MiB image manifest (containing JSON descriptors, not the image layer content). For portability, clients SHOULD avoid exceeding this limit by limiting the usage of the data field and annotations.

### 4.3.1 Cryptographic Failure States 

A parser MUST instantiate an error and halt execution if any of the following cryptographic conditions occur:

* **Data Hash Mismatch:** The calculated hash digest of the Data Payload does not exactly match the `data_hash` declared in the appended `$manifest-chain-link`.  
* **Trailer Hash Mismatch:** The calculated hash digest of the `$manifest-chain-link` does not exactly match its own internal `meta_hash` value.  
* **Signature Verification Failure:** If a `signature_auth` block is present and the parser is configured to evaluate it, the parser MUST instantiate an error if the `git_signature` cannot be cryptographically verified against the declared `signer_identity`.

### 4.3.2 Sequence and Chronology Failure States 

Because the Manifest Chain relies on mathematical chronological linking, a parser MUST instantiate an error if:

* **Broken Index:** The `block_index` does not increment by exactly `1` from the preceding block.  
* **Broken Trailer:** The `prev_meta_hash` does not exactly match the `meta_hash` of the immediately preceding transaction.

### 4.3.3 Structural and Formatting Errors 

Following the loading failure principles of the YAML 1.2.2 specification, a parser MUST reject ill-formed streams. A parser MUST instantiate an error if:

* Any REQUIRED fields within the `$manifest-chain-link` (such as `version`, `timestamp`, or `hashing_strategy`) are missing or strictly fail to conform to their defined primitives.  
* Duplicate keys are detected within a single mapping object, as ambiguity in key resolution is a critical vector for supply chain tampering.

## 4.4 Verification Summary Attestations (VSA)

As software supply chains scale, applications frequently rely on hundreds or thousands of dependencies. Requiring a localized parsing engine to recursively download and sequentially evaluate the full Manifest Chain, detached anchors, and build provenance for every single dependency introduces unacceptable latency into high-velocity CI/CD/CA pipelines and developer installations.

To resolve this performance bottleneck without sacrificing zero-trust mathematical guarantees, implementations of this specification SHOULD support the generation and ingestion of **Verification Summary Attestations (VSA)**.

### 4.4.1 Definition and Purpose

A Verification Summary Attestation (VSA) is an authenticated statement indicating that a trusted entity (the verifier) has evaluated one or more software artifacts and a bundle of attestations against a specific security policy.

By issuing a VSA, the verifier communicates the verified compliance level (such as an achieved SLSA level) to downstream consumers. This allows software consumers to delegate complex, recursive policy decisions to a trusted party—such as a Sovereign Registry or a central Enterprise CI/CD/CA gate—and simply trust that party's decision regarding the artifact without needing to independently evaluate the entire historical manifest chain of attestations.

### 4.4.2 Integration with the Manifest Chain

When a VSA is utilized in conjunction with the Continuous Attestation software engineering practice, the Manifest Chain and the VSA MUST interact through the following architectural model:

* **Ingestion and Chain Traversal:** The trusted verifier (e.g., the Packablock Registry) MUST ingest the full Manifest Chain (`manifest_chain.yaml`) and its associated Detached Anchored Manifest (`chain_sig.yaml`). The verifier performs the heavy computational audit, walking the manifest chain backward to verify every `data_hash` and `prev_meta_hash` link, ensuring absolute sequence integrity and preventing open ended manifest chain replay attacks.  
* **VSA Issuance:** Upon successful validation of the chronological chain and any accompanying build provenance, the verifier issues a single, lightweight VSA.  
* **Binding the Chain as Input:** When generating the VSA, the verifier MUST explicitly reference the evaluated Manifest Chain within the VSA's `inputAttestations` field. This explicitly declares that the Continuous Attestation manifest chain was the primary evidence used to satisfy the verification policy.  
* **Downstream Consumer Verification:** During a local package installation (e.g., an `npm install` wrapped by the CLI tool), the consumer's client bypasses downloading the thousands of historical chain blocks. Instead, the client MUST perform a lightweight verification of the VSA by:  
  1. Verifying the cryptographic signature on the VSA envelope using preconfigured roots of trust.  
  2. Confirming the VSA's `subject` matches the exact digest of the downloaded binary or package.  
  3. Ensuring the `verificationResult` field strictly evaluates to `PASSED`.  
  4. Confirming that the `verifiedLevels` field meets the organization's required baseline (e.g., `SLSA_BUILD_LEVEL_3`).

By utilizing this VSA architecture, the specification guarantees that the unbroken, Git-like chronological history of the Manifest Chain is rigorously audited, while abstracting that complexity into a single, highly performant cryptographic payload for the end consumer.

## 4.5 Agentic Evaluation and Deterministic Tooling

To maintain structural clarity and interoperation standard parity, the key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this section are to be interpreted as described in RFC 2119\.

The Continuous Attestation software engineering practice transforms static configuration files into an active, Agentic ecosystem. However, while Large Language Models (LLMs) excel at synthesizing incident reports and guiding remediation strategies, they are fundamentally probabilistic engines. Asking an LLM to "read" a massive codebase or evaluate a set of production release artifacts to definitively locate a specific, CVE-impacted dependency version is an invitation for confident hallucinations.

### 4.5.1 The Limitations of Probabilistic Auditing

LLMs natively lack the deterministic capacity to parse thousands of unindexed files, accurately reconstruct chronological file states, or perform exact byte-for-byte sequence matching across multi-tenant environments. If an automated security agent attempts to ascertain the compliance state of a release by relying on probabilistic text generation or naked source code extraction, the resulting output is non-deterministic and entirely unsuitable for regulatory auditing.

### 4.5.2 Mandatory Tooling for Agentic Workflows

To ensure reliability and mathematical truth during incident response or version auditing, automated agents and LLMs MUST NOT independently guess or probabilistically evaluate the state of dependencies. Instead, the Agentic workflow MUST interact with the Continuous Attestation software engineering practice through deterministic search and comparison tools.

When an LLM is tasked with auditing a codebase or production artifact, the system SHALL adhere to the following architecture:

* **Tool Invocation:** The LLM MUST be equipped with and explicitly invoke deterministic parsing tools (such as the `pkablk` CLI client or a native semantic YAML parser) to perform the actual extraction and cryptographic verification of the manifest chain.  
* **Targeting the Bundled OCI Artifact:** Rather than scanning arbitrary source files, the deterministic tool MUST target the Bundled OCI Artifact—the synchronized, content-addressable unit containing the compiled binary and the active Manifest Chain (`manifest_chain.yaml`).  
* **Evaluating the dependency change history:** The tool MUST strictly sequentially process the dependency change history, executing exact string comparisons on the data payload and calculating the corresponding `meta_hash` sequence to prove exactly when a specific version was introduced or remediated.  
* **Agentic Synthesis:** Once the deterministic tool has completed its evaluation, it returns the mathematically verified output (e.g., "Tenant B is running version 4.17.21, cryptographically signed by Alice on 2026-06-13T16:21:00.000Z") back to the LLM. The LLM then synthesizes these hard, deterministic facts into the final compliance or incident response report.

By enforcing this strict boundary between the LLM's probabilistic reasoning and the CLI tool's deterministic execution, organizations can deploy autonomous security agents that operate with the absolute precision required by enterprise compliance frameworks.

## 4.6 Semantic Versioning Constraints and Degradation Warnings

To maintain structural clarity and interoperation standard parity, the key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this section are to be interpreted as described in RFC 2119\.

The Continuous Attestation software engineering practice relies on mathematically verifiable chronological states. Example: in commit A lodash version was 8.0.0; in commit B lodash version was 8.1.0. However, modern dependency management frequently utilizes Semantic Versioning (SemVer) ranges (e.g., `^4.21.0`, `~2.0.0`) or unbounded descriptors (e.g., `>=1.0.0`) to resolve packages at build time. Unbounded or excessively loose version constraints introduce severe non-determinism into the build process, exposing the supply chain to split-timeline regressions and making point-in-time auditing highly unpredictable. At build time, unbounded version criteria provides few guard rails to drift.

To mitigate the risk of unbounded dependencies without abruptly halting development workflows, parsing engines and CI/CD/CA wrappers MUST implement graceful degradation warnings when evaluating the dependency change history:

* **Unbounded Version Detection:** When a validation engine evaluates a `$manifest-chain-link` block or generates a point-in-time SBOM, it MUST analyze the version constraints of all resolved dependencies. However, in raw line-based diff strategy the validation engine may only resolve differences in the version criteria string.  
* **The Open Fuse/Version Promiscuity Warning State:** If the parser detects an unbounded version descriptor (such as `>=` or `>`), it MUST flag the dependency with a warning state (e.g., a "Yellow" or "Open Fuse" alert). This explicitly warns the organization that the dependency lacks a strict version capping and is vulnerable to upstream tampering or split-timeline regressions.  
* **Auditing and Telemetry:** Implementations SHOULD log these warnings to centralized telemetry or incident response dashboards to give responders actionable visibility into dependency drift. Reports could go to console logs or registry.  
* **Resolution and Pinning:** To resolve the warning state and return the dependency to a fully secure ("Green") status, developers MUST replace the unbounded descriptor with a pinned version or a strictly bounded SemVer ceiling in a subsequent manifest commit, which is then cryptographically sealed into the next block of the manifest chain.

By enforcing these constraint warnings, the architecture proactively identifies non-deterministic supply chain vulnerabilities before they result in compromised production deployments, guiding developers toward strict dependency pinning.

# 5\. Extensibility and Security

To maintain structural clarity and interoperation standard parity, the key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this section are to be interpreted as described in RFC 2119\.

## 5.1 Extensibility and Custom Properties

The Manifest Chain is designed to be highly automated and adaptable to specialized enterprise use cases without sacrificing parser interoperability.

### 5.1.1 The Properties Array 

Following the design philosophy of the CycloneDX standard, the `$manifest-chain-link` MAY include a `properties` array to act as a name-value store. This provides the flexibility to include custom metadata (such as internal organizational tracking IDs, environment flags, or telemetry) without having to use additional namespaces or create custom schema extensions that might cause a strict Raw Byte Parser to fail.

### 5.1.2 Extension Evaluation Rules 

If an implementation chooses to support custom extension fields within the `$manifest-chain-link`, it MUST adhere to the following strict evaluation constraints adapted from the SLSA specification:

* Immutability of Meaning: Extension fields MUST NOT alter the meaning of any other required cryptographic field. An invalid or tampered `meta_hash` MUST immediately trigger a critical failure state, regardless of any custom extensions present.  
* The Monotonic Principle: Extensions SHOULD follow the monotonic principle, meaning that a parser deleting or ignoring an unrecognized extension field MUST NOT turn a DENY security decision into an ALLOW decision.

## 5.2 Security Considerations and Threat Model

The Manifest Chain serves as a zero-trust cryptographic manifest chain. Implementations MUST evaluate the following supply chain threats and ensure their parsing engines are configured to mitigate them.

### 5.2.1 Provenance and Hash Forgery 

An adversary might attempt to generate a bogus manifest payload and forge the resulting hashes to mask a malicious software injection. Because the `$manifest-chain-link` relies on chronological mathematical linking, a forged `data_hash` will inevitably break the calculation of the concluding `meta_hash`. The optional but recommended requirement to sign the trailer via the `signature_auth` block further mitigates this threat, ensuring that a forged hash sequence cannot be authenticated by a legitimate actor.

### 5.2.2 Split-Timeline and Rollback Attacks 

An attacker might attempt a rollback attack by providing a mathematically valid but historically outdated Manifest Chain file, attempting to silently revert the environment to a known vulnerable dependency state. By strictly enforcing the sequentially incrementing `block_index` and continuous `prev_meta_hash` anchors, parsing engines are mathematically guaranteed to detect if a manifest chain has been branched, rolled back, or truncated.

### 5.2.3 Cryptographic Key Compromise 

The non-repudiation of the chain relies heavily on the security of the keys used to generate the `signature_auth` block. Cryptographic keys MUST contain sufficient entropy and be stored in a secure environment. If a developer's signing key is compromised, the sequential nature of the dependency change history allows enterprise security teams to identify the exact `block_index` where the compromised key was first introduced. This allows them to instantly isolate the blast radius and cryptographically deprecate all subsequent blocks.

### 5.2.4 Archived Chain Replay and Open Ended manifest chains 

An adversary might attempt to resurrect a historically archived Manifest Chain following a successful rollover event. In this scenario, the attacker takes the archived chain and initializes (`event: init`) a counterfeit version of a manifest that was previously tracked, introducing substantial regressions or malicious alterations into the compromised version. Because the archived chain was mathematically valid up to the point of its rollover, an isolated, purely offline parser might be tricked into accepting the open-ended chain's newly appended blocks as a legitimate continuation.

To mitigate this threat, implementations MUST enforce strict rollover boundary verification and adhere to the **Anchor Singularity** principle:

* **Rollover Cryptographic Binding:** A successful rollover event MUST strictly rotate client keys and securely chain old metadata hashes across the rollover boundary. The new active Manifest Chain MUST cryptographically bind back to the last `meta_hash` of the archived chain to prove chronological continuity.  
* **The Anchor Singularity Rule:** A Manifest Chain MUST possess only a single, absolute anchor point representing its latest verified terminal state (the most recent `meta_hash`). While this single anchor point MAY be broadcast to multiple external targets simultaneously, the architecture MUST strictly enforce its singularity:  
  * **Single Detached Manifest:** If utilizing a file-based anchor within a repository, implementations MUST allow only a single Detached Anchored Manifest file (e.g., `chain_sig.yaml`). Parsers MUST instantiate a critical error if multiple detached anchor files are detected for the same chain.  
  * **Semantic Log Push:** The anchor point MAY be transmitted to a sovereign cryptographic registry (such as the Packablock Registry) to record the timeline state.  
  * **Transparency Log Anchoring:** The anchor point MAY be published to a third-party transparency log (e.g., Sigstore Rekor). Implementations MAY submit the final signature envelope to the Rekor API using a supported pluggable type schema, such as a `hashedrekord` or a `dsse` envelope. Furthermore, implementations SHOULD leverage tools like the GitHub Artifact Attestations API (`actions/attest@v4`) to automatically freeze the chronological timeline.  
* **Most Recent Point Resolution:** If a parser, CI/CD/CA pipeline, or registry queries multiple anchoring targets (e.g., evaluating both the local `chain_sig.yaml` and a Sigstore Rekor inclusion proof), it MUST only recognize the absolute most recent mathematically valid `meta_hash` across all queried targets as the true anchor point. All older states MUST be considered superseded.  
* **Terminal Rejection:** Parsers and registries MUST strictly track the active status of the chain against this single anchor point. If a verifier observes a transaction appended to a Manifest Chain whose terminal `meta_hash` has already been superseded by the recognized anchor point, it MUST instantly instantiate a critical error and halt execution, permanently rejecting the open ended manifest chain.

### 5.2.5 CI/CD/CA Pipeline Bypass and Tampering

To maintain structural clarity and interoperation standard parity, the key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this section are to be interpreted as described in RFC 2119\.

An adversary, or a developer attempting to expedite a release, might attempt to bypass the Continuous Attestation verification or append steps. This can occur by modifying the CI/CD/CA workflow definitions in a pull request, deleting the verification steps, or exploiting the runner environment to spoof a successful manifest chain append before compilation.

To guarantee that the manifest chain checks and appends succeed before any code compiles, the architecture MUST separate the security enforcement mechanism from the developer's local workspace and user-defined build steps. Implementations mitigating this threat MUST adhere to the following architectural constraints:

* **Base-Branch Workflow Execution:** To prevent a malicious pull request from deleting the security enforcement steps, platforms MUST execute the validation workflows from the base target branch (e.g., `main`), strictly ignoring any workflow modifications introduced in the incoming untrusted branch.  
* **Package Manager Interception (Wrappers):** Implementations SHOULD utilize a localized wrapper (such as the `pkablk` CLI) to intercept standard package manager installations (e.g., `npm install`). The wrapper MUST recursively evaluate the dependencies. If a dependency explicitly fails a cryptographic check (such as a broken sequence or an invalid signature), the wrapper MUST immediately exit with a non-zero status code, halting the CI/CD/CA pipeline instantly and preventing the build runner from reaching the compilation stage.  
* **Hardened Execution Environments:** To prevent user-defined build steps from attempting to overwrite the local `manifest_chain.yaml` history or fake the data hash, the pipeline MUST run the verification wrapper inside a hardened, isolated container. Following SLSA Build Level 3 requirements, the build platform **MUST prevent secret material used to sign the provenance from being accessible to the user-defined build steps**.  
* **Ephemeral Identity and Shadow manifest chains:** The runner SHOULD NOT utilize long-lived cryptographic keys stored as repository secrets. Instead, the runner MUST request a short-lived OpenID Connect (OIDC) token to authenticate the block append, streaming the new state directly to a transparency log or Sovereign Registry. To absolutely physically separate the manifest chain from developer control, implementations MAY employ a "Shadow manifest chain" pattern, performing a dual-checkout where the `manifest_chain.yaml` resides on a strictly protected branch isolated from the `main` source code.

By enforcing these boundaries, malicious actors are physically incapable of skipping the verification, forging the `data_hash`, or modifying the chain's chronological history, ensuring a zero-trust continuous attestation pipeline.

## 5.3 Autonomous Agent Risk Mitigation and Deterministic Gating

To maintain structural clarity and interoperation standard parity, the key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this section are to be interpreted as described in RFC 2119\.

As enterprise leadership increasingly mandates the integration of proprietary AI coding assistants and autonomous agents, engineering teams are subjected to a high-velocity execution risk. Autonomous agents can update dependencies, refactor infrastructure-as-code, and open Pull Requests at a scale that easily outpaces the capacity of human auditors.

When faced with massive, sweeping configuration changes or 10,000-line diffs generated by an AI, human reviewers experience severe signal-to-noise degradation. This creates a critical lack of assurance regarding exactly *what* the agent just did and whether it quietly introduced an exploit through an indirect dependency version change. Furthermore, attempting to solve this visibility gap by deploying an AI-based scanning tool to monitor an AI coding agent creates an expensive, non-deterministic loop of "AI grading AI".

To contain the risk of autonomous configuration drift, implementations of the Continuous Attestation framework MUST establish a deterministic cryptographic circuit breaker. This approach requires zero additional generative AI processing overhead to catch agent hallucinations or mistakes:

* **Granular Delta Logging over AI Drift:** By leveraging the Semantic or Line-Based Diff Chain architecture, every modification to a tracked file appended by an AI agent MUST be captured in a content block. In parallel with the Git change history for the whole repo and the point in time SBOM, the Manifest Chain stores what was changed, when, and by whom in a format designed to be readable by AI tools. The CLI can instantly report on a query with no Git logs and without pulling historical SBOM files. An AI agent can use the deterministic retrieval report to generate a concise answer (e.g., *Block 43: Agent-XYZ updated package 'X' from version 1.2.0 to 1.3.1-beta*).  
* **Cryptographic Non-Repudiation for Agents ("Who Authorized This?"):** To prevent well-meaning or hallucinating agents from force-pushing unverified dependencies, AI tools operating within a workflow MUST either act via a specific Machine Identity (leveraging ephemeral OIDC tokens) or operate strictly in a "Draft State".  
* **The Draft State Constraint:** When operating in a Draft State, the agent inherently lacks cryptographic authorization. The system MUST require a human developer or other approved AI agent to review the granular delta block and manually seal the `$manifest-chain-link` block using an authorized local signature. Even using another AI in this stage is safer because they can focus on a much smaller data set and use deterministic tools.  
* **Automated Rejection:** If an agent attempts to bypass human review or inject an unbounded version descriptor, the verification process ( `pkablk` `verify` ) MUST instantly reject the commit or package because it lacks the permission to sign the change, halting the deployment. This satisfies the requirement of deterministic risk identification and automated gating.

By replacing probabilistic AI scanning with a deterministic cryptographic consistent gate, organizations can safely leverage autonomous engineering velocity while maintaining a mathematically defensive timeline that allows for immediate, automated rollbacks when an agent introduces a vulnerable component.

## 5.4 IANA Considerations

To maintain structural clarity and interoperation standard parity, the key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this section are to be interpreted as described in RFC 2119\.

### 5.4.1 Media Type Registration 

To ensure that HTTP transport layers, distribution platforms, and continuous integration engines can unambiguously identify a Manifest Chain file, implementations SHOULD utilize a registered IANA Media Type.

* **Type name:** `application`  
* **Subtype name:** `vnd.packablock.manifest-chain+yaml` (or `+json`, depending on the serialization format of the manifest chain).  
* **Required parameters:** None.  
* **Encoding considerations:** 8bit (UTF-8 strictly required for all string primitives).

### 5.4.2 ORAS Artifact Type Registration 

When utilizing the Bundled OCI Artifact architecture (Section 4.2) to bind the Manifest Chain to an OCI image via the ORAS Artifact Manifest, the file MUST be differentiated using a registered `artifactType`.

* The `artifactType` MUST be a unique value registered with IANA to avoid conflicts with other supply chain artifacts (such as standard SBOMs or Notary signatures).  
* **Recommended Value:** `application/vnd.packablock.manifest-chain.v1`

# 6\. Appendices

* **Appendix A:** Full-Length Examples / Example Files  
* **Appendix B:** Historically Reserved or Deprecated Items  
* **Appendix C:** References (Normative and Informative)  
* **Appendix D:** Changes to this Specification  
* **Appendix E:** Offline Verification and Constant-Memory Traversal Mechanism (Normative)  
* **Appendix F:** User Interface and CLI Visualization Guidelines (Informative)

( This page intentionally left blank. )

[use-case-1-no-attestation]: {{ site.baseurl }}/assets/images/use-case-1-no-attestation.png

[use-case-2-validate-ca-artifacts]: {{ site.baseurl }}/assets/images/use-case-2-validate-ca-artifacts.png

[use-case-3-package-manager-verification]: {{ site.baseurl }}/assets/images/use-case-3-package-manager-verification.png

[use-case-4-builder-pipeline]: {{ site.baseurl }}/assets/images/use-case-4-builder-pipeline.png

[use-case-5-cve-impact-audit]: {{ site.baseurl }}/assets/images/use-case-5-cve-impact-audit.png

[use-case-6-build-sentinel]: {{ site.baseurl }}/assets/images/use-case-6-build-sentinel.png

[use-case-7-ai-pr-hallucination]: {{ site.baseurl }}/assets/images/use-case-7-ai-pr-hallucination.png