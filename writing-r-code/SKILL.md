---
name: writing-r-code
description: Use when writing, editing, or reviewing R code in any project. Use when working with Seurat, Bioconductor, tidyverse, scRNA-seq pipelines, or any R-based analysis. Use when generating code chunks for QMD documents, R scripts, or interactive sessions.
---

# Writing R Code

## Overview

Enforce a consistent R coding style: tidyverse-first idioms, Seurat v5 and Bioconductor ecosystem patterns, self-contained code chunks, and proactive Context7 MCP lookups to ensure all code matches current package APIs.

## Context7 MCP — Mandatory for Package Functions

Before writing any function call from a package that may have undergone API changes, **always** perform a Context7 lookup:

1. Call `resolve-library-id` with the package name
2. Call `query-docs` with the resolved library ID and the specific function or workflow

Apply this to every package in the ecosystem — not just Seurat. The following packages require proactive Context7 verification:

| Package | Common API-sensitive functions |
|---------|-------------------------------|
| Seurat | `CreateSeuratObject`, `SCTransform`, `NormalizeData`, `FindVariableFeatures`, `ScaleData`, `IntegrateLayers`, `RunPCA`, `RunUMAP`, `FindNeighbors`, `FindClusters`, `JoinLayers` |
| SeuratDisk | `SaveH5Seurat`, `Convert` |
| tidyseurat | Verify pipe-compatible dplyr verbs on Seurat objects |
| tidySingleCellExperiment | Verify tidy interface for SCE objects |
| SingleR | `SingleR`, `trainSingleR`, `classifySingleR` |
| scater | `isOutlier`, `perCellQCMetrics`, `addPerCellQCMetrics` |
| BadranSeq | `do_DimPlot`, `do_UmapPlot`, `do_PcaPlot`, `do_FeaturePlot`, `EnhancedElbowPlot`, `generate_badranseq_colors`, `theme_badranseq` |
| SCpubr | `do_DimPlot`, `do_ViolinPlot`, `do_DotPlot`, `do_FeaturePlot` — fallback only when BadranSeq lacks the needed plot type |
| ShinyCell2 | `createConfig`, `makeShinyApp`, `modColours` |
| harmony | `RunHarmony`, `HarmonyIntegration` |
| glmGamPoi | Verify integration with SCTransform |
| clustree | `clustree` resolution tree syntax |
| SingleCellExperiment | `as.SingleCellExperiment`, assay access patterns |
| readr | `read_rds`, `write_rds` — verify current argument names |

Do not guess function signatures. Verify first, write second.

## Core Principles

### Tidyverse-First

Prefer tidyverse idioms for all data manipulation:

- Use `dplyr` verbs: `filter()`, `mutate()`, `select()`, `group_by()`, `summarise()`
- Use the native pipe `|>` or magrittr pipe `%>%` consistently within a project
- Use `readr::read_rds()` and `readr::write_rds()` instead of base `readRDS()`/`saveRDS()`
- Use `tidyseurat` for Seurat object manipulation — enables dplyr verbs directly on Seurat objects
- Use `tidySingleCellExperiment` for SCE manipulation
- Prefer `purrr::map()` over `lapply()` when iterating

**tidyseurat scope and limitations:** `tidyseurat` enables dplyr verbs for **metadata operations** on Seurat objects — filtering cells, mutating metadata columns, grouping by metadata fields. Core Seurat pipeline functions (`SCTransform`, `RunPCA`, `RunUMAP`, `FindNeighbors`, `FindClusters`, `IntegrateLayers`) must use standard Seurat syntax. Do not attempt to pipe Seurat analysis functions through dplyr chains.

```r
# Correct — tidyseurat for metadata operations
seu <- seu %>%
  filter(nFeature_RNA > 200, nFeature_RNA < 5000) %>%
  mutate(log10GenesPerUMI = log10(nFeature_RNA) / log10(nCount_RNA))

# Correct — Seurat-native syntax for analysis functions
seu <- SCTransform(seu, vst.flavor = "v2")
seu <- RunPCA(seu, features = VariableFeatures(seu))
seu <- RunUMAP(seu, dims = 1:20)

# Incorrect — base R subsetting
seu <- seu[, seu$nFeature_RNA > 200 & seu$nFeature_RNA < 5000]
```

