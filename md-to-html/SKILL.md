---
name: md-to-html
description: Use when converting a markdown file produced by Claude into a rendered self-contained HTML document via Quarto. Triggers include requests to render md to html, convert markdown output to a polished document, or produce a shareable HTML from a markdown draft.
---

# md-to-html

## Overview

Convert markdown files into self-contained HTML documents by wrapping them in a Quarto (.qmd) file with the preferred YAML header, then rendering with `quarto render`.

## Process

### 1. Identify the source markdown

- Locate the `.md` file in the working directory
- Read the file content to determine an appropriate `title` for the YAML header

### 2. Create the .qmd file

- Use the same filename with `.qmd` extension (underscores, not hyphens)
- Apply this YAML header, replacing the title to match the document:

```yaml
---
title: "Document Title Here"
author: "Badran Elshenawy"
date: today
format:
  html:
    theme: darkly
    toc: true
    toc-depth: 3
    code-fold: show
    code-tools: true
    embed-resources: true
    self-contained: true
    title-block-banner: true
---
```

### 3. Run md-format on the source

Before copying content into the `.qmd`, invoke the `md-format` skill on the source `.md` file to catch and fix any formatting issues (e.g. bullet lists missing a blank line before them that would collapse horizontally in the rendered output). Apply all fixes to the source before proceeding.

### 4. Preserve the writing

- Copy all markdown content below the YAML header **unchanged** (after `md-format` fixes have been applied)
- Do **not** convert prose to bullet points or alter structure — this skill preserves content as-is
- The `writing-qmd-scientific` skill governs QMD authoring conventions; this skill is only for conversion

### 6. Fix line breaks

- Consecutive bold metadata lines (e.g. `**Date:**`, `**Presenter:**`) need a trailing `\` to render on separate lines in Quarto
- Add `\` at the end of each such line except the last

### 7. Render

```bash
quarto render filename.qmd
```

- Output is a self-contained `.html` file in the same directory

## Naming Convention

- Use underscores (`_`) not hyphens (`-`) in filenames
- If the source `.md` uses hyphens, rename to underscores for both `.qmd` and `.html`

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Consecutive bold lines collapse into one line | Add trailing `\` for line breaks |
| Hyphens in filenames | Rename to underscores |
| Altering the writing content | This skill converts only — do not restructure or rephrase |
| Guessing the title | Read the source file and extract the actual title |
