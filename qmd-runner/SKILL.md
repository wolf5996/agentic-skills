---
name: qmd-runner
description: Use when debugging Quarto (`.qmd`) notebooks chunk-by-chunk via auto-generated tryCatch runners. Triggers when a `quarto render` fails opaquely, when you need to surface every failing chunk in one pass rather than stop at the first error, when iteratively fixing analysis pipelines (Seurat / Bioconductor / GSEA / biomaRt / msigdbr / clusterProfiler), or when adopting an inherited notebook tree whose chunks no longer execute end-to-end. Workflow: parse the qmd → emit a sibling `.R` runner with one `tryCatch` per `{r}` chunk → run it → fix the source qmd → regenerate the runner → repeat until the PASS / FAIL / SKIP summary table is fully green; then commit the qmd fixes and do a final `quarto render`. Also use when a qmd whose YAML sets `execute: eval: false` has to be executed for real and must stop at the first error: `--mode execute` emits a fail-fast runner, launched through `resource-watched-run`.
---

# QMD Runner

## Overview

- **Problem**: `quarto render` aborts at the first chunk that errors, so a single broken cell hides every downstream failure. Iterating one error at a time on a 20-chunk analysis notebook is slow.
- **Solution**: programmatically extract each `{r}` chunk into a sibling `.R` runner where every chunk is wrapped in `tryCatch`. Run the runner, get a single PASS / FAIL / SKIP table for every chunk in one pass, fix everything, repeat.
- **Rule**: every fix lands in the **source `.qmd`**. The runner is regenerated from the qmd each iteration — never hand-edit the runner.
- **End state**: when every chunk is PASS / SKIP, the corresponding `quarto render` will succeed too. Renders go from a debugging tool to a final-output tool.
- **Two modes**: debug (above: `tryCatch`, every chunk, summary table) and execute (fail-fast, timestamped progress lines, for running a notebook for real). See `## Modes`.
- **Working directory**: both modes resolve it from the qmd's YAML (`root.dir`, then `execute-dir`, then the qmd's directory) and bake it into the runner as a comment plus `setwd()`.

## When to Use

- A `quarto render` of an analysis notebook errors out and the message is hard to parse
- Adopting an inherited pipeline that has not been re-rendered in months
- Upgrading a key dependency (`Seurat`, `dplyr`, `msigdbr`, `biomaRt`, `clusterProfiler`) and a sweep of qmds needs revalidating
- Many chunks share in-memory state (e.g. GSEA pipelines where `feature_loadings` flows through several PC chunks) and you want chunk-level isolation of failures
- Multi-script pipelines where downstream notebooks read checkpoints from upstream notebooks (`creating-analysis-projects` `read → scripts → checkpoints → write` layout) and you want to validate the whole DAG
- A notebook whose YAML sets `execute: eval: false` (documentation-only render) must actually produce its outputs: `quarto render` executes nothing, so execute mode is the only way to run it as written
- A long multi-chunk conversion where a later verification chunk must never run on partial outputs (execute mode)

## When NOT to Use

- Single-chunk qmds where the cost of building a runner exceeds the diagnostic gain — just `quarto render` directly
- Render failures caused by YAML / front-matter errors (not chunk code) — those need a different fix
- Producing the polished `.html` artefact — the runner does not invoke Quarto, so the html does not get rebuilt; finish with `quarto render` once chunks are green
- **Debug mode on a long, heavy pipeline that must not continue past an error:** `tryCatch` keeps going, so a later verification chunk runs on partial outputs and reports a misleading result. Use execute mode
- **Execute mode for first-time debugging:** it stops at the first error, so each run teaches you one failure. Debug until green first

## Modes

| | Debug (default) | Execute |
|---|---|---|
| Flag | `--mode debug` or none | `--mode execute` |
| Output file | `runners/<basename>-debug.R` | `runners/<basename>-execute.R` |
| Error handling | `tryCatch` per chunk, keeps going | none; `Rscript` halts at the first error, exit status 1 |
| Progress | `=== [HH:MM:SS] START/PASS/FAIL ===` | `YYYY-MM-DD HH:MM:SS chunk: <label>` on stderr |
| End of run | PASS / FAIL / SKIP table, exit 1 if any FAIL | `done in N min` |
| `#| eval: false` chunks | `skip_chunk()` | `chunk_skip()` message; `--all` includes them |
| Resume | not applicable | `--from <label>` skips earlier chunks |
| Launch | foreground `Rscript ... | tee` | always through `resource-watched-run` |
| Use for | finding every broken chunk | producing the outputs for real |

**Debug until green, then execute:**

