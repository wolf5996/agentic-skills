# Agentic Skills for R & Bioinformatics

Opinionated agent skills for single-cell RNA-seq analysis, R package development, and scientific documentation. Built for bioinformatics workflows using Seurat, Bioconductor, tidyverse, and Quarto.

These skills encode specific conventions, patterns, and quality standards that AI coding agents follow when working on your projects. They are deliberately opinionated — fork and adapt them to your own workflow.

## Supported Agents

This repository works with both **Claude Code** and **Codex**. Each tool discovers skills differently:

- **Claude Code** reads `SKILL.md` files directly from `~/.claude/skills/`, using YAML frontmatter (`name`, `description`) to determine when to load each skill.
- **Codex** reads `SKILL.md` files from `~/.codex/skills/` and uses `agents/openai.yaml` metadata for interface display names, descriptions, and default prompts.

Both tools share the same skill content (`SKILL.md`). The `agents/` subdirectories are Codex-specific and harmless to Claude Code — they are simply ignored.

## What Are Skills?

Skills are markdown files (`SKILL.md`) that teach an AI agent domain-specific conventions. When the agent detects a relevant task (e.g., editing a `.qmd` file), it loads the matching skill and follows its rules. Skills live in the agent's skills directory as subdirectories, each containing a `SKILL.md` file and optionally an `agents/openai.yaml` for Codex metadata.

### Codex Agent Metadata

Each skill may include an `agents/openai.yaml` file that provides Codex-specific UI metadata:

- `display_name` — how the skill appears in Codex's interface
- `short_description` — tooltip text shown when browsing skills
- `default_prompt` — the prompt template Codex uses when invoking the skill

Claude Code does not use these files; it reads the YAML frontmatter in `SKILL.md` directly. The `agents/` directories are committed to the shared repo so both tools stay in sync, but they only affect Codex behavior.

## Skills Overview

| Skill | Domain | Description |
|-------------------|---------------------|---------------------------------|
| **creating-analysis-projects** | Project Setup | Scaffolds bioinformatics analysis projects with strict separation of code (git-tracked) from data. Enforces the `read/` → `scripts/` → `checkpoints/` → `write/` directory architecture. |
| **writing-r-code** | R Coding | Tidyverse-first R coding conventions. Self-contained code chunks with `Libraries → Inputs → Processing → Outputs` structure. Seurat v5 layer-based patterns. Mandatory Context7 MCP verification for function calls. |
| **writing-qmd-scientific** | Quarto Documents | Standards for scientific Quarto notebooks. All explanatory prose must be bullet points (no paragraphs). Hashpipe (`#\|`) chunk options. Parameter justification tables after every code block. |
| **writing-labarchive-entries** | Lab Notebooks | Verbose, structured lab documentation with numbered sections. Four entry types: Reference Datasets, Analysis Pipelines, Tool Evaluations, Educational Notes. PubMed MCP integration for citations. |
| **developing-r-packages** | R Packages | Full R package lifecycle following Wickham & Bryan's *R Packages*. roxygen2 documentation, testthat testing, semantic versioning, GitHub Actions CI/CD, pkgdown sites. |
| **tailoring-applications** | Job Applications | Full pipeline for tailoring CVs and cover letters from job adverts. Parses adverts (text, URL, or PDF), scaffolds application directories, drafts product-market-fit cover letters and tailored CVs, renders to PDF, and drafts PI outreach emails. Covers academic and industry roles. |
| **md-to-html** | Document Conversion | Converts markdown files into self-contained HTML documents via Quarto. Wraps `.md` content in a `.qmd` with a preferred YAML header (darkly theme, TOC, embedded resources) and renders with `quarto render` using the native Quarto engine (not knitr). Preserves content as-is—conversion only, no restructuring. |
| **git-hygiene** | Version Control | Conventional Commits format with scoped types, lowercase subjects, and granular atomic commits. Covers type selection (`feat`, `fix`, `docs`, `style`, `refactor`, `chore`, `ci`, `test`), optional scopes, branching conventions, and pre-commit checklist. |
| **md-format** | Writing | Formatting rules for `.md`, `.rmd`, and `.qmd` files rendered by pandoc. Enforces blank-line separation before bullet lists to prevent items collapsing horizontally. Includes verification grep commands and covers all trigger contexts (bold headings, inline emphasis labels, paragraphs ending with colons). |
| **hugo-blog** | Publishing | End-to-end workflow for publishing posts on the Hugo personal blog. Covers the dual-file `.rmd`/`.md` pattern, hugodown rendering, file naming, YAML front matter, README sync before every push, commit message format, and common mistakes. |
| **recommendation-letter-workflow** | Academic Applications | Full pipeline for creating and maintaining recommendation letters for PhD and postdoc applications. Quarto-based `.qmd` sources rendered to PDF. Enforces 5-section structure, specificity rules (concrete examples per section), superlative caps, programme-tailored closing sentences, and 2-page maximum length. |

## Skill Dependencies

The skills reference and build on each other:

```         
creating-analysis-projects
├── writing-r-code          (code chunk conventions)
└── writing-qmd-scientific  (document structure)
    └── writing-r-code      (inline code patterns)

writing-labarchive-entries   (standalone — references PubMed MCP)
developing-r-packages       (standalone — R package conventions)
tailoring-applications      (standalone — CV and cover letter pipeline)
md-to-html                  (standalone — converts .md → .qmd → .html via Quarto)
git-hygiene                 (standalone — conventional commit format and branching)
```

**Reading order for newcomers:**

1. `creating-analysis-projects` — the overall project architecture
2. `writing-r-code` — code patterns used everywhere
3. `writing-qmd-scientific` — how to document analysis pipelines
4. `developing-r-packages` and `writing-labarchive-entries` — advanced/specialized
5. `tailoring-applications` — CV and cover letter pipeline
6. `md-to-html` — converting finished markdown to polished HTML
7. `git-hygiene` — version control conventions for all repos

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

**Clone into your skills directory:**

``` bash
# For Claude Code
git clone https://github.com/wolf5996/agentic-skills.git ~/.claude/skills

# For Codex (can be the same or a separate clone)
git clone https://github.com/wolf5996/agentic-skills.git ~/.codex/skills
```

Both tools can point to the same GitHub repo. The shared skill content stays in sync automatically.

**Cherry-pick individual skills:**

``` bash
git clone https://github.com/wolf5996/agentic-skills.git ~/.codex/skills
cp -r /tmp/agentic-skills/writing-r-code ~/.claude/skills/
rm -rf /tmp/agentic-skills
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

1.  Create a new directory: `personal_skills/<skill-name>/`

2.  Add a `SKILL.md` file with YAML frontmatter:

    ``` yaml
    ---
    name: skill-name
    description: When to trigger this skill. Be specific about file types, task types, and contexts.
    ---
    ```

3.  Write the skill content following the patterns in existing skills

4.  If using Codex, optionally add `agents/openai.yaml` with display metadata

5.  Create symlinks in both agents' skills directories:

    ``` bash
    ln -s personal_skills/<skill-name> ~/.claude/skills/<skill-name>
    ln -s personal_skills/<skill-name> ~/.codex/skills/<skill-name>
    ```

6.  Update this README's skills table and dependency graph

7.  Commit and push

**Naming convention:** lowercase, hyphen-separated (e.g., `writing-r-code`, `creating-analysis-projects`)

## License

MIT — fork, adapt, and share freely.