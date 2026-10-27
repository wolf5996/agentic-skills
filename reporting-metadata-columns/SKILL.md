---
name: reporting-metadata-columns
description: Use when documenting, describing, auditing or presenting the metadata columns of a Seurat object (or SingleCellExperiment, AnnData obs, or any per-cell table) as a reference report. Triggers include "list the metadata columns", "describe the columns in the object", "update the metadata summary", "which columns did I add vs the provider", "make a column dictionary / data dictionary / codebook for the Seurat object", a collaborator or core facility delivering a metadata report (e.g. a `Metadata_Summary.md` or Rmd with coloured category pills) that needs extending with the analyst's own columns, or checking that every column in a checkpoint is documented. Produces a lettered Quarto notebook outside the numbered pipeline that detects columns programmatically from each object, splits them into provider vs analyst columns, assigns a category and data type, renders colour-coded HTML cards with live summaries, groups families of score columns (AddModuleScore, ssGSEA, CoRAL), writes a registry CSV, and flags undocumented, missing and pending columns. Use even when the user only asks for "an updated list of columns" or "a table of what each column means".
---

# Reporting Metadata Columns

## Overview

- **Problem**: a delivered single-cell object comes with a metadata report written by the provider, then the analyst's notebooks add columns of their own
  - The report goes stale the moment the first analyst column lands
  - Nobody can tell which columns came from whom, what each one means, or whether a column in the object was ever described
- **Solution**: one lettered notebook (`A-metadata-columns.qmd`) that rebuilds the column reference from the objects every time it renders
  - **Detection is programmatic**: column lists come from the objects; only the descriptions are written by hand
  - **Two sections**: provider columns (the delivered object) and analyst columns (anything a checkpoint adds)
  - **Same visual language as the provider report**: category and data-type pills, colour-coded cards
  - **Honesty checks**: undocumented, missing and pending columns are flagged, so the registry cannot silently drift from the objects
- **Bundled files**:
  - `references/render-metadata-cards.R`: the HTML card renderer, paste it into the notebook
  - `assets/metadata-columns-template.qmd`: a runnable notebook skeleton with `<PLACEHOLDER>`s

## When to Use

- A provider (collaborating lab, core facility, consortium) delivered an object plus a column report, and the analyst wants it extended "the same way, but split into theirs and mine"
- Before a presentation, handover, paper submission or ShinyCell app, when someone will ask "what does this column mean"
- After a pipeline step adds columns (annotation cleanup, module scores, CNV calls) and the column reference must catch up
- Auditing a checkpoint for columns nobody documented

## When NOT to Use

- Describing assays, reductions or gene-level features: this skill covers per-cell metadata only (mention the assays in prose, do not card them)
- A one-off "what columns are in this object" question: `names(seu[[]])` answers it; build the report when the answer must persist or be shared
- Cluster marker tables, DE results or other analysis outputs

## The Notebook Is Lettered, Not Numbered

- **Name**: `scripts/A-metadata-columns.qmd`, next to the numbered chain (`01-`, `02-`, ..., `99-`)
  - Letters sort before or after numbers and signal "reference document, not a pipeline step"
- **Why outside the chain**: it reads every checkpoint, so placing it at any number would imply an ordering it does not have
  - No numbered notebook may read anything it writes; its own snapshot cache and registry CSV are leaves
- **Re-render** whenever a numbered notebook writes a new checkpoint; the notebook reports `pending` columns until then
- **Conventions**: copy the YAML, `## Context` / `## Checkpoints` / `## Setup` structure and chunk layout from the project's own numbered notebooks (see `writing-qmd-scientific`, `writing-r-code`)

## Taxonomy

Two descriptors per column, as in the Kleinman-lab style report this skill was built from. Reuse the provider's own categories and hex codes when they have them; these are the defaults:

| Descriptor | Value | Colour | Meaning |
|---|---|---|---|
| Category | Sample metadata | `#2e7d32` | Properties of the sample, not the cell (sample ID, genotype, sex) |
| Category | QC metrics | `#5c3d8f` | Cell-level quality measures (counts, features, percent mito, doublet scores) |
| Category | Cell state & classification | `#8F3D70` | Computed states and calls (phase, clusters, CNV, malignancy, GFP status) |
| Category | Raw cell annotation | `#37474f` | Per-reference annotations and scores before integration |
| Category | Imputed cell annotation | `#90a4ae` | Integrated or refined final labels |
| Category | Signature scores | `#00838f` | Per-cell gene set scores (added for analyst score columns) |
| Category | Unassigned | `#757575` | Automatic, for undocumented columns |
| Data type | categorical | `#378ADD` | Labels, groups, IDs, clusters (even when stored as integers) |
| Data type | continuous | `#D85A30` | Numeric measurements and scores |

