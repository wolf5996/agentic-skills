---
name: creating-analysis-projects
description: Use when setting up a new R or bioinformatics analysis project, scaffolding directory structures, refactoring messy scripts into clean pipelines, or establishing project conventions. Use when the user says "init", "set up a project", "refactor these scripts", or "create a pipeline". Also use when reviewing whether an existing project follows these conventions.
---

# Creating Analysis Projects

## Overview

Scaffold R/bioinformatics analysis projects with a strict separation between code (version-controlled) and data/outputs (not tracked). Git lives at the **project root** with a whitelist `.gitignore` that tracks only `scripts/`. Every notebook is self-contained. Every convention is enforced by structure, not discipline.

**REQUIRED SUB-SKILLS:**
- Use `writing-r-code` for all R code generation
- Use `writing-qmd-scientific` for all QMD document structure
- Use `superpowers:brainstorming` when designing a new pipeline from scratch
- Use `superpowers:writing-plans` when the pipeline has 3+ notebooks to implement

## Directory Structure

The project uses a **read / write / checkpoints** triad as its core data flow architecture. This is non-negotiable — every project follows this layout:

```
project_name/                      # ← Git repo lives HERE
├── .git/
├── .gitignore                     # Whitelist: tracks only scripts/
├── read/                          # Raw input data — IMMUTABLE, never modified by code
│   └── reference/                 # Reference files (marker lists, GTFs, gene sets, etc.)
├── scripts/                       # ← All tracked code lives here
│   ├── .gitignore                 # Script-specific ignores (rendered outputs, caches, etc.)
│   ├── README.md
│   ├── project-name.Rproj         # RStudio project file (sets working directory)
│   ├── utils.R                    # Shared helper functions
│   ├── 01-first-step.qmd
│   ├── 02-second-step.qmd
│   └── ...
├── checkpoints/                   # RDS intermediates passed between pipeline steps
└── write/                         # All pipeline outputs
    ├── figures/                   #   Plots prefixed by step number
    └── tables/                    #   CSVs/Excel prefixed by step number
```

### The read / write / checkpoints triad

These three directories define how data flows through the project:

- **`read/`** — raw input data and reference files. Code reads from here but **never writes to it**. This directory is the immutable ground truth. Subdirectories organise by sample or data source (e.g., `read/bmls-4/filtered_feature_bc_matrix/`). Reference files like marker databases, gene annotations, and GTFs go in `read/reference/`.
- **`checkpoints/`** — serialised R objects (`.rds`) that pass state between pipeline steps. Each notebook reads its predecessor's checkpoint and writes its own. These are the pipeline's internal handoff mechanism. Named with step prefix: `01-merged-harmony.rds`, `02-annotated.rds`. Within a notebook, intermediate checkpoints enable self-contained chunks: `04-fibro-subset.rds` → `04-fibro-sct.rds` → `04-fibro-harmony.rds` → `04-fibro-states.rds`.
- **`write/`** — all human-facing outputs. Split into `write/figures/` (plots saved via `safe_ggsave()`) and `write/tables/` (CSVs, Excel files saved via `readr::write_csv()`, `openxlsx`). Everything is prefixed by step number so you can tell at a glance which notebook produced it.

### Why git at root with a scripts/ whitelist

- Git at root means one repo per project — no nested `.git/` confusion, clean `git clone` into the project root
- The whitelist `.gitignore` (`/*` then `!/scripts`) means only `scripts/` is ever tracked — everything else is silently ignored by default
- Adding new data directories (`read/sample-2/`, `outputs/`) never requires updating `.gitignore`
- `read/` is immutable raw data — large, binary, doesn't belong in git
- `checkpoints/` are ephemeral intermediates that change every re-run
- `write/` contains generated outputs that are reproducible from code

## Naming Conventions

### File naming: hyphens

All filenames use **hyphens** (`-`): `01-qc-integration.qmd`, `02-umap-singler.pdf`, `04-fibro-states.rds`

### Code naming: underscores

All R variable and function names use **snake_case** (`_`): `seu_integrated`, `marker_results_df`, `fix_md_rownames()`

### Output prefixes

Every output file is prefixed with its step number:
- Figures: `01-elbow-pca.pdf`, `02-umap-singler.pdf`
- Tables: `01-qc-summary.csv`, `04-fibro-markers-all.csv`
- Checkpoints: `01-merged-harmony.rds`, `02-annotated.rds`

### Variable descriptiveness

Variable names must make their type and purpose obvious at a glance:

| Bad | Good | Why |
|-----|------|-----|
| `obj`, `seu` | `seu_integrated`, `seu_fibro` | What Seurat object is this? |
| `objs` | `seu_list` | It's a list of Seurat objects |
| `md` | `metadata_df` | It's a metadata data frame |
| `mat` | `expr_matrix` | It's an expression matrix |
| `p`, `p1` | `plot_umap_clusters`, `plot_violin_state` | What does the plot show? |
| `res` | `go_enrichment`, `marker_results_df` | Results of what? |
| `sid`, `i`, `ct` | `sample_name`, `cluster_id`, `cell_type` | Loop iterators describe what they iterate |
| `df`, `tab` | `composition_df`, `regulon_diagnostic_df` | What data does it hold? |

Keep it practical — 2-3 words max. `seu_fibro` not `seurat_object_containing_fibroblast_subset`.

## Path Conventions

- All paths are **relative** from `scripts/`: `../read/`, `../checkpoints/`, `../write/figures/`
- Paths appear **inline at point of use** — never defined as upfront variables
- Exception: external dependencies the user must provide (e.g., a GTF file path) get a clearly commented variable at the top of the relevant chunk

