---
name: md-format
description: Use when writing or editing .md, .rmd, or .qmd files. Apply when authoring lists, headings, or structured content rendered by pandoc — including Hugo (via hugodown), Quarto, or plain markdown pipelines. Enforces formatting patterns that ensure correct vertical rendering of bullet lists and other structural elements across all three document types.
---

# Markdown Formatting

## Overview

All three document types — `.md`, `.rmd`, and `.qmd` — are processed by pandoc before final rendering. Pandoc applies strict rules about blank lines that determine whether content renders as a list or collapses into inline text. The same rules apply regardless of whether the output is a Hugo blog post, a Quarto HTML document, or a plain markdown file.

**Golden rule:** pandoc needs a blank line before the first list item to recognise it as a list.

---

## Rule 1: Blank line before list items

A bullet list must be preceded by a **blank line**. Without it, pandoc treats the `-` or `*` markers as part of the preceding paragraph and collapses all items into a single horizontal line.

### Trigger contexts

This failure is most likely to occur after:

| Preceding element | Example |
|---|---|
| Bold label (e.g. method heading) | `**Monocle3 (R)** 🧭` |
| Inline emphasis label | `*Solutions:*` |
| Paragraph ending with a colon | `If you don't know where to start:` |
| Any paragraph with no trailing blank line | Any prose block |

### Correct vs incorrect

**Wrong — no blank line, items collapse horizontally:**

```markdown
**Monocle3 (R)** 🧭
- Handles branching trajectories well
- Integrates with Seurat via SeuratWrappers
- Best for: General-purpose trajectory analysis in R
```

Renders as:
> **Monocle3 (R)** 🧭 - Handles branching trajectories well - Integrates with Seurat via SeuratWrappers - Best for: General-purpose trajectory analysis in R

**Correct — blank line inserted, items render vertically:**

```markdown
**Monocle3 (R)** 🧭

- Handles branching trajectories well
- Integrates with Seurat via SeuratWrappers
- Best for: General-purpose trajectory analysis in R
```

### More examples

**Wrong:**

```markdown
If you don't know where to start:
- RNA velocity can suggest directionality
- Multiple root selections can test robustness
```

**Correct:**

```markdown
If you don't know where to start:

- RNA velocity can suggest directionality
- Multiple root selections can test robustness
```

---

**Wrong:**

```markdown
*Solutions:*
- Adjust `learn_graph()` parameters
- Check cell density in putative branch regions
```

**Correct:**

```markdown
*Solutions:*

- Adjust `learn_graph()` parameters
- Check cell density in putative branch regions
```

---

### Applies to all three file types

| File type | Renderer | Same rule applies? |
|---|---|---|
| `.md` | pandoc directly | Yes |
| `.rmd` | knitr → pandoc (hugodown) | Yes |
| `.qmd` | knitr/jupyter → pandoc (Quarto) | Yes |

The blank line requirement is a pandoc rule, not a Hugo or Quarto rule. It applies everywhere pandoc is in the rendering chain.

---

## Verification before rendering

Before rendering any document, grep for list items that immediately follow non-blank lines:

```bash
# Flag lines where a list item (-) is preceded by a non-blank line
grep -n "^[-\*] " file.rmd | cut -d: -f1 | while read n; do
  prev=$((n - 1))
  prevline=$(sed -n "${prev}p" file.rmd)
  if [ -n "$prevline" ] && [[ "$prevline" != "---" ]]; then
    echo "Line $n may be missing a blank line above it: $prevline"
  fi
done
```

Or use a quick visual scan with context:

```bash
grep -n -B1 "^[-\*] " file.rmd
```

Any result where the `-B1` line is non-blank (and not another list item) is a candidate for a missing blank line.

---

## Common Mistakes

| Mistake | What renders | Fix |
|---|---|---|
| Bold method heading immediately followed by list | Items collapse into one line after the heading | Add blank line after the bold heading |
| `*Solutions:*` or `*Diagnosis:*` immediately followed by list | Items collapse inline | Add blank line after the emphasis label |
| Paragraph ending with colon immediately followed by list | Items collapse inline | Add blank line between colon and first `-` |
| Nested list items without blank line from parent paragraph | Nested items collapse | Ensure blank line before first nested `-` too |
| Fixing the `.rmd` but forgetting to re-render the `.md` | `.md` still has the old collapsed rendering | Always re-render after fixing the source |
