---
name: tailoring-applications
description: Use when tailoring CVs and cover letters for job applications (academic or industry). Use when parsing job adverts, scaffolding application directories, drafting cover letters, or tailoring CVs to specific roles. Use when the user shares a job advert (text, URL, or PDF) and wants application documents produced.
---

# Tailoring Applications

Full pipeline skill for producing tailored CVs and cover letters from job adverts. Covers academic and industry applications. Self-contained — embeds all writing and formatting rules.

## Phase Detection

Before doing anything, detect which phase to enter based on what already exists. If the user provides a fresh advert, start at Phase 1. If an application directory already exists, pick up from the appropriate phase.

```
Phase 1: ANALYSE   → No directory exists, or no description.md / assessment.md
Phase 2: SCAFFOLD  → Directory exists with analysis files but missing QMDs
Phase 3: DRAFT     → QMDs need to be written or revised
Phase 4: RENDER    → QMDs are final, produce PDFs
```

Detection logic:

1. User provides an advert (text, URL, or PDF) → Phase 1
2. Directory exists with `description.md` + `assessment.md` but no QMDs → Phase 2
3. QMDs exist and user asks to revise → Phase 3
4. User explicitly asks to render → Phase 4

## Upfront Classification

Before Phase 1, determine the application type:

- **Academic** — university, research institute, or academic-adjacent position
- **Industry** — biotech, pharma, CRO, or commercial company

If obvious from the advert, infer and confirm. If ambiguous, ask. This classification drives tone, structure, and CV ordering throughout.

---

## Phase 1: ANALYSE

Parse the job advert and produce two files.

### Input Handling

The advert may arrive as:
- **Pasted text** — use directly
- **URL** — fetch with WebFetch and extract the job listing content
- **PDF file** — read with the Read tool

### Output: `description.md`

Structured breakdown of the advert. Follow this template:

```markdown
# [Institution/Company] — [Role Title]

## Role Summary

- **Title:** [Full title]
- **Employer:** [Organisation]
- **Location:** [City, remote/hybrid/on-site]
- **Salary:** [If stated, otherwise "Not disclosed"]
- **Type:** [Full-time/Part-time, Academic/Industry]
- **Focus:** [One-sentence summary of what the role does]
- **PI/Director:** [If academic, name the PI or group lead]

**Apply:**

- [Application method and link]

---

## About [Organisation/Department]

[2-3 paragraph summary of the organisation, department, or group. What they do, why it matters, scale.]

---

## Key Responsibilities

- [Bulleted list extracted or inferred from advert]

## Essential Requirements

- [Bulleted list — these are hard requirements]

## Desirable Requirements

- [Bulleted list — nice-to-haves]

---
```

Description formatting rules:

- Role-summary metadata must be a markdown bullet list using `- **Label:** value`.
- Do not emit bare bold metadata rows such as `**Title:** ...`.
- Leave `**Apply:**` as a standalone label followed by a blank line and a bullet list.
- Keep a blank line before every list start so pandoc renders lists vertically.

### Output: `assessment.md`

Honest, structured fit assessment. Follow this template:

```markdown
# [Institution/Company] — [Role Title]

- **Date applied:** [Today's date, YYYY-MM-DD]
- **Link:** [Application URL]
- **Location:** [City + remote/hybrid/on-site]
- **Salary:** [If known]
- **Company:** [One-sentence description of the organisation]
- **Role:** [One-sentence description of what the role involves]
- **Application method:** [How to apply]
- **Note:** [One-line honest assessment of fit — e.g., "Strong match on bioinformatics, weaker on ML engineering"]

---

## Overall Likelihood: ~[X]% ([Brief qualifier])

[2-3 sentence honest assessment of chances.]

---

## Top 3 Things Most Likely to Get You Shortlisted

1. **[Strength].** [Why this matters for this specific role.]
2. **[Strength].** [Why this matters.]
3. **[Strength].** [Why this matters.]

---

## Top 3 Things Most Likely to Sink the Application

1. **[Weakness].** [Why this is a problem for this specific role.]
2. **[Weakness].** [Why this is a problem.]
3. **[Weakness].** [Why this is a problem.]

---

## What You Could Do Before Applying

1. **[Action].** [How this would strengthen the application.]
2. **[Action].** [How this would help.]
3. **[Action].** [How this would help.]

---

## Is It Worth Applying?

**[Yes/No/Borderline].** [Reasoning — consider scale of hiring, stretch factor, learning value, network value.]
```

