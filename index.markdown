---
layout: page
title: Documentation
permalink: /
---

# Packablock Documentation

Welcome to the official documentation site for the Packablock Supply Chain Trust Registry. 

We are currently setting up our documentation. The complete user guides, API references, and deployment manuals will be available here soon.

Please check back later!

## Example Client Integration

Here is a quick example of how to push an attestation log using the client library:

```javascript
import { PackablockClient } from '@packablock/client';

// Initialize the zero-trust trust registry client
const client = new PackablockClient({
  endpoint: "https://api.packablock.com",
  registryId: "reg_01j1234567890abcdef",
  signingKey: process.env.PACKABLOCK_SIGNING_KEY
});

// Create and cryptographically sign a new package attestation log
const attestation = await client.attest({
  packageName: "auth-middleware",
  version: "1.4.2",
  status: "verified",
  metadata: {
    builder: "github-actions",
    commit: "d3b07384d113edec49eaa6238ad5ff00",
    attestedAt: new Date().toISOString()
  }
});

console.log(`Attestation published successfully! Hash: ${attestation.hash}`);
```
