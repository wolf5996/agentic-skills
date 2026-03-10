# Claude Code Skills for R & Bioinformatics

Opinionated [Claude Code] skills for single-cell RNA-seq analysis, R package development, and scientific documentation. Built for bioinformatics workflows using Seurat, Bioconductor, tidyverse, and Quarto.

  [Claude Code]: https://docs.anthropic.com/en/docs/claude-code

These skills encode specific conventions, patterns, and quality standards that Claude Code follows when working on your projects. They are deliberately opinionated — fork and adapt them to your own workflow.

## What Are Claude Code Skills?

Skills are markdown files (`SKILL.md`) that teach Claude Code domain-specific conventions. When Claude detects a relevant task (e.g., editing a `.qmd` file), it loads the matching skill and follows its rules. Skills live in `~/.claude/skills/` as subdirectories, each containing a single `SKILL.md` file.

## Skills Overview

| Skill | Domain | Description |
|------------------|---------------------|---------------------------------|
| **creating-analysis-projects** | Project Setup | Scaffolds bioinformatics analysis projects with strict separation of code (git-tracked) from data. Enforces the `read/` → `scripts/` → `checkpoints/` → `write/` directory architecture. |
| **writing-r-code** | R Coding | Tidyverse-first R coding conventions. Self-contained code chunks with `Libraries → Inputs → Processing → Outputs` structure. Seurat v5 layer-based patterns. Mandatory Context7 MCP verification for function calls. |
| **writing-qmd-scientific** | Quarto Documents | Standards for scientific Quarto notebooks. All explanatory prose must be bullet points (no paragraphs). Hashpipe (`#|`) chunk options. Parameter justification tables after every code block. |
| **writing-labarchive-entries** | Lab Notebooks | Verbose, structured lab documentation with numbered sections. Four entry types: Reference Datasets, Analysis Pipelines, Tool Evaluations, Educational Notes. PubMed MCP integration for citations. |
| **developing-r-packages** | R Packages | Full R package lifecycle following Wickham & Bryan's *R Packages*. roxygen2 documentation, testthat testing, semantic versioning, GitHub Actions CI/CD, pkgdown sites. |

## Skill Dependencies

The skills reference and build on each other:

```         
creating-analysis-projects
├── writing-r-code          (code chunk conventions)
└── writing-qmd-scientific  (document structure)
    └── writing-r-code      (inline code patterns)

writing-labarchive-entries  (standalone — references PubMed MCP)
developing-r-packages       (standalone — R package conventions)
```

**Reading order for newcomers:** 1. `creating-analysis-projects` — the overall project architecture 2. `writing-r-code` — code patterns used everywhere 3. `writing-qmd-scientific` — how to document analysis pipelines 4. `developing-r-packages` and `writing-labarchive-entries` — advanced/specialized

## Prerequisites

### Required

-   [Claude Code] CLI installed

  [Claude Code]: https://docs.anthropic.com/en/docs/claude-code

### BadranSeq

These skills reference [**BadranSeq**] as the preferred visualization package for scRNA-seq figures. I built BadranSeq to wrap Seurat, ggplot2, and ComplexHeatmap into a single package that produces publication-ready single-cell figures with minimal boilerplate.

  [**BadranSeq**]: https://github.com/wolf5996/BadranSeq

-   **GitHub:** [wolf5996/BadranSeq]
-   **Package site:** [wolf5996.github.io/BadranSeq]
-   **Used in:** `writing-r-code` (as the primary visualization fallback chain: BadranSeq → SCpubr → Seurat)

  [wolf5996/BadranSeq]: https://github.com/wolf5996/BadranSeq
  [wolf5996.github.io/BadranSeq]: https://wolf5996.github.io/BadranSeq/

If you don't use BadranSeq, see the [Fork & Customize] section below for how to swap in your own preferred visualization package.

  [Fork & Customize]: #fork--customize

### Recommended MCP Servers

-   [**Context7**] — `writing-r-code` mandates Context7 lookups to verify function signatures for 17+ R/Bioconductor packages before writing code. Without it, Claude will still write R code but won't verify against live documentation.
-   **PubMed MCP** — `writing-labarchive-entries` uses PubMed for citation lookups. Optional but enhances documentation quality.

  [**Context7**]: https://github.com/upstash/context7

## Installation

**Clone into your Claude Code skills directory:**

``` bash
# Back up any existing skills first
cp -r ~/.claude/skills ~/.claude/skills.bak

# Clone this repo as your skills directory
git clone https://github.com/wolf5996/claude-skills.git ~/.claude/skills
```

**Or cherry-pick individual skills:**

``` bash
# Clone somewhere temporary
git clone https://github.com/wolf5996/claude-skills.git /tmp/claude-skills

# Copy just the skills you want
cp -r /tmp/claude-skills/writing-r-code ~/.claude/skills/
cp -r /tmp/claude-skills/writing-qmd-scientific ~/.claude/skills/

# Clean up
rm -rf /tmp/claude-skills
```

## Fork & Customize

These skills are personal and opinionated by design. To make them yours:

1.  **Fork this repository** on GitHub
2.  **Swap author name** — search for `Badran Elshenawy` in YAML templates and replace with your name
3.  **Swap preferred packages** — `writing-r-code` references `BadranSeq` as the primary visualization package; replace with your own (e.g., `SCpubr`, `dittoSeq`, or base `Seurat`)
4.  **Adjust project paths** — `creating-analysis-projects` uses a specific `read/scripts/checkpoints/write/` layout; adapt if your lab uses different conventions
5.  **Adjust Context7 package list** — `writing-r-code` lists 17+ packages for mandatory lookup; add or remove packages to match your stack

## Design Decisions

A few things that look like inconsistencies are actually intentional:

-   **Numbered vs unnumbered headings**: `writing-qmd-scientific` forbids numbered headings (Quarto's TOC handles navigation), while `writing-labarchive-entries` mandates numbered sections (standalone records need explicit structure). Different document types, different conventions.
-   **Bullet points only in QMD**: `writing-qmd-scientific` strictly forbids paragraph prose outside code chunks — everything must be bullet points with nested sub-bullets. This is a deliberate readability choice, not a general rule for all skills.
-   **Self-contained chunks**: Every code chunk loads its own data from a checkpoint file rather than depending on in-memory state from previous chunks. This makes chunks independently runnable and debuggable.

## Adding New Skills

This repository is a work in progress. New skills are added as workflows mature.

**To add a skill:**

1.  Create a new directory: `~/.claude/skills/<skill-name>/`

2.  Add a `SKILL.md` file with YAML frontmatter:

    ``` yaml
    ---
    name: skill-name
    description: When to trigger this skill. Be specific about file types, task types, and contexts.
    ---
    ```

3.  Write the skill content following the patterns in existing skills

4.  Update this README's skills table and dependency graph

5.  Commit and push

**Naming convention:** lowercase, hyphen-separated (e.g., `writing-r-code`, `creating-analysis-projects`)

## License

MIT — fork, adapt, and share freely.