### Seurat v5 Patterns

- Use layer-based architecture when working with multi-sample data
- `JoinLayers()` before operations requiring merged data
- `IntegrateLayers()` for batch correction (CCA, RPCA, Harmony)
- `SCTransform()` with `vst.flavor = "v2"` as default normalization

### Bioconductor Conventions

- Use `scater::isOutlier()` for MAD-based QC (not fixed thresholds)
- Use `SingleR()` for reference-based annotation
- Convert to `SingleCellExperiment` via `as.SingleCellExperiment()` for Bioconductor workflows
- Store cell type labels in `sce$label` for SingleR compatibility

## Setup Chunk — One Per Script

**Every script opens with a single `setup` chunk** that declares what holds for the whole document: the `conflicted` preferences and every output directory the script writes to. These are **never** repeated in individual chunks.

```r
#| label: setup

# Libraries ----------
library(conflicted)

# Conflicts ----------
conflicts_prefer(
  dplyr::filter, dplyr::count, dplyr::rename, dplyr::slice,
  dplyr::first, dplyr::desc, dplyr::lag,
  purrr::reduce,
  base::intersect, base::setdiff, base::union, base::setequal,
  base::unname, base::as.factor, base::Position,
  .quiet = TRUE
)

# Output directories ----------
dir.create("../checkpoints", recursive = TRUE, showWarnings = FALSE)

dir.create("../write/figures/01-processing-pipeline",
           recursive = TRUE, showWarnings = FALSE)

dir.create("../write/tables/01-processing-pipeline",
           recursive = TRUE, showWarnings = FALSE)
```

Rules:

- **Placement**: after the `## Context` and `## Checkpoints` prose sections, before the first analysis section. Give it its own `## Setup` heading with the usual bullet prose
- **Visibility**: a normal, visible chunk. Do **not** use `include: false` — the conflict preferences are a methodological choice and belong in the rendered document
- **Conflicts**: declare the union of everything the script attaches anywhere, not just what the first chunk needs. `library()` calls accumulate across a session, so a later chunk sees conflicts its own library list does not explain. `conflicts_prefer()` registers for the session, so once is enough
- **Directories**: every directory any chunk writes to, listed once. `dir.create()` with `showWarnings = FALSE` is idempotent
- **`library(conflicted)` still appears in each chunk's library block.** The preference block does not, but the `library()` call does, so a chunk run without setup fails loudly on a masked verb rather than resolving it silently

## Self-Contained Code Chunks

Every code chunk must be independently executable **once the setup chunk has run**. Follow this pattern.

**Processing chunk** (writes a checkpoint — flat `checkpoints/` layout):

```r
# Libraries ----------
library(Seurat)
library(tidyseurat)
library(readr)
library(dplyr)

# Inputs ----------
seu <- read_rds("../checkpoints/01-dataset-seu-filtered.rds")

# Processing ----------
seu <- SCTransform(
  seu,
  vst.flavor = "v2",
  vars.to.regress = "percent.mt",
  variable.features.n = 3000,
  return.only.var.genes = FALSE,
  verbose = TRUE
)

# Outputs ----------
write_rds(seu, "../checkpoints/01-dataset-seu-normalised.rds")
```

**Visualisation chunk** (writes a figure — per-script subdir under `write/figures/`; chunk lives in `01-processing-pipeline.qmd`):

```r
# Libraries ----------
library(Seurat)
library(BadranSeq)
library(ggplot2)
library(readr)

# Inputs ----------
seu <- read_rds("../checkpoints/01-dataset-clustered.rds")

# Processing ----------
plot_umap <- do_UmapPlot(seu, group.by = "celltype")

# Outputs ----------
ggsave("../write/figures/01-processing-pipeline/01-umap-celltype.pdf",
       plot_umap, width = 8, height = 6, bg = "white")
```