### Assessment Rules

- Be brutally honest about fit. Do not inflate likelihood.
- Assess against the applicant's actual profile (see Applicant Profile section below).
- 60-70% criteria match is sufficient to recommend applying.
- Flag when an application is a stretch but still worth it for learning or networking.

---

## Phase 2: SCAFFOLD

Create the application directory and file structure.

### Directory Naming

```
{academic,industry}_applications/YYYY-MM-DD_institution_shortname/
```

Examples:
- `academic_applications/2026-03-20_oxford_snelling/`
- `industry_applications/2026-03-20_healx_bioinformatician/`

Use today's date. Institution shortname should be lowercase, underscored, recognisable.

### Files to Create

```
YYYY-MM-DD_institution_shortname/
├── description.md                                          (from Phase 1)
├── assessment.md                                           (from Phase 1)
├── badran_elshenawy_<institution>_cover_letter.qmd         (empty scaffold)
└── badran_elshenawy_<institution>_cv.qmd                   (empty scaffold)
```

The QMD files should be scaffolded with the correct YAML front matter (see Formatting section) but no body content yet — that comes in Phase 3.

---

## Phase 3: DRAFT

Write the cover letter and CV content. This is the core of the skill.

### 3A: Cover Letter

The cover letter is **not a list of qualifications** — the CV handles that. The cover letter argues for **product-market fit**: why the institution needs someone like you, and why you are that person. The reader should finish thinking "this is an obvious hire," not "this person meets the criteria."

#### Structure: Product-Market Fit

```
\begin{flushright}
\textcolor{accent}{\textbf{Dr Badran Elshenawy}}\\
Nuffield Department of Medicine\\
University of Oxford\\
Oxford OX3 7FZ\\[0.6em]
[Date]
\end{flushright}

\textcolor{accent}{\textbf{[Supporting Statement / Application] --- [Role Title] (Ref: [number])}}\
[Institution / Department]

Dear [Hiring Committee / named contact],

## Where [Institution/Group] is heading
[1 paragraph: what the group/institute is doing, what direction they are moving in,
and what kind of person that direction calls for. Show you understand their context.
End with a line connecting yourself to that context.]

## What I bring
[1-2 paragraphs: your strongest relevant experience, framed as delivery not credentials.
Show what you have already done that maps to what they need. Let facts speak.
Be confident but not arrogant — "I have done X" not "I am the best at X".]

## [Research / Domain / Technical depth section — title varies by role]
[1-2 paragraphs: demonstrate that your research or technical work is directly
relevant to the role. Connect your daily work to their questions.
Show the overlap is real, not just theoretical.]

## Why [Institution] specifically
[1 paragraph: genuine, specific reasons. Timing, culture, partnerships, direction.
Not generic praise. Show you have done your homework.]

## What I am offering
[2-3 sentence summary. What you bring, what you want to do, openness to discuss.]

\vspace{0.6em}
Yours sincerely,
\vspace{0.2em}
\textcolor{accent}{\textbf{Dr Badran Elshenawy}}
```

**Rules:**
- **Product-market fit, not criterion checklist.** The CV lists qualifications; the cover letter argues for fit
- **Research the institution.** Use WebSearch to understand what they are building, what direction they are moving in, and what problems the hire is meant to solve. Reference specifics (papers, programmes, partnerships)
- Section headings should be narrative, not bureaucratic (e.g., "Where the lab is heading" not "Essential Criterion 1")
- Be direct but not arrogant. Confident but humble. "I have done X" not "I am the obvious choice"
- Avoid contrastive reframing and negation (e.g., "not just X, but Y"). State the positive directly
- Light use of em dashes only. Prefer commas, semicolons, or parentheses
- Use CAR framework where giving examples, but embed it in narrative, not as a checklist
- British English throughout
- No word padding — every sentence must earn its place
- If there is a gap in your profile, address it briefly (one sentence) and move on. Do not dwell on weaknesses

#### Supporting Statements (Oxford-style)

When the advert specifically asks for a "supporting statement that addresses each selection criterion," the product-market fit structure still works, but ensure each criterion is visibly addressed within the narrative sections. The reader should be able to tick off criteria while reading a compelling argument, not a bulleted list.

#### Industry Cover Letters

