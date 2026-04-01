# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This repo (`wolf5996/claude-skills`) contains opinionated Claude Code skills for R/bioinformatics workflows. Each skill is a directory with a single `SKILL.md` file that teaches Claude domain-specific conventions.

## Repo Structure

```
~/.claude/skills/
├── personal_skills/          ← this git repo
│   ├── creating-analysis-projects/SKILL.md
│   ├── developing-r-packages/SKILL.md
│   ├── md-to-html/SKILL.md
│   ├── tailoring-applications/SKILL.md
│   ├── writing-labarchive-entries/SKILL.md
│   ├── writing-qmd-scientific/SKILL.md
│   ├── writing-r-code/SKILL.md
│   └── writing-commit-messages/SKILL.md
├── creating-analysis-projects -> personal_skills/creating-analysis-projects
├── developing-r-packages -> personal_skills/developing-r-packages
├── md-to-html -> personal_skills/md-to-html
├── tailoring-applications -> personal_skills/tailoring-applications
├── writing-labarchive-entries -> personal_skills/writing-labarchive-entries
├── writing-qmd-scientific -> personal_skills/writing-qmd-scientific
├── writing-r-code -> personal_skills/writing-r-code
└── writing-commit-messages -> personal_skills/writing-commit-messages
```

## Symlink Requirement

Claude Code discovers skills from `~/.claude/skills/<skill-name>/SKILL.md`. Since this repo lives at `~/.claude/skills/personal_skills/`, each skill directory needs a **symlink one level up** to be visible:

```bash
# From ~/.claude/skills/
ln -s personal_skills/<skill-name> <skill-name>
```

**Every new skill must have a corresponding symlink created in `~/.claude/skills/`.** Without it, Claude Code will not discover or load the skill. After adding a new skill directory to this repo, always create the symlink before committing.

## Adding a New Skill

1. Create `<skill-name>/SKILL.md` in this repo with YAML frontmatter (`name`, `description`)
2. Create symlink: `ln -s personal_skills/<skill-name> ~/.claude/skills/<skill-name>`
3. Update `README.md`: add to the skills table and dependency graph
4. Naming convention: lowercase, hyphen-separated (e.g., `writing-r-code`)

## Editing Skills

- Skills are invoked via the `Skill` tool, not `Read`. Never use `Read` on a SKILL.md to invoke it.
- The `description` field in frontmatter controls when Claude triggers the skill — make it specific about file types, task types, and contexts.
- Skills reference each other (see dependency graph in README.md). When changing shared conventions in `writing-r-code`, check downstream skills (`writing-qmd-scientific`, `creating-analysis-projects`).
