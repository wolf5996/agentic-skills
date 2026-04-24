# Repository Conventions

## Folder Layout

- `template/` contains the master Quarto source.
- `YYYY-MM-DD_institution/` contains one application package.
- `archived_docx_letters/` stores older `.docx` and `.pdf` versions.
- `supporting_documents/` stores applicant CVs, theses, and other reference material.
- `docs/plans/` stores planning notes and implementation documents.

## Naming

- Use dated folder names: `2026-03-23_protaiomics/`.
- Use matching filenames inside each folder, for example `protaiomics_recommendation_letter.qmd` and `protaiomics_recommendation_letter.pdf`.
- Prefer lowercase, underscored filenames.
- For upload forms, follow the requested naming convention exactly, often `SurnameForenameProgramme`.

## Letter Structure

- Keep a right-aligned date block.
- Keep a recipient block and subject line near the top.
- Use section headings for the core themes:
  - Theoretical Knowledge
  - Technical Proficiency
  - Interpretation and Analytical Insight
  - Independence and Problem-Solving
  - Motivation, Work Ethic, and Professionalism
  - Communication Skills
  - Overall Assessment
- Include optional sections only when they strengthen the application.

## Rendering

- Use `quarto render` to produce the PDF.
- Verify the output before delivery.
- If the environment is missing TeX or fonts, fix the toolchain rather than changing the letter content unless necessary.