Same product-market fit approach, but:

- **Lead with what you deliver**, not your academic pedigree
- Emphasise transferable technical capabilities and outcomes
- Frame academic work in industry-relevant terms (e.g., "production-quality pipelines" not "research workflows")
- Shorter — industry reviewers scan faster

### 3B: CV Tailoring

Start from the master CV template at `cv_iterations/badran_elshenawy_cv_template.qmd`. Copy it into the application directory as `badran_elshenawy_<institution>_cv.qmd`, then tailor:

#### Elevator Pitch (Top Section)

Rewrite the elevator pitch using Past → Present → Future framework, tailored to this specific role. This is the most important section — reviewers scan in an F-pattern.

#### Section Ordering

- **Academic applications:** Area of study and science first. Research Experience before Technical Skills.
- **Industry applications:** Skills and methodology first. Technical Skills before Research Experience.

#### Bullet Point Tailoring

- **Relevant bullet points go to the top** of each section
- **Bold the verb** at the start of each bullet
- Use CAR framework: Accomplished X as measured by Y by doing Z
- All three CAR elements must be present (order is flexible)
- Focus on **your role first, the project second**
- Be specific — vague bullets do not demonstrate expertise
- Scan the advert for keywords and ensure they appear naturally in the CV

#### CV Constraints

- 2 pages maximum — strict
- 11pt font, narrow margins
- Reverse chronological within each section
- ORCID in contact header
- Must include: publications, open-source software, teaching, academic citizenship
- Do NOT remove sections wholesale — tailor within sections by reordering and rewording

### Writing Rules (Both Documents)

- **British English** spelling and conventions throughout
- **CAR framework** for all examples: Context, Action, Result
- **Nature Communications (2025):** Badran is a courtesy co-author — describe as "co-author" only. Do NOT claim he "contributed computational analyses."
- **PacBio pipeline:** He built it (real Snakemake work) but the team never used it. Fine to cite as evidence of engineering skills. Do NOT claim he "routinely integrates PacBio data."
- **Honesty over inflation.** If something is a stretch, frame it as a trajectory ("actively developing", "building towards") rather than claiming current mastery.
- **No word padding.** Every sentence must carry information. Cut filler.

---

## Phase 4: RENDER

Render both QMDs to PDF:

```bash
quarto render badran_elshenawy_<institution>_cover_letter.qmd --to pdf
quarto render badran_elshenawy_<institution>_cv.qmd --to pdf
```

After rendering, report:
- Word count for the cover letter (flag if over any stated limit)
- Page count for the CV (must be ≤ 2 pages)
- Any rendering errors

If the CV exceeds 2 pages, go back to Phase 3 and trim.

---

## Phase 5: OUTREACH

After rendering, draft a concise outreach email to the PI or hiring manager. Save as `outreach_<name>.md` in the application directory.

### Finding the contact

Use WebSearch to find the PI's email address. Check institutional staff pages, lab websites, and departmental directories. UCL emails typically follow `f.lastname@ucl.ac.uk`, Oxford follows `firstname.lastname@department.ox.ac.uk`.

### Outreach email structure

```markdown
# Outreach — [Name]

**To:** [email]
**Subject:** Application for [Role Title] (Ref [number])

---

[Greeting]

[1 sentence: you applied, linking to the role]

[1 paragraph: genuine interest in their specific work. Reference a paper, tool,
programme, or direction. Show you have read something real, not just the advert.]

[1 paragraph: specific value proposition. What you bring that connects to what
they are building. Be concrete — name datasets, methods, or experience that
maps directly to their needs.]

[1 sentence: ask for a meeting, offer flexibility]

Best,
Badran
```

### Rules

- Short. 4-5 paragraphs maximum.
- Genuine interest, not flattery.
- The value proposition paragraph should be specific and separate from the interest paragraph.
- Light on em dashes. No contrastive negation ("not just X, but Y").
- Tone: direct, warm, professional. Not formal, not casual.

---

## QMD Formatting

### Cover Letter YAML Front Matter