1. Debug runner until every chunk is PASS or SKIP (R1 to R2)
2. Commit the qmd fixes (R3)
3. `Rscript runners/generate-runner.R --mode execute <qmd>` (E1)
4. Launch through `resource-watched-run` (E2)
5. Verify the outputs landed and are complete (E4)
6. `quarto render` only if the document renders anything; a `execute: eval: false` notebook is already done

## Workflow

### R0 — Wire up the generator (once per repo)

- Place `runners/generate-runner.R` at the repo root and a matching `.gitignore` exclusion
- The generator is the only thing that gets committed; per-script runner outputs stay gitignored
- Copy the generator from the most recent repo that has one; the canonical version supports `--mode`, `--all` and `--from` (see `## The Generator`)

`.gitignore` excerpt:

```gitignore
# Per-chunk debug runners (auto-generated from qmds)
!runners/
!runners/generate-runner.R
mcf7/scripts/runners/
hcc1806/scripts/runners/
```

- **Whitelist-style `.gitignore`** (`*` then `!scripts/**`): the `!scripts/**` line re-tracks `scripts/runners/`, so add `scripts/runners/` after it, plus `!runners/generate-runner.R`

### R1 — Generate runners for every active qmd

- Run `Rscript runners/generate-runner.R <qmd-path>` (or pass several) for every notebook to be debugged; `--mode debug` is the default
- Each emits `<dirname(qmd)>/runners/<basename-without-ext>-debug.R` (debug) or `<basename-without-ext>-execute.R` (execute), so the filename always states which mode a runner is
- Skip notebooks that are not worth runner-debugging (e.g. credentials-only deployment scripts)

### R2 — Iterative debug loop

For each runner, in dependency order (01 → 02 → 03 → ...):

1. `Rscript <runner>-debug.R 2>&1 | tee <runner>-debug.log`
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

### E1 to E4 — Execute mode

Use after the debug table is green, or for a notebook that renders with `execute: eval: false` and has to be run as written.

- **E1 Generate:** `Rscript runners/generate-runner.R --mode execute scripts/01-rda-to-rds.qmd` writes `scripts/runners/01-rda-to-rds-execute.R`. Read the `# Working directory:` comment at the top and confirm it is the directory the qmd's relative paths expect

- **E2 Launch:** always through `resource-watched-run`: pre-flight the machine, launch under `nice -n 10 /usr/bin/time -l` in the background, arm the monitor with `PROGRESS='chunk:'`. Do not repeat the commands here; that skill owns them

- **E3 Resume after a mid-run failure:** fix the qmd, then regenerate with `--from <label>` at the first chunk whose inputs are complete on disk. Chunks before it become `chunk_skip()` lines. The hand alternative, deleting finished chunk blocks from the `-execute.R`, is allowed because execute runners are disposable, but `--from` is reproducible

  - **Caveat:** `--from` also skips a `setup` chunk. Resume only where every input is on disk, which the per-chunk `Libraries / Inputs / Processing / Outputs` structure from `writing-r-code` guarantees

- **E4 Verify:** confirm the expected outputs exist and are complete (row counts, `dim()` tables, file counts), then report with the post-run table from `resource-watched-run`

## Anatomy of a Runner

Generated debug runner preamble (every debug runner starts with this):

```r
# Auto-generated by runners/generate-runner.R --mode debug. Do not edit by hand.

# Working directory: knitr opts_knit root.dir ".." in 01-rda-to-rds.qmd
setwd("/abs/path/to/analysis")

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

When the repo root holds an `.Rprofile`, the preamble sources it from the root first so renv activates the project library, then calls `setwd()`.

### Execute runner

```r
# Auto-generated by runners/generate-runner.R --mode execute. Do not edit by hand.
# Fail-fast: no tryCatch. Rscript halts on the first error with exit status 1.

# Working directory: knitr opts_knit root.dir ".." in 01-rda-to-rds.qmd
setwd("/abs/path/to/analysis")

options(warn = 1)
RUNNER_T0 <- Sys.time()
chunk_start <- function(label) message(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " chunk: ", label)
chunk_skip <- function(label, reason) message(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " skip: ", label, " (", reason, ")")

# ---- chunk: convert-kp (qmd line ~72) ----
chunk_start("convert-kp")
<chunk body, verbatim, option lines stripped>

# ---- chunk: convert-kf (skipped: before --from convert-kpf) ----
chunk_skip("convert-kf", "before --from convert-kpf")

