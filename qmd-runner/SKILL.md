---
name: qmd-runner
description: Use when debugging Quarto (`.qmd`) notebooks chunk-by-chunk via auto-generated tryCatch runners. Triggers when a `quarto render` fails opaquely, when you need to surface every failing chunk in one pass rather than stop at the first error, when iteratively fixing analysis pipelines (Seurat / Bioconductor / GSEA / biomaRt / msigdbr / clusterProfiler), or when adopting an inherited notebook tree whose chunks no longer execute end-to-end. Workflow: parse the qmd → emit a sibling `.R` runner with one `tryCatch` per `{r}` chunk → run it → fix the source qmd → regenerate the runner → repeat until the PASS / FAIL / SKIP summary table is fully green; then commit the qmd fixes and do a final `quarto render`.
---

# QMD Runner Debugging

## Overview

- **Problem**: `quarto render` aborts at the first chunk that errors, so a single broken cell hides every downstream failure. Iterating one error at a time on a 20-chunk analysis notebook is slow.
- **Solution**: programmatically extract each `{r}` chunk into a sibling `.R` runner where every chunk is wrapped in `tryCatch`. Run the runner, get a single PASS / FAIL / SKIP table for every chunk in one pass, fix everything, repeat.
- **Rule**: every fix lands in the **source `.qmd`**. The runner is regenerated from the qmd each iteration — never hand-edit the runner.
- **End state**: when every chunk is PASS / SKIP, the corresponding `quarto render` will succeed too. Renders go from a debugging tool to a final-output tool.

## When to Use

- A `quarto render` of an analysis notebook errors out and the message is hard to parse
- Adopting an inherited pipeline that has not been re-rendered in months
- Upgrading a key dependency (`Seurat`, `dplyr`, `msigdbr`, `biomaRt`, `clusterProfiler`) and a sweep of qmds needs revalidating
- Many chunks share in-memory state (e.g. GSEA pipelines where `feature_loadings` flows through several PC chunks) and you want chunk-level isolation of failures
- Multi-script pipelines where downstream notebooks read checkpoints from upstream notebooks (`creating-analysis-projects` `read → scripts → checkpoints → write` layout) and you want to validate the whole DAG

## When NOT to Use

- Single-chunk qmds where the cost of building a runner exceeds the diagnostic gain — just `quarto render` directly
- Render failures caused by YAML / front-matter errors (not chunk code) — those need a different fix
- Producing the polished `.html` artefact — the runner does not invoke Quarto, so the html does not get rebuilt; finish with `quarto render` once chunks are green

## Workflow

### R0 — Wire up the generator (once per repo)

- Place `runners/generate-runner.R` at the repo root and a matching `.gitignore` exclusion
- The generator is the only thing that gets committed; per-script runner outputs stay gitignored

`.gitignore` excerpt:

```gitignore
# Per-chunk debug runners (auto-generated from qmds)
!runners/
!runners/generate-runner.R
mcf7/scripts/runners/
hcc1806/scripts/runners/
```

### R1 — Generate runners for every active qmd

- Run `Rscript runners/generate-runner.R <qmd-path>` (or pass several) for every notebook to be debugged
- Each emits `<dirname(qmd)>/runners/<basename-without-ext>.R`
- Skip notebooks that are not worth runner-debugging (e.g. credentials-only deployment scripts)

### R2 — Iterative debug loop

For each runner, in dependency order (01 → 02 → 03 → ...):

1. `Rscript <runner>.R 2>&1 | tee <runner>.log`
2. Read the PASS / FAIL / SKIP table at the bottom
3. For each FAIL:
   a. Diagnose the underlying error from the runner's `Error:` line
   b. **Edit the source qmd** (not the runner) to fix the root cause
   c. `Rscript runners/generate-runner.R <qmd-path>` to regenerate
   d. Re-run, confirm the chunk now PASSes
4. Move to the next runner once every chunk in the current one is PASS or SKIP

### R3 — Commit the fixes

- `git status` now shows only the `.qmd` edits from step R2
- Commit with a single conventional-commits message (e.g. `fix: address chunk-level errors surfaced by runners`), or split per-script if the diff is large
- Runners stay untracked

### R4 — Final `quarto render`

- Run `quarto render <qmd>` sequentially in dependency order to produce the polished html and repopulate `write/` + `checkpoints/` end-to-end
- All chunks should pass since the runners already proved it; if any chunk does fail in the actual render, it is usually a render-time concern (e.g. knitr cache, fig device, working directory) — drop back into R2 for that script

### R5 — Report

- Print a per-script PASS table
- Verify checkpoints and figures landed where expected

## Anatomy of a Runner