```yaml
---
format:
    pdf:
        documentclass: article
        papersize: a4
        fontsize: 11pt
        mainfont: "EB Garamond"
        mainfontoptions:
            - Numbers=OldStyle
        geometry:
            - top=25mm
            - bottom=25mm
            - left=25mm
            - right=25mm
        linestretch: 1.15
        indent: false
        colorlinks: true
        linkcolor: NavyBlue
        urlcolor: NavyBlue
        include-in-header:
            text: |
                \usepackage[dvipsnames]{xcolor}
                \definecolor{accent}{HTML}{1B3A5C}
                \definecolor{rulecolor}{HTML}{3B7EA1}
                \usepackage{ragged2e}
                \justifying
                \usepackage{enumitem}
                \setlength{\parskip}{0.5em}
                \setlength{\parindent}{0pt}
                \usepackage{titlesec}
                \titleformat{\section}{\normalfont\large\bfseries\color{accent}}{}{0em}{}
                \titleformat{\subsection}{\normalfont\normalsize\bfseries\color{accent}}{}{0em}{}
                \titlespacing*{\section}{0pt}{1.0em}{0.3em}
                \titlespacing*{\subsection}{0pt}{0.6em}{0.2em}
                \usepackage{fancyhdr}
                \pagestyle{fancy}
                \fancyhf{}
                \renewcommand{\headrulewidth}{0pt}
                \fancyfoot[C]{\footnotesize\color{rulecolor}%
                    \href{mailto:badran.elshenawy@ndm.ox.ac.uk}{badran.elshenawy@ndm.ox.ac.uk}
                    \enspace\textbar\enspace
                    \href{https://orcid.org/0000-0001-5672-8517}{ORCID}
                    \enspace\textbar\enspace
                    \href{https://github.com/wolf5996}{GitHub}
                    \enspace\textbar\enspace
                    \href{https://www.linkedin.com/in/dr-badran-m-e-65414b113/}{LinkedIn}
                    \enspace\textbar\enspace
                    \href{https://badran-elshenawy.netlify.app/}{Blog}}
---
```

### CV YAML Front Matter

```yaml
---
title: "Badran Elshenawy"
subtitle: "Postdoctoral Scientist — Bioinformatics — University of Oxford"
format:
    pdf:
        documentclass: article
        papersize: a4
        fontsize: 11pt
        mainfont: "EB Garamond"
        mainfontoptions:
            - Numbers=OldStyle
        geometry:
            - top=15mm
            - bottom=15mm
            - left=18mm
            - right=18mm
        linestretch: 1.05
        indent: false
        colorlinks: true
        linkcolor: NavyBlue
        urlcolor: NavyBlue
        include-in-header:
            text: |
                \usepackage[dvipsnames]{xcolor}
                \definecolor{accent}{HTML}{1B3A5C}
                \definecolor{rulecolor}{HTML}{3B7EA1}
                \usepackage{ragged2e}
                \justifying
                \usepackage{enumitem}
                \setlist[itemize]{nosep, left=0pt, topsep=2pt, parsep=1pt, itemsep=1pt}
                \setlength{\parskip}{0.3em}
                \setlength{\parindent}{0pt}
                \usepackage{titlesec}
                \titleformat{\section}{\normalfont\normalsize\bfseries\scshape\color{accent}}{}{0em}{}[\vspace{-0.5em}{\color{rulecolor}\rule{\linewidth}{0.5pt}}]
                \titleformat{\subsection}{\normalfont\normalsize\bfseries\color{accent}}{}{0em}{}
                \titlespacing*{\section}{0pt}{0.8em}{0.3em}
                \titlespacing*{\subsection}{0pt}{0.4em}{0.1em}
                \usepackage{fancyhdr}
                \pagestyle{fancy}
                \fancyhf{}
                \renewcommand{\headrulewidth}{0pt}
                \fancyfoot[C]{\footnotesize\thepage}
                \pagenumbering{gobble}
                \usepackage{titling}
                \setlength{\droptitle}{-3em}
                \pretitle{\begin{center}\LARGE\bfseries\color{accent}}
                \posttitle{\end{center}}
                \preauthor{}
                \postauthor{}
                \predate{\begin{center}\normalsize\color{accent}}
                \postdate{\end{center}}
                \date{}
                \author{}
---
```

---

## Applicant Profile

This section provides the ground truth for assessment and tailoring. Use this to write honest assessments and to select which experiences to foreground.

### Identity

Dr Badran Elshenawy, Postdoctoral Scientist, Nuffield Department of Medicine, University of Oxford.

### Research Focus

