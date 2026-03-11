# Contributing to Agentic AI Security Checklist

Thank you for your interest in making AI agent systems more secure.

## How to Contribute

### Reporting Issues

- **Security vulnerabilities in examples**: Please open an issue. These are example/reference implementations, not production security tools.
- **Incorrect information**: Open an issue with sources.
- **Missing attack vectors**: Open an issue describing the vector and its relevance to agentic AI.

### Pull Requests

We welcome PRs for:

1. **New checklist items** — Must include: description, why it matters, example check command, and criticality rating (CRITICAL or RECOMMENDED)
2. **Hook examples** — For Claude Code or other AI coding tools (Cursor, Windsurf, Copilot, etc.)
3. **CI templates** — For other platforms (GitLab CI, CircleCI, Azure Pipelines, etc.)
4. **Case studies** — Real-world incidents (anonymized if needed) that inform the checklist
5. **Translations** — Especially German, Japanese, Korean, Chinese
6. **Corrections** — Factual errors, outdated information, broken links

### PR Guidelines

- Keep changes focused — one topic per PR
- Update `CHECKLIST.md` if adding/modifying checklist items
- Update the item count in `README.md` if the total changes
- Test hook examples before submitting (see `examples/hooks/README.md` for test instructions)
- For threat model updates, cite sources

### Writing Style

- Be direct and actionable
- Include concrete commands and examples
- Explain *why* something is a risk, not just *what* to do
- Reference real incidents where possible (with sources)
- Keep it tool-agnostic where possible (Claude Code is the reference implementation, but principles apply broadly)

## Code of Conduct

Be respectful. Focus on making AI systems safer. Disagree constructively.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