Rules:
- **Libraries**: Declare all `library()` calls at the top of each chunk, `library(conflicted)` included. The `conflicts_prefer()` block lives in the setup chunk, never here
- **Inputs**: Load checkpoint or data files explicitly. No `dir.create()` — that is the setup chunk's job
- **Processing**: The analysis code
- **Outputs**: Save checkpoint to flat `../checkpoints/` OR write figures / tables to `../write/figures/<NN-script-slug>/` and `../write/tables/<NN-script-slug>/` (see `creating-analysis-projects` for the per-script subdir convention)

## Code Sectioning Style

Use this format for sections within code chunks. Code starts **directly** on the next line after the heading — **no blank line** between the heading and the code:

```r
# Section Name ----------
code_here()
```

Blank lines **between** sections are fine for visual separation:

```r
# Libraries ----------
library(Seurat)
library(readr)

# Inputs ----------
seu <- read_rds("../checkpoints/dataset_seu.rds")

# Processing ----------
seu <- NormalizeData(seu)

# Outputs ----------
write_rds(seu, "../checkpoints/dataset_seu_normalized.rds")
```

Do **NOT** use banner-style comments:

```r
# =============================================================================
# Section Name
# =============================================================================
```

## Checkpoint Naming Convention

| Checkpoint | Naming Pattern |
|------------|---------------|
| Raw Seurat object | `*_seu.rds` |
| After QC filtration | `*_seu_filtered.rds` |
| After normalization | `*_seu_normalized.rds` |
| SingleCellExperiment export | `*_sce.rds` |

## Visualization Patterns

**BadranSeq is the de-facto standard for scRNA-seq visualisation.** Use it first for all dimensionality reduction, feature expression, and elbow plots. This serves a dual purpose: producing publication-ready figures and actively testing/developing the package through real-world usage. Fall back to SCpubr or Seurat only when BadranSeq does not provide the needed plot type (e.g., violin plots, dot plots, heatmaps).

**Preference order:**
1. `BadranSeq` — UMAP, PCA, feature plots, elbow plots, split-panel silhouettes
2. `SCpubr` — violin plots, dot plots, heatmaps, and other plot types BadranSeq does not cover
3. `Seurat` — only if both BadranSeq and SCpubr lack the functionality or are failing

```r
library(BadranSeq)
library(patchwork)

# UMAP by cell type ----------
p1 <- do_UmapPlot(seu, group.by = "celltype")

# PCA with variance labels ----------
p2 <- do_PcaPlot(seu, dims = c(1, 2))

# Feature expression ----------
p3 <- do_FeaturePlot(seu, features = c("CD3D", "CD8A", "CD14"))

# Split-panel silhouette ----------
p4 <- do_UmapPlot(seu, split.by = "condition")

# Elbow plot ----------
p5 <- EnhancedElbowPlot(seu, ndims = 30, cutoff_pc = 10)

# Combine ----------
p_combined <- p1 | p2
ggsave("../write/figures/01-processing-pipeline/01-overview.pdf",
       p_combined, width = 16, height = 8, bg = "white")
```

**When to fall back to SCpubr/Seurat:**

| Plot Type | Package | Reason |
|-----------|---------|--------|
| UMAP, PCA, t-SNE | BadranSeq | `do_UmapPlot`, `do_PcaPlot`, `do_DimPlot` |
| Feature expression | BadranSeq | `do_FeaturePlot` |
| Elbow / variance | BadranSeq | `EnhancedElbowPlot` |
| Split-panel with silhouettes | BadranSeq | `do_UmapPlot(split.by = ...)` |
| Violin plots | SCpubr | `do_ViolinPlot` — not in BadranSeq |
| Dot plots | SCpubr | `do_DotPlot` — not in BadranSeq |
| Heatmaps | SCpubr | `do_EnrichedHeatmapPlot` — not in BadranSeq |
| Nebulosa density | SCpubr/Nebulosa | Not in BadranSeq |

