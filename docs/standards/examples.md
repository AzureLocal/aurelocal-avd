# Example Standards

Conventions for example scenarios and walkthroughs in this repository.

---

## Purpose

Examples demonstrate real-world deployment scenarios using the tools and scripts in this repo. They should be self-contained, reproducible, and educational.

---

## Structure

Each example should follow this format:

```markdown
# Example: <Descriptive Title>

## Overview
Brief description of what this example demonstrates and when you'd use it.

## Prerequisites
- List of requirements (tools, access, config)

## Configuration
Show the relevant `config/variables.yml` values for this scenario.

## Steps
1. Step-by-step instructions
2. With code blocks for each command
3. Expected output after each step

## Verification
How to confirm the deployment worked correctly.

## Cleanup
How to tear down resources created by this example.
```

---

## Guidelines

- Use **Infinite Improbability Corp (IIC)** as the fictional company in all examples — `iic.local` for domains, `IIC` for NetBIOS, `rg-iic-*` for resources. Never use `contoso`. See [Standards overview](index.md#fictional-identity).
- Show realistic but safe values (no real subscription IDs, IPs, or secrets)
- Include both the happy path and common failure scenarios
- Reference the relevant standards pages for conventions used
- Keep examples focused — one scenario per file
- Use `!!! note` admonitions for important context

---

## Location

Examples live in `examples/` at the repo root (future). Each example is a self-contained directory or Markdown file.
