---
name: writing-qmd-scientific
description: Use when creating or editing Quarto (.qmd) documents for scientific analysis. Use when writing analysis pipelines, bioinformatics workflows, or scientific notebooks. Use when structuring code chunks with surrounding documentation, rationale, or methodology descriptions.
---

# Writing QMD Scientific Documents

## Overview

- **Goal**: Structure Quarto documents as self-documenting scientific pipelines
- **Every section** combines bullet-point explanations (rationale, methodology, justification) with self-contained code chunks
- **Reader experience**: any reader can jump to any section, understand why each step exists, and run it independently

## Document YAML Header

```yaml
---
title: "Dataset Reference Creation"
author: "Badran Elshenawy"
date: today
format:
  html:
    theme:
      dark: darkly
      light: cosmo
    toc: true
    toc-depth: 3
    code-fold: true
    code-tools: true
    embed-resources: true
    self-contained: true
    title-block-banner: true
engine: knitr
execute:
  eval: false
  warning: false
  message: false
---
```

- **Theme**: always dark by default. `dark: darkly` is listed first so it loads first; `light: cosmo` is the toggle. Never use a light-only theme

## Section Structure

### Heading Convention

- Use descriptive section and subsection headers without numbering:

```markdown
## Data Import
### Loading Raw Data
### Metadata Extraction

## Quality Control
### QC Metric Calculation
### MAD-Based Outlier Detection
### Filtration
```

### Prose Format — Bullet Points Only, No Paragraphs

**CRITICAL: All explanatory text outside code chunks MUST be bullet points.** Never write paragraph prose. Every piece of information is a bullet. Related details are sub-bullets. This is non-negotiable.

- **Format**: Bold key term on the top-level bullet, then sub-bullets for details
- **No paragraphs**: Do not write sentences that flow as paragraphs — break every thought into a bullet
- **Nesting**: Further points relating to the same idea become sub-bullets (indent one level)
  - Sub-sub-bullets are fine for additional depth
- **One idea per bullet**: Each bullet conveys a single point

```markdown
## Quality Control and Filtration

- **Purpose**: Quality control using MAD-based outlier detection and adaptive threshold filtration
- **QC approach**: MAD-based (Median Absolute Deviation) outlier detection
  - More robust than fixed thresholds for datasets with unknown distributions
  - Adapts to the specific characteristics of the dataset
  - Uses `scater::isOutlier()` with `nmads = 3` on log-transformed values
- **Metrics assessed**:
  - `nCount_RNA`: Total UMI counts per cell (library size)
  - `nFeature_RNA`: Number of detected genes per cell
  - `percent.mt`: Mitochondrial gene percentage (cell stress indicator)
- **Filtration method**: `tidyseurat` + `dplyr::filter()` for readable syntax
- **Rationale for MAD over fixed thresholds**:
  - Fixed thresholds (e.g., >200 genes) are arbitrary and dataset-dependent
  - MAD thresholds are statistically principled and reproducible
```

Rules for prose:
- **No paragraphs** — every explanation is bullet points, always
- Every methodological choice must have a **justification** (as a sub-bullet)
- Use nested bullet points for detail (bold key term → explanation → rationale)
- Include package and function names in backticks
- Reference specific parameters and their values
- If you catch yourself writing a sentence that isn't a bullet, convert it to one

### Code Chunk Options

- **All chunk options** must use the `#|` (hashpipe) syntax on separate lines inside the chunk
- **Never** place options inside the `{r}` header (e.g., `{r label="quality-control"}` is wrong)

```markdown
# Correct — hashpipe syntax
```{r}
#| label: quality-control
#| eval: false
#| fig-width: 10

# Incorrect — options inside curly braces
```{r label="quality-control", eval=FALSE, fig.width=10}
```

- **Naming**: hashpipe options use kebab-case (`fig-width`, `fig-height`, `fig-cap`) rather than legacy dot-separated names (`fig.width`)

### Figure Chunks

- **Every chunk that prints a plot sets `fig-width` and `fig-height`**: the 7 × 5 in default squashes anything with facets, long labels or a legend. Size by content (see `writing-r-code`, *Figure Sizing and Readability*)
  - The same numbers go into the chunk's `ggsave()` so the saved PDF matches what the document shows
- **Document-level defaults** go in the YAML so a forgotten chunk is still readable, and so `ragg_png` is used (compute nodes have no X11):

```yaml
knitr:
  opts_chunk:
    dev: ragg_png
    fig-width: 9
    fig-height: 6.5
    fig-dpi: 300
```

- **Word reports (`format: docx`)** scale images to the text width, about 6.5 in: keep `fig-width` ≤ 9 and set theme `base_size` to 15–16 so text stays ≥ 10 pt after scaling. Never place two full-size plots side by side in one figure; make two figures
- **Captions and cross-references**: label figure chunks `fig-<name>` with a `fig-cap`, tables `tbl-<name>` with a `tbl-cap`, and refer to them in prose as `@fig-name` / `@tbl-name`
- **Check the render**: open the rendered figure (or rasterise the saved PDF) before declaring the chunk done

