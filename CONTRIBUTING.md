# Contributing to FastQuiz

Thank you for your interest in contributing to FastQuiz. This document explains how to contribute code, report bugs, and suggest features.

## Code of Conduct

This project adheres to the [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to respect the standards set out there.

## How to Contribute

### Reporting Bugs and Suggesting Features

* **Bugs:** Open an [Issue](https://github.com/your-org/fast_quiz/issues) with an appropriate label. Please include: Ruby/Rails versions, steps to reproduce, and expected vs actual behavior.
* **Features:** Open an Issue describing the use case and rationale. You can discuss before writing code.

### Submitting Changes (Pull Request)

1. **Fork** the repo and clone it locally.
2. Create a **branch** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   # or fix/your-bug-name
   ```
3. **Set up and run** the app following the [README](README.md#setup).
4. Make your changes and ensure:
   * Tests pass: `bin/rails test`
   * RuboCop passes: `bin/rubocop` (if applicable)
   * Code follows the existing style in the project
5. Commit with a clear message (e.g. `Add validation for exam code`).
6. Push your branch and open a **Pull Request** against `main`.
7. Address review feedback if the maintainers request changes.

### Code Conventions

* **Ruby:** Follow the [Ruby Style Guide](https://rubystyle.guide/) and the project’s [.rubocop.yml](.rubocop.yml) configuration.
* **JavaScript/TypeScript:** Keep style consistent with existing code.
* **Commits:** Use concise messages in present tense (e.g. “Add …” instead of “Added …”).

### Running Tests and CI

Before submitting a PR, run:

```bash
bin/rails test
bin/rubocop
bin/brakeman --quiet --no-pager
bin/bundler-audit
```

The project’s CI runs tests and similar security checks.

## Security

If you discover a security vulnerability, **do not** open a public Issue. Please see [SECURITY.md](SECURITY.md) for how to report it safely.

## Questions

If you have questions about the contribution process, you can open an Issue with the “question” or “discussion” label.

Thank you for contributing.