- **Adding a category**: only when a new family of columns fits none of the existing ones; give it a colour distinct from the rest and add it to the legend by adding it to `default_category_colours`
- **Type is declared, not inferred**: `seurat_clusters` is categorical though it may be stored as a factor of numbers; the declared type picks the summary (level counts vs min/median/max)

## Workflow

### 1. Read the provider report in full

- Transcribe every entry into a `tribble` of `name, category, type, description`
  - Keep the provider's wording; drop HTML emphasis; fix only obvious typos and say so in the prose
  - Map their category keys (`cell_annotation`, `Imputed_Cell_Annotation`, `qc`) to display names
- If their report calls a helper that is not available (a cluster-only `source()`), that is why the renderer is re-implemented here

### 2. Snapshot the metadata, one object at a time

- `sources`: one row per object in pipeline order: `stage, notebook, path`
  - `delivered` first, then each numbered Seurat checkpoint
  - The first source holding a column is credited with adding it; this is how provider vs analyst is decided
  - Missing files are skipped, so the notebook runs before a slow upstream notebook finishes
- Read each object with `readr::read_rds`, keep `as_tibble(seu[[]], rownames = ".cell")`, then `rm()` and `gc()` before the next
- Cache as `../checkpoints/A-metadata-snapshot.rds`, reused while every source's `exists` and modification time are unchanged
  - Rebuilds automatically when a checkpoint is rewritten
  - Guard the write: stop if no source exists, so a mis-pathed `sources` table cannot replace a good cache with an empty one
- **Memory**: plan with `resource-watched-run`, but expect less than a full analysis session
  - Measured: three uncompressed rds files (1.7, 2.9 and 0.7 GB, read in turn) peaked at 3.4 GB RSS in 13 s
  - gzip-compressed objects take longer and peak higher; serialise this with any other heavy job

### 3. Build the registry

The `column-registry` chunk in the template does all of this; adapt the tables, not the logic.

- **Provider registry**: the transcription from step 1, `description_source` = the report file
- **Spelling fixes** (`report_name_fixes`): report name, object name, evidence
  - Case drift is common (`Cell_Subtype_X` in the report, `Cell_subtype_X` in the object)
  - When names differ more, match by evidence such as column position (a `_score` column directly after its label column) and write that evidence into the note
- **Provider extras** (`provider_extra`): delivered columns the report omits, described by the analyst and marked `description_source = "this notebook"`
  - Typical case: Seurat adds `nCount_<assay>` and `nFeature_<assay>` when an assay is created with a counts layer, so score assays stored that way (CoRAL in the worked example) leave two undocumented columns each
  - Assays created with `data =` only (escape, `CreateAssayObject(data = ...)`) do not add them
- **Analyst registry**: `name, category, type, added_in, description`
  - `added_in` names the notebook expected to add the column; it is what turns "absent" into `pending` rather than `missing`
  - Describe the rule that built the column, not just its content (which cells were reset, which suffix means what)
- **Families**: `family` (a prefix), `category`, `type`, `added_in`, `description`
  - Members are `prefix + expected names` (e.g. pathway names from a gene-set checkpoint) united with any observed column matching the prefix, so an extra member is never hidden and a missing one is visible
  - Use for any repeated block: `AMS_<PATHWAY>`, `ssGSEA_<PATHWAY>`, per-reference CoRAL scores, per-resolution clusters
- **Live summaries** from the first source holding the column, following the declared type
  - Categorical: number of levels and the three largest levels with counts; "every value unique" for ID columns
  - Continuous: min, median, max over finite values
  - NA count for both

### 4. Status rules

| Status | Condition | Action |
|---|---|---|
| `documented` | described and present | none |
| `undocumented` | present in an object, no registry row | add a registry row (type is inferred from class meanwhile) |
| `missing` | described, absent, and its source notebook's checkpoint exists | the column was renamed or dropped; fix or remove the row |
| `pending` | described, absent, its notebook has not written its checkpoint | re-render later |

- **Notes** (`note` column) keep documented deviations visible: spelling fixes, analyst-written descriptions of provider columns, a continuous column stored as character, a delivered column dropped by a later checkpoint

