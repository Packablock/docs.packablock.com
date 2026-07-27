---
layout: page
title: About Continuous Attestation
permalink: /about/
---

# About Continuous Attestation

Continuous Attestation (CA) is a software engineering practice that extends standard Software Bill of Materials (SBOM) generation into a live, cryptographically linked timeline log.

Traditional SBOMs are static, point-in-time documents. They represent a snapshot of what dependencies are supposedly active, but they lack chronological context, sequence verification, and tamper-evident signatures.

Continuous Attestation addresses these limitations by tracking software dependencies as an unbroken, append-only manifest chain.

---

## The Core Philosophy

| Principle | Traditional Security (Awareness) | Continuous Attestation (Prevention) |
| :--- | :--- | :--- |
| **Verification Posture** | Passive scanner alerts after dependency ingestion. | Active challenge loop blocks build on unverified changes. |
| **Chronological Audit** | Point-in-Time snapshot (speculative, lacks context). | Immutable block-by-block lineage (tamper-evident). |
| **Trust Model** | Trust the registry or control plane implicitly. | Zero-trust validation (mathematically check hashes locally). |

---

## Alignment with Industry Standards

Packablock’s Continuous Attestation model aligns directly with standard security frameworks:

* **SLSA (Supply Chain Levels for Software Artifacts)**: Satisfies the requirements for Build Track Level 2 and Level 3 by validating build provenance and verifying that the chronological sequence of dependencies remains untampered.
* **Sigstore Rekor**: Integrates with transparency log architectures by publishing terminal manifest signatures as anchored validation points, preventing history-rewrite attacks.
* **Open Policy Agent (OPA)**: Integrates with policy evaluation engines to dynamically enforce organization-level compliance rules at the CI/CD gate.

---

### Project Maintainer & Vision

Continuous Attestation and the Packablock project are maintained by **Aaron Bronow**. 

* **GitHub**: [github.com/aaronbronow](https://github.com/aaronbronow)
* **LinkedIn**: [linkedin.com/in/aaronbronow](https://www.linkedin.com/in/aaronbronow)
