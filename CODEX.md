# CODEX.md

This repository contains opinionated Codex skills for R and bioinformatics workflows. Each skill lives in its own directory with a single `SKILL.md` file and optional `agents/openai.yaml` metadata.

## Repository Structure

```
~/.codex/skills/
├── personal_skills/              # this git-backed collection
│   ├── creating-analysis-projects/SKILL.md
│   ├── developing-r-packages/SKILL.md
│   ├── md-to-html/SKILL.md
│   ├── tailoring-applications/SKILL.md
│   ├── writing-labarchive-entries/SKILL.md
│   ├── writing-qmd-scientific/SKILL.md
│   └── writing-r-code/SKILL.md
├── creating-analysis-projects -> personal_skills/creating-analysis-projects
├── developing-r-packages -> personal_skills/developing-r-packages
├── md-to-html -> personal_skills/md-to-html
├── tailoring-applications -> personal_skills/tailoring-applications
├── writing-labarchive-entries -> personal_skills/writing-labarchive-entries
├── writing-qmd-scientific -> personal_skills/writing-qmd-scientific
└── writing-r-code -> personal_skills/writing-r-code
```

## Discovery

Codex discovers user skills from top-level directories in `~/.codex/skills/`. If this repository is kept in `~/.codex/skills/personal_skills/`, each skill should also have a symlink one level up so it can be discovered directly.

## Adding or Updating Skills

1. Add or update `<skill-name>/SKILL.md`
2. Regenerate `agents/openai.yaml` if the human-facing metadata changed
3. Ensure the top-level symlink exists in `~/.codex/skills/`
4. Keep naming lowercase and hyphen-separated

## Shared Preferences

- **HTML output is dark by default.** Any skill that renders HTML (Quarto, R Markdown) uses `theme: {dark: darkly, light: cosmo}` with `dark` listed first. Never ship a light-only theme