### 5. Registry CSV

`write/tables/A-metadata-columns/A-metadata-columns.csv`, one row per column, family members included:

| Column | Content |
|---|---|
| `provider`, `name`, `family` | who added it; column name; family prefix or empty |
| `category`, `type`, `description`, `description_source` | taxonomy and text; source is the report file or "this notebook" |
| `added_in` | notebook (or delivery) whose object first holds the column |
| `status`, `present`, `in_latest`, `note` | honesty checks |
| `class`, `n_cells`, `n_na`, `n_levels`, `top_levels`, `min`, `median`, `max` | live summary |

- Read it back with explicit `col_types` in the card chunks: a column that is all empty for one provider is otherwise guessed as logical

### 6. Render the cards

- Paste `references/render-metadata-cards.R` into a `card-renderer` chunk after `setup`
  - It is the one shared chunk besides `setup`; document that in its prose
- One chunk per section, `#| output: asis`, each reading the registry CSV and calling `render_metadata_cards()`, then `cat()`
  - `supplier = "<provider>"` adds a "description added here" pill to provider cards whose text the analyst wrote
- The renderer returns a ```` ```{=html} ```` raw block, because pandoc re-parses indented HTML in asis output as code blocks
- Cards use translucent greys so they read in both `darkly` and `cosmo`; family cards span the full width with a collapsible member table
- Finish with a `registry-checks` chunk: a `kable` of every non-documented or noted row, families collapsed to one row

### 7. Run, render, verify

- `qmd-runner` debug runner until every chunk is PASS, launched through `resource-watched-run` the first time (the snapshot build is the heavy part)
- `quarto render A-metadata-columns.qmd -M eval:true` from `scripts/`
- Verify, do not assume:
  - Simulate an absent optional checkpoint against a scratch copy of the snapshot and confirm its columns read `pending`, not `missing`
  - Screenshot the HTML (headless Chrome: `--headless=new --screenshot --window-size=1500,16000`) and look at it
  - Run any template or experiment from a scratch project tree, never from `scripts/`: a stray run of the snapshot chunk with other `sources` overwrites the real cache

## Worked Example

- An EZHIP mouse glioma project used this pattern: `scripts/A-metadata-columns.qmd` beside `01-annotation-qc.qmd`, `02-signature-scoring.qmd`, `99-shinycell-app.qmd`
  - **Provider**: Kleinman lab `Metadata_Summary.md`, 56 described columns; the delivered object held 62
  - **Found by the checks**: two report names with case or name drift (`Cell_Subtype_Braindex_CAWPE`, `..._score`) and six `nCount_`/`nFeature_` columns for the three CoRAL assays, all undescribed in the report
  - **Analyst columns**: six `_BE` cleanup columns from 01 and two 50-member families (`AMS_<PATHWAY>`, `ssGSEA_<PATHWAY>`) from 02 under a new "Signature scores" category
  - Before 02 finished, the 100 score columns rendered as `pending` and the report was still usable

## Common Mistakes

| Mistake | Fix |
|---|---|
| Hand-typing the column list | Detect columns from the objects; hand-write descriptions only |
| A card per score column (100 near-identical cards) | Describe a family once, list members in a collapsible table |
| Numbering the notebook into the pipeline | Lettered name; nothing downstream reads its outputs |
| Treating an absent column as an error before its notebook ran | `added_in` plus the available sources gives `pending` |
| Silently renaming a provider column to match the object | `report_name_fixes` with evidence, shown as a note |
| Describing a provider column without saying who wrote the text | `description_source = "this notebook"` and the "description added here" pill |
| Inferring categorical vs continuous from the R class | Declare the type; integers can be cluster IDs |
| Reading every object at once | One at a time, `rm()` + `gc()`, cached snapshot |
| `cat()`-ing raw HTML into an asis chunk | Wrap in a ```` ```{=html} ```` block |
| `read_csv` guessing types per section | Explicit `col_types` |
| Testing a template inside the real `scripts/` | Use a scratch project tree with a copy of the snapshot |

## Pairs Well With

- `writing-qmd-scientific` and `writing-r-code`: YAML, bullet-only prose, chunk structure, setup chunk
- `qmd-runner`: debug runner until green
- `resource-watched-run`: launching the snapshot build when objects are large
- `md-format`: blank lines before lists in the prose
- `creating-analysis-projects`: where `read/`, `checkpoints/` and `write/tables/<script>/` live