Computational biology for liver disease:
1. Spatial transcriptomics maps of the liver (Xenium platform, 250k+ cells, RFH + KCH cohorts)
2. Correcting hepatocyte underrepresentation in dissociation-based single-cell atlases
3. BadranSeq — open-source R package for publication-ready single-cell visualisations (v1.0.0, 15+ functions, CI/CD, pkgdown)
4. Long-read (PacBio) HBV viral genome analysis pipeline (Snakemake)
5. Reprocessing three major published liver reference atlases (MacParland, Aizarani, Henderson)
6. Bioinformatics teaching (Nile University, Egypt) and open-access training materials

### Technical Profile

- **Languages:** R (primary), Python, Bash
- **Genomics:** Single-cell RNA-seq (Seurat, Bioconductor), spatial transcriptomics (10x Xenium, GeoMx DSP), bulk RNA-seq, long-read sequencing (PacBio)
- **Methods:** Differential expression, dimensionality reduction, clustering, trajectory inference, pathway enrichment, cell type annotation, neighbourhood analysis, data integration
- **ML/Stats:** Classification, regression, feature selection, model evaluation, high-dimensional data analysis
- **Engineering:** Git/GitHub, CI/CD, Snakemake, pkgdown, HPC (SLURM), reproducible pipelines

### Publications

- *Nature Communications* 2025 — HBV transcriptome mapping (courtesy co-author)
- *Bioessays* 2022 — scRNA-seq review (first co-author)
- *Cell Genomics* 2025 — Hypoxia gene signatures (co-author, primary scRNA-seq bioinformatician)

### Education

- DPhil Oncology, University of Oxford (2020-2024)
- MSci Pharmacology, University of Bristol (First Class Honours, 2016-2020) — Neuropharmacology focus; master's research at Janssen R&D, Belgium (mouse models of neurodegeneration, gait analysis for therapeutic efficacy assessment)

### Teaching & Science Communication

- AI Ambassador, AI Competency Centre, University of Oxford (2025–present) — organises practical training events on AI adoption for researchers
- Event Organiser & Lead Presenter, "Agents for Research: A Live Showcase of Agentic AI Tools" (April 2026) — university-wide event attracting 120+ sign-ups (~75 in-person), ranking among the top 3 most-attended events in the AI Competency Centre's history. Delivered a 20-minute presentation on agentic AI skills architecture; coordinated 7 demonstrators across two thematic blocks. No prior coding experience required from attendees.
- Course Lead Instructor, Single-cell Data Analysis (CIT690), Nile University, Egypt (2025)
- Workshop Instructor, Wellcome Connecting Science, Sanger Institute (2023)
- Open-access teaching materials on GitHub

### Key GitHub Repos (wolf5996)

`BadranSeq`, `rfh-and-kch-xenium-analysis`, `macparland-reference-building`, `aizarani-reference-building`, `henderson-reference-building`, `PacBio-RNA-Seq-Pipeline`, `nile-uni-scrna-seq-workshop-2nd-edition`, `r-fundamentals`

### Honest Weaknesses (for assessment calibration)

- Python is secondary — public portfolio is R-heavy
- No deep learning / neural network engineering experience (active trajectory, not current expertise)
- No immunology-specific computational work (TCR/BCR repertoire analysis, protein design)
- No synthetic biology background
- Nature Communications paper is courtesy co-authorship — do not overclaim

---

## Checklist

For every application, confirm:

- [ ] `description.md` accurately reflects the advert (no hallucinated requirements)
- [ ] `assessment.md` is brutally honest about fit percentage
- [ ] Cover letter argues product-market fit, not just lists qualifications
- [ ] Cover letter shows research into the institution (specifics, not generic praise)
- [ ] Cover letter tone: confident but humble, no contrastive negation, light em dash usage
- [ ] All CAR examples have Context, Action, AND Result
- [ ] No overclaiming on Nature Communications or PacBio pipeline
- [ ] British English throughout
- [ ] CV is ≤ 2 pages after rendering (no orphan lines, no excessive whitespace)
- [ ] CV includes Academic Citizenship section (for academic applications)
- [ ] Elevator pitch is tailored to this specific role
- [ ] CV bullet ordering matches application type (academic vs industry)
- [ ] Word limits respected (if stated in advert)
- [ ] Both PDFs render cleanly with no LaTeX errors
- [ ] Outreach email drafted and saved as `outreach_<name>.md`
- [ ] DPhil dates: 2020-2024 (not 2025)
