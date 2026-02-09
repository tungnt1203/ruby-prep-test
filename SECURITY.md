# Security Policy

## Reporting a Vulnerability

We take the security of FastQuiz and its users seriously. If you discover a security vulnerability, please **do not** open a public Issue on GitHub.

### How to Report

* Send a detailed description **by email** to the project maintainers (address may be in the maintainer’s GitHub profile or in the README).
* Alternatively, if the repo has a **Security** tab: use [GitHub Security Advisories](https://github.com/your-org/fast_quiz/security/advisories/new) (Private vulnerability reporting) to submit a report privately.

Your report should include:

* A description of the vulnerability and its impact (e.g. XSS, SQL injection, exposure of sensitive data).
* Steps to reproduce, as specific as possible.
* Environment details (Ruby version, Rails version, browser, etc.) if relevant.
* Suggested fix (optional).

### What to Expect

* We will acknowledge receipt of your report within a reasonable time (typically within a few days).
* After verification, we will communicate our plan to address it and, where appropriate, when a fix or advisory will be published.
* Reporters may be credited in the advisory or release notes (unless you prefer to remain anonymous).

### Scope

This policy applies to:

* The FastQuiz source code and configuration in this repository.
* Dependencies used directly by the project (Ruby gems, npm packages).

Security issues in third-party services (Viblo, OpenRouter, Gemini, etc.) should be reported directly to the respective provider; you may still notify us if it relates to how FastQuiz uses those services.

## Security Updates

* We encourage keeping dependencies up to date. The project uses `bundler-audit` and Brakeman in CI to help detect known issues.
* When important security fixes are available, we will update versions and note them in releases or changelog where possible.

Thank you for helping keep FastQuiz secure.
