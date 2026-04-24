---
name: recommendation-letter-workflow
description: Use when creating or maintaining a repository of recommendation letters for applications, especially Quarto-based `.qmd` letters rendered to PDF. Use for bootstrapping a new repo, adding a new institution folder, editing an existing letter, or rendering final PDFs from application-specific materials.
---

# Recommendation Letter Workflow

Use this skill for the full recommendation-letter pipeline: repository setup, dated folder naming, QMD drafting, description notes, and PDF rendering.

## When To Use

- A new recommendation-letter repository needs to be created.
- An existing repository needs a new institution/application folder.
- A `.qmd` letter needs to be edited, rendered, or archived.
- Supporting application material needs to be turned into a referee letter or questionnaire answer.

## Core Workflow

1. Inspect the current repository state first.
2. If starting fresh, create the standard folder structure from [repository conventions](references/repository-conventions.md).
3. Name application folders `YYYY-MM-DD_institution/`.
4. Duplicate the template QMD into the new dated folder and tailor recipient details, date, and body text.
5. Create a `description.qmd` that records what was changed and why.
6. Render with `quarto render <folder>/<file>.qmd`.
7. Check the PDF for placeholders, date accuracy, recipient accuracy, and layout issues.

## Editing Rules

- Keep the repository organized around dated application folders plus a shared `template/`.
- Use the repository's existing prose and formatting patterns unless the target institution requires a different tone.
- Replace institution-specific placeholders in both opening and closing paragraphs.
- Keep claims grounded in the applicant information already available in the repo.
- If a questionnaire is requested, answer directly in the same style as the letters and save the final text in Markdown.

## Output Expectations

- For new work, create the repository structure, template, application folder, `qmd`, and `description.qmd`.
- For existing work, update only the relevant dated folder and its rendered PDF.
- Prefer concise, reusable text that can be adapted across institutions without inventing new facts.

## If You Need More Detail

See [repository conventions](references/repository-conventions.md) for the exact folder layout, naming patterns, and template structure used in this repository.
