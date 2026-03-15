# Documentation Standards

Conventions for all documentation in this repository. Docs are built with MkDocs Material and published via GitHub Actions.

---

## Structure

All documentation lives in the `docs/` directory. The MkDocs site nav is defined in `mkdocs.yml`.

```
docs/
├── index.md                    # Home page
├── architecture.md             # Architecture overview
├── getting-started.md          # Quick start guide
├── avd-deployment-guide.md     # Full AVD deployment walkthrough
├── contributing.md             # Contribution guidelines
├── reference/
│   └── variables.md            # Variable reference (auto from config)
└── standards/
    ├── index.md                # This section overview
    ├── scripts.md              # Script standards
    ├── documentation.md        # Documentation standards (this file)
    ├── solutions.md            # IaC standards
    ├── variables.md            # Variable/config standards
    └── examples.md             # Example scenario standards
```

## Formatting

- Use **Markdown** with MkDocs Material extensions (admonitions, tabs, code blocks)
- Use ATX-style headers (`#`, `##`, `###`)
- One sentence per line (for clean diffs)
- Use fenced code blocks with language hints: ` ```powershell `, ` ```yaml `, ` ```bash `
- Use admonitions for warnings, notes, and tips:

```markdown
!!! warning
    This will delete all data.

!!! note
    Requires PowerShell 7.0+.
```

## Style

- Write in second person ("you") for guides
- Use present tense
- Be direct — avoid filler words
- Use tables for structured reference data
- Link to other docs pages using relative paths (e.g., `[Variables](reference/variables.md)`)

## MkDocs Build

The site builds with `mkdocs build --strict`. All warnings are treated as errors:

- No broken internal links
- No missing nav entries
- No orphaned pages (every `.md` in `docs/` should be in the nav)

## GitHub Actions

The deploy workflow (`.github/workflows/deploy-docs.yml`) runs on:

- Push to `main` when `docs/**` or `mkdocs.yml` change
- Manual dispatch (`workflow_dispatch`)