Generated runner preamble (every runner starts with this):

```r
# Locate the project .Rprofile by walking up from getwd() until we find it,
# then setwd(repo_root) BEFORE sourcing it so renv/activate.R picks the
# correct project library path. Finally setwd() into the script's directory
# so the qmd's relative paths (../checkpoints/, ../write/) resolve correctly.
local({
  cand <- normalizePath(getwd(), winslash = "/")
  for (i in 1:8) {
    if (file.exists(file.path(cand, ".Rprofile")) && file.exists(file.path(cand, "renv/activate.R"))) break
    parent <- dirname(cand)
    if (parent == cand) break
    cand <- parent
  }
  Sys.setenv(SMARTSEQ_REPO_ROOT = cand)
  prev_wd <- getwd()
  setwd(cand)
  source(".Rprofile", local = FALSE)
  setwd(prev_wd)
})
setwd(file.path(Sys.getenv("SMARTSEQ_REPO_ROOT"), "<cell-line>/scripts"))

# Chunk-level outcome accumulator.
RUNNER_RESULTS <- list()

run_chunk <- function(label, expr) {
  cat(sprintf("\n=== [%s] START: %s ===\n", format(Sys.time(), "%H:%M:%S"), label))
  result <- tryCatch({
    eval(expr, envir = .GlobalEnv)
    cat(sprintf("=== [%s] PASS:  %s ===\n", format(Sys.time(), "%H:%M:%S"), label))
    list(status = "PASS", error = NA_character_)
  }, error = function(e) {
    cat(sprintf("=== [%s] FAIL:  %s ===\n", format(Sys.time(), "%H:%M:%S"), label))
    cat(sprintf("  Error: %s\n", conditionMessage(e)))
    list(status = "FAIL", error = conditionMessage(e))
  })
  RUNNER_RESULTS[[label]] <<- result
  invisible(result)
}

skip_chunk <- function(label, reason = "marked eval: false in qmd") {
  cat(sprintf("\n=== [%s] SKIP:  %s (%s) ===\n", format(Sys.time(), "%H:%M:%S"), label, reason))
  RUNNER_RESULTS[[label]] <<- list(status = "SKIP", error = NA_character_)
  invisible(NULL)
}
```

Each chunk in the runner becomes:

```r
# ---- chunk: <label> (qmd line ~<N>) ----
run_chunk("<label>", quote({
  <chunk body>
}))
```

For chunks marked `#| eval: false` in the qmd:

```r
# ---- chunk: <label> ----
skip_chunk("<label>")
```

Summary block at the bottom prints the PASS / FAIL / SKIP table and `quit(status = 1L)` if any FAIL.

## The Generator

`runners/generate-runner.R` is responsible for:

- Reading the qmd line-by-line
- Detecting `{r}` chunk opens (` ```{r}` or ` ```{r ...}`) and `` ``` `` closes
- Lifting `#| label:` and `#| eval:` options out of each chunk header
- Indenting the chunk body two spaces and wrapping it in `run_chunk(<label>, quote({ ... }))`
- Emitting one file at `<dirname(qmd)>/runners/<basename-without-ext>.R`
- Being idempotent: re-running overwrites without prompting

Why eval in `.GlobalEnv`: Quarto / knitr renders each chunk into the document's global environment, so any chunk-to-chunk state-sharing (functions defined in chunk 1 used in chunk 5) Just Works. The runner mirrors this exactly so a passing runner predicts a passing render.

Run the generator on multiple qmds at once:

```bash
Rscript runners/generate-runner.R \
  mcf7/scripts/01-processing-pipeline.qmd \
  mcf7/scripts/02-tables-visualisations.qmd \
  hcc1806/scripts/01-processing-pipeline.qmd
```

## Common Failure Patterns

These come up over and over on real-world Seurat / Bioconductor pipelines. Fix them in the source `.qmd`, not the runner.

