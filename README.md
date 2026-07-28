# 📖 docs.packablock.com

This repository houses the official documentation and technical specifications for **Packablock Deterministic Supply Chain Policy Control**. It is implemented as a static website built with Jekyll and served via Cloudflare Pages.

---

## 🏛️ Directory Structure

*   `spec.md`: The formal Continuous Attestation (CA) Specification (RFC-style draft).
*   `index.markdown`: The documentation homepage layout (features, installation, and GitHub integration scripts).
*   `about.markdown`: An overview of the Continuous Attestation philosophy and SLSA/Sigstore standards alignment.
*   `assets/`: Contains custom styling and use-case diagram assets.
*   `_includes/`: Contains navigation header templates and custom layout modifications.

---

## 🚀 Local Development

To run the documentation site locally for review, you can compile it using Jekyll via the standard Docker Compose workspace setup, or directly through Bundler:

### Using Docker (Workspace environment)
If you are running the `packablock-workspace` developer compose stack, the docs site is served side-by-side on your Tailscale network and mapped locally:
*   **URL**: `http://localhost:4003`

### Running Locally (Manual setup)
1. Ensure you have Ruby (v3.1+) and Bundler installed.
2. Install dependencies:
   ```bash
   bundle install
   ```
3. Start the Jekyll local server:
   ```bash
   bundle exec jekyll serve
   ```
4. Open your browser to: `http://localhost:4000`

---

## 👥 Contributing

We welcome improvements to the specification wording, typography layout, and browser accessibility overrides. Please submit pull requests to the `dev` branch.