```markdown
```{r}
#| label: fig-marker-panels
#| fig-cap: "Lineage markers per sample. Log2 normalised counts; boxes show the three replicates of each line."
#| fig-width: 10
#| fig-height: 7
```

### Setup Chunk

- **Every document opens with one `setup` chunk** under its own `## Setup` heading, placed after the `## Context` and `## Checkpoints` prose and before the first analysis section
- **It holds**: `library(conflicted)`, the `conflicts_prefer()` block, and a `dir.create()` for every output directory the document writes to
- **Nothing else repeats them.** Individual chunks keep `library(conflicted)` in their library block but never redeclare the preferences or create directories
- **Visible, not hidden** — no `include: false`. The conflict handling is a documented choice like any other
- See `writing-r-code` for the full template and the reasoning

### Code Chunks

- **Code chunks** are self-contained units, given that `## Setup` has run
- **Pattern**: follows the `writing-r-code` skill (Libraries → Inputs → Processing → Outputs)
- **Internal formatting**: `# Section ----------` separators

````markdown
```{r}
#| label: quality-control

# Libraries ----------

library(Seurat)
library(tidyseurat)
library(scater)
library(readr)
library(dplyr)

# Inputs ----------

seu <- read_rds("../checkpoints/dataset_seu.rds")

# Calculate QC metrics ----------

seu[["percent.mt"]] <- PercentageFeatureSet(seu, pattern = "^MT-")
seu[["percent.ribo"]] <- PercentageFeatureSet(seu, pattern = "^RP[SL]")

# MAD-based outlier detection ----------

seu <- seu %>%
  mutate(
    outlier_count = isOutlier(nCount_RNA, nmads = 3, log = TRUE),
    outlier_feature = isOutlier(nFeature_RNA, nmads = 3, log = TRUE),
    outlier_mt = isOutlier(percent.mt, nmads = 3, type = "higher")
  )

seu$outlier <- seu$outlier_count | seu$outlier_feature | seu$outlier_mt

# Filtration ----------

seu_filtered <- seu %>%
  filter(!outlier)

# Outputs ----------

write_rds(seu_filtered, "../checkpoints/dataset_seu_filtered.rds")
```
````

### Post-Code Elements

- **After code blocks**, include parameter tables and result summaries:

**Parameter tables:**

```markdown
| Parameter | Value | Justification |
|-----------|-------|---------------|
| `nmads` | 3 | Standard threshold; captures 99.7% of distribution |
| `log` | TRUE | Log-transform stabilizes variance for count data |
| `type` | "higher" | For percent.mt, only high values indicate poor quality |
```

**Result summaries:**

```markdown
**Filtration Summary:**
- Cells before: ~18,000
- Cells after: ~15,000
- Cells removed: ~3,000 (~17%)
```

### Tabsets

- **Alternative views of one result go in a tabset**, not stacked down the page: the figure and the table of the same numbers, one tab per genotype, contrast or sample, an overview and a zoom
  - The section stays one screen long and the reader picks the view
- **Syntax**: a `panel-tabset` div; each heading one level below the section heading inside it becomes a tab

````markdown
## Composition Per Tumour

- **Rationale and findings bullets stay here, above the tabset**

::: {.panel-tabset}
### Figure

```{r}
#| label: fig-composition
#| fig-cap: "Cells per tumour by cell type, split by the malignant call."
#| fig-width: 12
#| fig-height: 7.5
```

### Table

```{r}
#| label: tbl-composition
#| tbl-cap: "Cells per tumour and malignant call."
```
:::
````

- **Rules**:
  - Prose stays above the div, never inside one tab only, so it is read whichever tab is open
  - Every tab's chunk follows the usual rules: self-contained, labelled `fig-`/`tbl-` with a caption, explicit `fig-width`/`fig-height`, saved to `write/`
  - Tab headings are short nouns: "Figure", "Table", "EZHIPp53 vs KP"
  - `::: {.panel-tabset group="contrast"}` synchronises every tabset with the same `group`: choosing "vs KPP" in one switches them all
  - One level of tabs only; no tabset inside a tab
  - **HTML only**: `docx` and `pdf` render the tabs as consecutive sections, so a Word report still shows every tab

### Findings Boxes and the Summary of Findings

- **Every analysis section states its findings in a box**: after the rationale bullets and before the chunks and tabsets, a `callout-tip` titled "Findings" with one bullet per result
  - Bold claim first, then the numbers: what the section found, not what it did
  - Numbers come from the rendered tables; write the box after the chunks have run and the figures have been looked at