### Alternative Views in Tabsets

- **When one question gets several plots** (per genotype, per contrast, a figure and its table, an overview and a zoom), put each in its own chunk inside a Quarto `panel-tabset` rather than stacking them or cramming them into one `patchwork` figure
  - Each tab chunk stays self-contained, sized and saved like any other figure chunk
  - Syntax and rules: `writing-qmd-scientific`, *Tabsets*

### Bulk RNA-seq and tabular data

BadranSeq's `do_*Plot` functions take Seurat objects, so for bulk RNA-seq, DESeq2 results, or any tibble of values, work in this order:

1. **Existing packages first**: `EnhancedVolcano` (volcano), `BadranSeq::do_GseaPlot` (GSEA bars), `enrichplot::gseaplot2` (running score), `ComplexHeatmap` (any heatmap), `ggstatsplot::ggbetweenstats` (group comparisons with a real *n*, such as hundreds of genes per group — not 3 replicates per line), `ggrepel` for labels
2. **ggplot2 from scratch** only when no package draws the plot you need (per-gene box + jitter panels with DESeq2 `padj` annotated, NES dot plots, LFC-vs-LFC scatters)
3. **Pair every marker claim with a plot and a table**: a statement that a gene is "high" or "low" in a group is backed by a per-sample box/violin/jitter panel *and* a table of means plus the test statistic. Never a heatmap alone

## Figure Sizing and Readability

**A squashed figure is a bug.** Every plot must be readable when saved and when rendered: no overlapping labels, no panels narrower than their content, no 6 pt text. This applies to the saved PDF, the chunk output in HTML, and images embedded in Word reports.

### Rules

- **Set the size on every figure chunk and every `ggsave()`**: never rely on the 7 × 5 in default. The chunk's `fig-width`/`fig-height` and the `ggsave(width, height)` carry the same numbers (or `ggsave` is larger), so the file and the rendered chunk match
- **Size by content, not by habit**:
  - Facet panels: at least 2.5 in wide and 2.2 in tall each (a 4 × 3 grid of panels is at least 10 × 7 in)
  - Heatmaps: 0.25–0.3 in per row plus 1.5 in for annotations and legends; wide when there are many columns
  - Bar and dot plots with long category labels: height = 0.35 in per category + 1.5 in
  - Volcano plots and PCA: 9 × 8 in or larger when labels are drawn
  - Use `limitsize = FALSE` in `ggsave()` for tall figures
- **Fonts are big**: `theme_*(base_size = 14)` minimum in notebooks; 15–16 in report figures that a page will scale down. Axis text ≥ 12 pt, strip text ≥ 13 pt bold, titles ≥ 16 pt. Legend keys sized to match (`legend.key.size = unit(1, "lines")` or larger)
- **One theme helper per project**, applied to every plot, so size and style are set once:

```r
theme_report <- function(base_size = 15) {
  theme_bw(base_size = base_size) +
    theme(
      panel.grid.minor = element_blank(),
      strip.background = element_rect(fill = "grey92", colour = NA),
      strip.text = element_text(face = "bold", size = base_size - 1),
      axis.text = element_text(size = base_size - 2),
      legend.position = "bottom",
      plot.title = element_text(face = "bold", size = base_size + 2)
    )
}
```

- **Long labels wrap, they never rotate 90°**: `scales::label_wrap(30)` on the axis or `stringr::str_wrap()` on the data. Use `ggrepel` for point labels with `max.overlaps = Inf` and check nothing is dropped
- **Word and PDF reports scale images to the text width (about 6.5 in)**: keep `fig-width` ≤ 9 and raise `base_size` to 15–16 so text is still ≥ 10 pt after scaling. A 14 in wide figure shrunk to 6.5 in has 7 pt text. Set `fig-dpi: 300` in the YAML so the embedded PNG stays sharp
- **Multi-panel figures get the full size they need**: with `patchwork`, add the panel sizes together rather than cramming two 9 in plots into one 9 in figure. Two volcano plots are two figures, not one
- **ComplexHeatmap** and other grid graphics: set `row_names_gp = gpar(fontsize = 12)`, `column_names_gp`, `row_title_gp` and `heatmap_legend_param = list(title_gp = gpar(fontsize = 13), labels_gp = gpar(fontsize = 12))` explicitly; the defaults are too small
- **Look at the output**: rasterise the saved PDF (`convert -density 60 file.pdf[0] file.png`) and read the image before declaring a figure done. If a label is cut, a panel squashed, or text unreadable, resize and re-render

