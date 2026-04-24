---
name: hugo-blog
description: Use when adding, editing, or publishing blog posts on the Hugo personal site at badran-elshenawy.netlify.app. Use when creating new series posts, rendering R Markdown to markdown, updating the README, or committing and pushing content. Applies to all work in the my_website repository.
---

# Hugo Blog

## Overview

Hugo personal blog for Badran Elshenawy, deployed on Netlify at badran-elshenawy.netlify.app. Posts are authored in R Markdown (`.rmd`), rendered to `.md` via hugodown, and auto-deployed on push to `main`. The site uses the Coder theme (git submodule — never edit `themes/Coder/` directly).

---

## Dual-file pattern

Every post exists as **two committed files**:

| File | Role |
|---|---|
| `content/posts/{name}.rmd` | Source of truth — edit this |
| `content/posts/{name}.md` | Generated output — never edit directly |

The `.md` is always produced by rendering the `.rmd`. If you edit the `.md` directly, it will be overwritten on the next render.

---

## File naming

Use `{series_name}_part_{NN}.rmd` with underscores and zero-padded numbers:

- `tidyverse_to_scverse_part_01.rmd`
- `scrna_seq_series_part_15.rmd`
- `claude_series_part_08.rmd`
- Standalone posts: `my_first_post.rmd`, `vs_code_quarto_visual_mode.rmd`

New series start at `_part_01`. Always check existing posts in `content/posts/` to confirm the next number in a series.

---

## Front matter (YAML)

Required fields — always use `---` delimiters:

```yaml
---
title: "Series Name – Post N: Subtitle"
author: "Badran Elshenawy"
date: 2026-01-01T09:00:00Z
categories: [...]
tags: [...]
description: "..."
slug: "url-friendly-slug"
draft: false
output: hugodown::md_document
aliases:
  - /posts/slug_with_underscores/
summary: "..."
featured: true
---
```

- `rmd_hash` is added automatically by hugodown on render — do not write it manually
- `aliases` uses underscores; `slug` uses hyphens
- Dates use ISO 8601 with time: `2026-04-24T09:00:00Z`

---

## Workflow for adding a post

### 1. Apply md-format

Before writing or placing any `.rmd`, invoke the `md-format` skill to catch formatting issues — especially missing blank lines before bullet lists.

### 2. Create the .rmd

Place it at `content/posts/{series_name}_part_{NN}.rmd` with correct YAML front matter.

### 3. Render to .md

```bash
Rscript -e 'rmarkdown::render("content/posts/filename.rmd", output_format = hugodown::md_document())'
```

Run from the repo root. The `.md` is written to the same directory as the `.rmd`.

### 4. Update README.md

Before every push, update `readme.md` in the repo root:

- Increment the post count for the relevant series in the series table
- If it's a new series, add a row to the table
- Increment the total post count in the "X+ posts" line

**Never push without checking README is in sync.** It's fine for intermediate local commits to be out of sync, but not at push time.

### 5. Commit

Lowercase commit messages in the format `{series} post {N}: {topic}`:

```
tidyverse to scverse post 1: why i'm making the switch to python
pseudotime series post 6: choosing methods and troubleshooting
claude series post 14: capstone retrospective
```

Stage both the `.rmd` and `.md`, plus `readme.md` if updated:

```bash
git add content/posts/filename.rmd content/posts/filename.md readme.md
git commit -m "series name post N: topic"
```

### 6. Push

```bash
git push
```

Netlify auto-deploys on push to `main`. No manual deploy step needed.

---

## Development commands

```bash
hugo server -D    # local dev with drafts visible
hugo server       # local dev without drafts
hugo              # production build → public/
```

---

## README series table

The `readme.md` tracks all series. Format:

```markdown
| Series | Posts | Topics |
|--------|-------|--------|
| **Series Name** | N | Brief topic description |
```

When adding the first post of a new series, add a new row. When adding subsequent posts, increment the count for that row.

---

## Common mistakes

| Mistake | Fix |
|---|---|
| Editing the `.md` directly | Always edit the `.rmd` and re-render |
| Forgetting to render after editing `.rmd` | Run the Rscript render command before committing |
| Pushing without updating README | Check series count and total post count first |
| Wrong date format | Use `2026-04-24T09:00:00Z` — ISO 8601 with time and Z |
| Editing `themes/Coder/` | Never — it's a git submodule; changes will be lost |
| Using hyphens in filenames | Use underscores: `tidyverse_to_scverse_part_01.rmd` |
| Missing blank line before bullet list in .rmd | Apply `md-format` before rendering — pandoc will collapse the list |
| Committing only the `.rmd` without the `.md` | Stage both files together |