- **The document ends with `## Summary of Findings`**: a numbered list, one item per finding across all sections, each ending with the `@fig-` or `@tbl-` that backs it. This is the list the reader goes through
- **Code is folded by default**: `code-fold: true` with `code-tools: true` in the YAML; the `</> Code` menu at the top shows or hides all code

```markdown
## Composition Per Tumour

- **Malignant call first**: rationale bullets as usual

::: {.callout-tip title="Findings"}
- **8006_KPP has no malignant cells** (785 normal cells), so KPP has two tumour replicates
- **GFP would lose 8–16 % of EZHIP malignant cells**: the `malignant` column, not GFP, defines tumour cells
:::

(chunks and tabsets)

## Summary of Findings

1. **KPP has two tumour replicates, not three**: 8006_KPP has no malignant cells (@fig-malignant-call)
2. **GFP is the wrong gate for EZHIP tumours** (@fig-gfp)
```

## Table Usage Patterns

- **Tables** serve specific roles in QMD documents:

| Table Type | When to Use | Example |
|------------|-------------|---------|
| Sample information | Dataset overview sections | Donors, cells, platform |
| Parameter explanation | After every code block with tunable parameters | Parameter, Value, Justification |
| QC thresholds | After MAD-based outlier detection | Metric, Lower, Upper, Cells Removed |
| Cell type distribution | After annotation | Cell Type, Count, Proportion |
| Results comparison | When comparing methods or datasets | Method, Metric, Result |
| Version information | Technical notes section | Package, Version |

## Checkpoint Pattern

- **Each major pipeline stage** produces a checkpoint
- **Document** the naming convention at the start of the QMD:

```markdown
## Checkpoint Convention

| Stage | File | Description |
|-------|------|-------------|
| Import | `*_seu.rds` | Raw Seurat object |
| QC | `*_seu_filtered.rds` | After cell/gene filtration |
| Normalization | `*_seu_normalized.rds` | After normalization + dim reduction |
| Export | `*_sce.rds` | SingleCellExperiment for SingleR |
```

## Directory Structure

- **QMD documents** assume this project layout (see `creating-analysis-projects` for the canonical definition):

```
project_name/
├── read/                          # Raw input data
├── scripts/                       # QMD files, R scripts, .Rproj (git root)
├── checkpoints/                   # FLAT — every notebook reads upstream rds files
│   ├── 01-merged-harmony.rds
│   └── 02-annotated.rds
└── write/                         # PER-SCRIPT SUBDIRECTORIES
    ├── figures/
    │   ├── 01-processing-pipeline/
    │   │   └── 01-umap-celltype.pdf
    │   └── 02-tables-visualisations/
    │       └── 02-condition-marker-heatmap.pdf
    ├── tables/
    │   ├── 01-processing-pipeline/
    │   │   └── 01-qc-summary.csv
    │   └── 02-tables-visualisations/
    │       └── 02-condition-markers-significant.csv
    └── apps/                      # ShinyCell2 apps (per-script subdirs too)
```

- `figures/` and `tables/` subdirectories are named after the qmd basename (without `.qmd`); files inside still carry the matching `NN-` step prefix
- `checkpoints/` stays flat — downstream notebooks all read upstream checkpoints, so subdirs would obscure the shared-state nature
- The `setup` chunk `dir.create()`s every output directory the document writes to, once. Individual chunks never create directories

- **Relative paths** in code always reference from `scripts/`:
  - Input data: `../read/`
  - Checkpoints: `../checkpoints/`
  - Figures: `../write/figures/`

## Common Mistakes

| Mistake | Correct Approach |
|---------|-----------------|
| Code chunk that depends on previous chunk's state | Each chunk loads its own checkpoint. The one allowed dependency is the `setup` chunk |
| Repeating `conflicts_prefer()` or `dir.create()` in every chunk | Both live in the single `setup` chunk at the top of the document |
| No rationale for parameter choices | Every parameter gets a justification |
| Writing paragraphs outside code chunks | **Always use bullet points** — no paragraph prose, ever |
| Prose that describes what the code does | Prose explains **why** — the code shows what |
| Numbered section headings | Use descriptive headers without numbers — let the TOC handle navigation |
| Flat bullet points without hierarchy | Use nested bullets: bold term → detail → rationale |
| Tables without context | Introduce every table with a sentence explaining its purpose |
| Several plots of the same result stacked down the page | One `panel-tabset`, one tab per view, the prose above the div |
| Results left for the reader to dig out of figures and tables | A Findings box per section and a numbered Summary of Findings at the end |
| Chunk options inside `{r ...}` | Use `#|` hashpipe syntax on separate lines inside the chunk |
| Dot-separated option names (`fig.width`) | Use kebab-case (`fig-width`) with hashpipe syntax |
| Figure chunk without `fig-width`/`fig-height` | Set both on every figure chunk, sized by content; defaults squash facets and labels |
| A biological claim in prose with no figure or table behind it | Every statement about a gene, marker or pathway points at a `@fig-` or `@tbl-` that shows it |