# Done ----------
message(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " done in ", round(difftime(Sys.time(), RUNNER_T0, units = "mins"), 1), " min")
```

- **Body stays unindented and outside `quote()`:** R's error message and `Execution halted` line then point at the runner line, and the monitor in `resource-watched-run` greps for `Execution halted`
- **`options(warn = 1)`:** warnings print as they happen next to the chunk that caused them, instead of piling up at the end

## The Generator

`runners/generate-runner.R` is responsible for:

- Reading the qmd line-by-line
- Detecting `{r}` chunk opens (` ```{r}` or ` ```{r ...}`) and `` ``` `` closes
- Lifting `#| label:` and `#| eval:` options out of each chunk header
- Resolving the working directory from the qmd YAML and baking it in as `setwd()`
- Debug: indenting the chunk body two spaces and wrapping it in `run_chunk(<label>, quote({ ... }))`
- Execute: emitting `chunk_start(<label>)` followed by the body verbatim
- Emitting one file at `<dirname(qmd)>/runners/<basename-without-ext>-debug.R` or `-execute.R`
- Being idempotent: re-running overwrites without prompting

Arguments:

```
Rscript runners/generate-runner.R [--mode debug|execute] [--all] [--from <label>] <qmd> [<qmd> ...]
```

| Argument | Effect |
|---|---|
| `--mode debug` | default; `tryCatch` runner, summary table |
| `--mode execute` | fail-fast runner with progress lines |
| `--all` | include chunks marked `#| eval: false` instead of skipping them (both modes) |
| `--from <label>` | execute only; chunks before `<label>` become skip lines. Errors if the label is missing or the mode is debug |

### Working directory resolution

Precedence, first hit wins:

1. `root.dir` in the qmd front matter (`knitr: opts_knit: root.dir: ".."`), resolved relative to the qmd's directory, as knitr does
2. `execute-dir` in the qmd front matter, else in the nearest `_quarto.yml` walking up from the qmd: `project` means the directory holding `_quarto.yml`, `file` means the qmd's directory
3. The qmd's directory

- The generator reads scalars with `^\s*root\.dir:\s*["']?([^"'#]+?)["']?\s*$` and no nesting tracking, since `root.dir` only ever appears under `knitr: opts_knit:`
- The resolved path and its source are written as `# Working directory: ...` at the top of the runner, so a wrong-directory failure is diagnosable from the first line
- Document-level `execute: eval: false` is ignored in both modes: it tells Quarto not to run chunks when rendering, which is exactly the case where a runner is needed. Chunk-level `#| eval: false` is still honoured unless `--all`

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
| `cannot open file 'read/...'` or `No such file or directory` in the **first** chunk | Working directory resolved to the wrong place | Read the `# Working directory:` comment at the top of the runner and compare with the qmd's `root.dir`; fix the YAML, not the runner |
| `Execution halted` mid-run in execute mode | Fail-fast did its job; the chunk named in the last `chunk:` line failed | Fix the qmd, regenerate with `--from <label>`, relaunch through `resource-watched-run` |

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
- **Gitignored**: every `<script-dir>/runners/<file>-debug.R`, `<file>-execute.R` and their `.log` files — these are derivative
- **Whitelist repos**: `!scripts/**` re-tracks `scripts/runners/`; add `scripts/runners/` after it (see R0)

## Common Mistakes

| Mistake | Fix |
|---|---|
| Running the debug runner to produce real outputs | Use `--mode execute`; debug mode continues past a failed chunk and later chunks run on partial outputs |
| Running an execute runner in the foreground with no `nice`, `time` or monitor | Launch through `resource-watched-run` |
| Editing the execute runner instead of the qmd | Fix the qmd and regenerate; the only sanctioned hand edit is trimming finished chunks to resume, and `--from` does that reproducibly |
| Editing the qmd and rerunning the stale runner | Regenerate after every qmd edit |
| `--from` at a chunk that needs in-memory state from an earlier chunk | Resume only where every input is on disk |
| Expecting `quarto render` to execute an `execute: eval: false` notebook | It renders prose only; use execute mode for the outputs |
| Trusting a `# Working directory:` that points at the wrong place | Fix `root.dir` or `execute-dir` in the YAML; the runner follows the YAML |

## Pairs Well With

- `resource-watched-run` — launches and monitors execute runners under `nice` and `/usr/bin/time`, and owns the kill protocol and post-run report
- `writing-r-code` — the per-chunk Libraries / Inputs / Processing / Outputs structure that this debugging loop assumes
- `writing-qmd-scientific` — hashpipe (`#|`) chunk options that the generator parses
- `creating-analysis-projects` — checkpoint-flow conventions that explain why downstream chunks fail when an upstream notebook has not been re-run
- `git-hygiene` — conventional commit format for the R3 fix-commits