| Error message | Root cause | Fix in qmd |
|---|---|---|
| `unable to find an inherited method for function 'select' for signature 'x = "spec_tbl_df"'` | `AnnotationDbi::select` masking `dplyr::select` after `library(biomaRt)` | Add `dplyr::select` to the `conflicts_prefer()` block in the qmd's `setup` chunk. The block covers the union of everything the notebook attaches, so add the verb there rather than patching the chunk that broke |
| `Cannot find directory '../write/figures/...'` | `ggsave` / `pdf()` requires the parent dir to exist | Add the missing `dir.create("../write/figures/<NN-script-slug>", recursive = TRUE, showWarnings = FALSE)` to the qmd's `setup` chunk, which holds every output directory the script writes to. Outputs live in per-script subdirectories matching the qmd basename — see `creating-analysis-projects`. |
| `Unable to query any Ensembl site` | biomaRt's default mirror is unresponsive | Loop through explicit mirrors and cache the result on disk: |
| `Duplicate values in names(stats) not allowed` (from `gseGO`) | Gene-symbol → entrez mapping is many-to-many; named vector has duplicate names | De-duplicate by `entrezgene_id` and drop `NA`s before constructing the named vector |
| `Unknown subcollection` (from `msigdbr`) | API drift — `category=` / `subcategory=` are now `collection=` / `subcollection=`, and subcollection IDs went uppercase (`MIR:MIR_LEGACY`) | Switch the parameter names and uppercase the subcollection ID |
| `path does not exist: '../read/reference/X.xlsx'` | Filename in qmd does not match what is on disk | List the actual `read/reference/` tree; many signature files ship as plain whitespace-delimited text rather than `.xlsx` |
| `NA/NaN/Inf in foreign function call (arg 10)` (from `hclust`) | `t(scale(t(mat)))` produces NaN rows when a gene's variance is zero | Drop zero-variance rows: `mat <- mat[apply(mat, 1, function(x) all(is.finite(x))), , drop = FALSE]` |
| `object 'X' not found` | A chunk references state that an earlier chunk would have defined, but you ran it standalone — or an earlier chunk failed and the variable was never created | Either run chunks top-to-bottom (the runner does), or refactor to read state from a checkpoint (`creating-analysis-projects` checkpoint pattern) |
| Masked-verb or missing-directory errors in the **first** chunk you run | The `setup` chunk was skipped. It registers the conflict preferences and creates the output directories for the whole notebook | Always run `setup` first. It is the one chunk every other chunk depends on |
| `#\| label:` invalid because a non-comment line precedes it | Something was inserted BEFORE the chunk option lines | Chunk options come first; all code goes in the chunk **body**, after every `#|` line |
| `there is no package called 'X'` | Package not installed in the renv library | `Rscript -e 'pak::pkg_install("X")'` handles CRAN, Bioconductor, and GitHub sources uniformly |

biomaRt mirror-fallback + cache pattern (the universal fix for the Ensembl errors):

```r
annotation_cache <- "../checkpoints/<NN>-<cellline>-biomart-annotation.rds"
if (file.exists(annotation_cache)) {
  annotation <- read_rds(annotation_cache)
} else {
  human <- NULL
  for (mirror in c("useast", "asia", "www")) {
    human <- tryCatch(
      useEnsembl(biomart = "genes", dataset = "hsapiens_gene_ensembl", mirror = mirror),
      error = function(e) NULL
    )
    if (!is.null(human)) break
  }
  if (is.null(human)) stop("biomaRt: every Ensembl mirror failed to respond")
  annotation <- getBM(
    attributes = c("ensembl_gene_id", "hgnc_symbol"),
    filters    = "ensembl_gene_id",
    values     = ids_to_lookup,
    mart       = human
  )
  write_rds(annotation, annotation_cache)
}
```

## Dependency Ordering

When a project has multiple notebooks that pass data via checkpoints, run runners in upstream-to-downstream order:

- Root notebooks first (data import, QC, normalisation) — they produce the canonical clustered checkpoint
- Then notebooks that read that checkpoint (visualisation, DEA, enrichment)
- Then notebooks that read DEA results (paper figures, target curation, app exports)

Pattern: `01 → 02 / 03 → 04+ in parallel`. Catching a 01 failure early prevents 12 cascading downstream failures.

Cross-line projects (e.g. MCF7 vs HCC1806) often vendor an upstream checkpoint into a sibling tree's `read/reference/external/`. Re-vendor that checkpoint immediately after the upstream notebook succeeds so downstream cross-line scripts pick up the fresh version:

```bash
cp hcc1806/checkpoints/01-hcc1806-seurat-clustered.rds \
   mcf7/read/reference/external/02-hcc1806-seurat-clustered.rds
```

## Tracked vs Gitignored

- **Tracked**: `runners/generate-runner.R` (the generator itself) and the `.gitignore` rules
- **Gitignored**: every `<script-dir>/runners/<file>.R` and `<file>.log` — these are derivative

## Pairs Well With

- `writing-r-code` — the per-chunk Libraries / Inputs / Processing / Outputs structure that this debugging loop assumes
- `writing-qmd-scientific` — hashpipe (`#|`) chunk options that the generator parses
- `creating-analysis-projects` — checkpoint-flow conventions that explain why downstream chunks fail when an upstream notebook has not been re-run
- `git-hygiene` — conventional commit format for the R3 fix-commits