```r
# Correct — inline at point of use
seu_integrated <- readr::read_rds("../checkpoints/01-merged-harmony.rds")
safe_ggsave("../write/figures/02-umap-singler.pdf", plot_umap, width = 8, height = 6)

# Incorrect — upfront path variables
checkpoint_dir <- "../checkpoints/"
fig_dir <- "../write/figures/"
```

## Pipeline Structure

### Numbered QMD notebooks

Each analysis step is a separate QMD file. Notebooks are numbered sequentially and pass data via RDS checkpoints:

```
01-first-step.qmd  →  ../checkpoints/01-output.rds
02-second-step.qmd →  reads 01-output.rds, writes ../checkpoints/02-output.rds
03-third-step.qmd  →  reads 02-output.rds, writes ../checkpoints/03-output.rds
```

### Shared utils.R

Helper functions used across multiple notebooks go in `utils.R`:
- Every QMD sources it: `source("utils.R")`
- Functions are grouped by category with `# Category ----------` headers
- No `rm(list = ls())` or side effects — pure utility functions only

### Self-contained code chunks

Every code chunk must be independently runnable. Follow the pattern from `writing-r-code`:

```r
# Libraries ----------
library(Seurat)
library(readr)

source("utils.R")

# Inputs ----------
seu <- readr::read_rds("../checkpoints/01-merged-harmony.rds")

# Processing ----------
seu <- NormalizeData(seu)

# Outputs ----------
readr::write_rds(seu, "../checkpoints/01-normalized.rds")
```

Processing chunks save intermediate checkpoints. Visualisation chunks load the latest checkpoint and save figures.

### Prose format

Section descriptions use **bullet points with bold key terms**, never paragraphs:

```markdown
## Quality Control

- **QC metrics**: `nFeature_RNA`, `nCount_RNA`, `percent.mt`
  - Mitochondrial fraction flags dying cells leaking cytoplasmic mRNA
- **Thresholds**: 200 ≤ nFeature ≤ 6000, nCount ≥ 500, percent.mt ≤ 20
  - Conservative but standard for 10x Chromium data
- **Rationale**: fixed thresholds chosen over MAD-based for reproducibility across batches
```

## Version Control Setup

### Initialise git at project root

```bash
cd project_name/
git init
git branch -m main
```

### Root .gitignore — whitelist approach

Ignores everything by default; only `scripts/` is tracked:

```gitignore
# Ignore everything
/*
/.*

# Whitelist: track only scripts/
!/scripts
```

### scripts/.gitignore — script-specific ignores

Place a second `.gitignore` inside `scripts/` to exclude rendered outputs and caches:

```gitignore
# Rendered outputs
*.html
*_files/

# Quarto cache and intermediates
.quarto/
_freeze/
_site/

# R intermediates
*.Rhistory
.Rproj.user/
.RData
.Rapp.history

# Knitr cache
*_cache/

# OS files
.DS_Store
Thumbs.db
```

### .Rproj template

```
Version: 1.0

RestoreWorkspace: No
SaveWorkspace: No
AlwaysSaveHistory: No

EnableCodeIndexing: Yes
UseSpacesForTab: Yes
NumSpacesForTab: 2
Encoding: UTF-8

AutoAppendNewline: Yes
StripTrailingWhitespace: Yes
```

### README structure

The README must clearly separate tracked vs untracked content:

1. **Project overview** — biological/scientific context
2. **Pipeline overview** — DAG or numbered list of analysis steps
3. **Per-step descriptions** — what each notebook does
4. **What is tracked** — tree of repo contents with one-line descriptions
5. **What is NOT tracked** — tree of parent directory with setup instructions
6. **Replication steps** — exact `git clone`, `mkdir`, and data placement commands
7. **Dependencies** — R packages with categories
8. **Code style** — brief summary of conventions

### GitHub repo creation

```bash
cd project_name/
git add scripts/
git commit -m "Initial commit: <N>-step <analysis-type> pipeline with shared utils"
gh repo create <descriptive-project-name> --private --source=. --push \
  --description "<one-line description of the analysis>"
```

Repo name should describe the science, not the tool: `capsular-contracture-scrna` not `seurat-analysis-pipeline`.

## Scaffolding Checklist

When setting up a new project:

1. Create parent directory structure (`read/`, `read/reference/`, `scripts/`, `checkpoints/`, `write/figures/`, `write/tables/`)
2. Move/organise raw data into `read/`
3. Move reference files into `read/reference/`
4. Archive any existing scripts to `.original_student_code/` or similar hidden directory
5. Create `.Rproj` in `scripts/`
6. Create `utils.R` in `scripts/` with shared helpers
7. Create numbered QMD notebooks in `scripts/`
8. Initialise git at project root; create root `.gitignore` (whitelist) and `scripts/.gitignore` (script-specific ignores)
10. Write `README.md`
11. Create GitHub repo and push

## Common Mistakes

| Mistake | Correct Approach |
|---------|-----------------|
| `git init` inside `scripts/` | `git init` at project root with whitelist `.gitignore` |
| Defining path variables upfront | Paths inline at every function call |
| Paragraph prose in QMD sections | Bullet points with bold key terms |
| Generic variable names (`obj`, `df`, `p`) | Descriptive names (`seu_fibro`, `composition_df`, `plot_umap_clusters`) |
| Chunks that depend on previous chunk state | Every chunk loads its own inputs from disk |
| Output files without step prefix | Always prefix: `01-`, `02-`, etc. |
| `readRDS()`/`saveRDS()` | `readr::read_rds()`/`readr::write_rds()` |
| `%>%` magrittr pipe | `\|>` native pipe |
| `here::here()` for paths | Relative `../` from `scripts/` |
| Mixing hyphens and underscores in filenames | Hyphens for files, underscores for code |