### Pattern

```r
#| label: fig-marker-panels
#| fig-width: 10
#| fig-height: 7

plot_markers <- expr_df |>
  filter(symbol %in% markers) |>
  ggplot(aes(x = cell_line, y = log2_count, fill = cell_line)) +
  geom_boxplot(width = 0.6, outlier.shape = NA, alpha = 0.6) +
  geom_jitter(width = 0.15, size = 2.5, shape = 21, colour = "black") +
  facet_wrap(~ symbol, ncol = 4, scales = "free_y") +
  scale_fill_manual(values = line_colours) +
  labs(x = NULL, y = expression(log[2]("normalised count" + 1))) +
  theme_report()

ggsave("../write/figures/04-results-report/04-marker-panels.pdf",
       plot_markers, width = 10, height = 7, bg = "white", limitsize = FALSE)

plot_markers
```

## Common Mistakes

| Mistake | Correct Approach |
|---------|-----------------|
| Using base R subsetting on Seurat objects | Use tidyseurat with dplyr verbs for metadata operations |
| Piping Seurat analysis functions through dplyr | Use Seurat-native syntax for `SCTransform`, `RunPCA`, `FindClusters`, etc. |
| Using `readRDS()`/`saveRDS()` | Use `readr::read_rds()`/`readr::write_rds()` |
| Hardcoding QC thresholds | Use `scater::isOutlier()` with MAD |
| Skipping Context7 for known functions | Always verify — APIs change between versions |
| Using `lapply` for iteration | Prefer `purrr::map()` family |
| Forgetting `JoinLayers()` before merge operations | Check layer state with `Layers(seu)` first |
| Not saving checkpoints after major steps | Every pipeline stage gets a checkpoint |
| Using SCpubr/Seurat for plots BadranSeq can handle | BadranSeq first — SCpubr/Seurat only as fallback |
| `ggsave("../write/figures/foo.pdf", …)` fails with `Cannot find directory` | The setup chunk must `dir.create()` every output directory the script writes to; outputs land in per-script subdirs (see `creating-analysis-projects`) |
| Repeating `conflicts_prefer()` or `dir.create()` in every chunk | Both belong in the one `setup` chunk at the top of the script. Repeating them is the boilerplate that buries the analysis |
| Putting the setup chunk behind `include: false` | Keep it visible — conflict handling is a methodological choice, not boilerplate to hide |
| Saving figures flat under `write/figures/` | Use the per-script subdir `write/figures/<NN-script-slug>/<NN-name>.pdf`; same for `write/tables/`. Checkpoints stay flat in `checkpoints/`. |
| Figure chunk or `ggsave()` without explicit size, or a 12-panel facet at 7 × 5 in | Set `fig-width`/`fig-height` and `ggsave(width, height)` on every figure, sized by content (see *Figure Sizing and Readability*) |
| Default theme font sizes (11 pt) in saved or report figures | `base_size = 14` minimum, 15–16 for report figures that get scaled to page width |
| Two full-size plots crammed side by side into one figure | Give each its own figure, or sum the widths |
| Rotated 90° axis labels | Wrap with `scales::label_wrap()` / `str_wrap()` and widen the figure |
| Declaring a figure done without looking at it | Rasterise the PDF and read it; fix squashed panels, cut labels or tiny text before moving on |
| A marker "is high in X" stated from a heatmap or from memory | Back it with a per-sample box/jitter panel and a table of means with the test statistic |
