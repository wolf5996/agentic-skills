# Metadata column card renderer
#
# Paste this whole file into the `card-renderer` chunk of a lettered metadata notebook
# (see ../assets/metadata-columns-template.qmd). It turns registry rows into self-contained
# HTML cards, grouped by category, with a legend, a status line and collapsible family tables.
#
# Usage, in a chunk with `#| output: asis`:
#   registry |> filter(provider == "Provider lab") |> render_metadata_cards(supplier = "Provider lab") |> cat()
#
# Registry contract (one row per column, as written by the column-registry chunk):
#   provider, name, family (NA for single columns), category, type ("categorical" / "continuous"),
#   description, description_source, added_in, status ("documented" / "undocumented" /
#   "missing" / "pending"), present (logical), class, n_na, n_levels, top_levels,
#   min, median, max, note
#
# Arguments:
#   category_colours  named hex vector; order sets the order of category blocks. Unknown
#                     categories are drawn in grey after the named ones
#   type_colours      named hex vector for "categorical" and "continuous"
#   status_colours    badge colours for the non-documented statuses
#   supplier          provider name whose cards get a "description added here" pill when
#                     description_source == "this notebook" (the analyst wrote the text)
#   legend            draw the data-type and category legend above the cards
#
# Returns one string: a ```{=html} raw block, so pandoc never re-parses indented HTML as code.

# Libraries ----------
library(conflicted)
library(dplyr)
library(purrr)
library(stringr)
library(htmltools)

# Palette ----------
default_category_colours <- c(
  "Sample metadata" = "#2e7d32",
  "QC metrics" = "#5c3d8f",
  "Cell state & classification" = "#8F3D70",
  "Raw cell annotation" = "#37474f",
  "Imputed cell annotation" = "#90a4ae",
  "Signature scores" = "#00838f",
  "Unassigned" = "#757575"
)

default_type_colours <- c(categorical = "#378ADD", continuous = "#D85A30")

default_status_colours <- c(undocumented = "#c62828", missing = "#c62828", pending = "#ef6c00")

# Styles ----------
card_css <- "
.mdc-legend{display:flex;flex-wrap:wrap;gap:.35rem 1.1rem;align-items:center;margin:.25rem 0 .9rem;font-size:.85rem}
.mdc-legend b{margin-right:.2rem}
.mdc-stats{font-size:.92rem;margin:.2rem 0 .6rem;opacity:.9}
.mdc-cat{display:flex;align-items:center;gap:.5rem;margin:1.4rem 0 .55rem;font-weight:600;font-size:1.05rem}
.mdc-cat small{font-weight:400;opacity:.7}
.mdc-dot{display:inline-block;width:.85rem;height:.85rem;border-radius:50%}
.mdc-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(340px,1fr));gap:.75rem}
.mdc-card{border:1px solid rgba(128,128,128,.32);border-left:6px solid;border-radius:8px;padding:.7rem .9rem;background:rgba(128,128,128,.06)}
.mdc-card.mdc-flag{border-style:dashed;border-left-style:solid}
.mdc-wide{grid-column:1/-1}
.mdc-head{display:flex;justify-content:space-between;align-items:baseline;gap:.5rem}
.mdc-name{font-family:SFMono-Regular,Menlo,Consolas,monospace;font-weight:700;font-size:.95rem;word-break:break-all}
.mdc-pills{display:flex;flex-wrap:wrap;gap:.3rem;margin:.4rem 0}
.mdc-pill{color:#fff;padding:1px 9px;border-radius:12px;font-size:.74rem;white-space:nowrap}
.mdc-ghost{background:transparent;color:inherit;border:1px solid rgba(128,128,128,.55)}
.mdc-desc{margin:.35rem 0;font-size:.88rem;line-height:1.45}
.mdc-note{margin:.3rem 0;padding:.25rem .5rem;border-radius:4px;background:rgba(239,108,0,.12);font-size:.8rem}
.mdc-summary{margin-top:.4rem;padding-top:.35rem;border-top:1px solid rgba(128,128,128,.25);font-size:.8rem;opacity:.85}
.mdc-status{color:#fff;padding:1px 7px;border-radius:4px;font-size:.68rem;font-weight:700;letter-spacing:.03em;text-transform:uppercase;white-space:nowrap}
.mdc-details summary{cursor:pointer;font-size:.84rem;margin-top:.45rem}
.mdc-scroll{max-height:460px;overflow:auto;margin-top:.35rem}
.mdc-members{width:100%;border-collapse:collapse;font-size:.78rem}
.mdc-members th,.mdc-members td{padding:2px 8px;border-bottom:1px solid rgba(128,128,128,.2);text-align:right;white-space:nowrap}
.mdc-members th:first-child,.mdc-members td:first-child{text-align:left}
"

# Card renderer function ----------
render_metadata_cards <- function(registry,
                                  category_colours = default_category_colours,
                                  type_colours = default_type_colours,
                                  status_colours = default_status_colours,
                                  supplier = NULL,
                                  legend = TRUE) {
  category_colour <- function(category) {
    if (category %in% names(category_colours)) category_colours[[category]] else "#757575"
  }

  escape_text <- function(text) {
    htmlEscape(text) |>
      str_replace_all("`([^`]+)`", "<code>\\1</code>")
  }

  format_number <- function(value) {
    if_else(is.na(value), "NA",
            trimws(formatC(signif(value, 3), format = "fg", digits = 3, big.mark = ",")))
  }

  format_count <- function(value) {
    if_else(is.na(value), "NA", format(value, big.mark = ",", scientific = FALSE, trim = TRUE))
  }

  pill <- function(label, colour) {
    sprintf('<span class="mdc-pill" style="background:%s">%s</span>', colour, escape_text(label))
  }

  ghost_pill <- function(label) {
    sprintf('<span class="mdc-pill mdc-ghost">%s</span>', escape_text(label))
  }

  status_badge <- function(status) {
    if (status %in% names(status_colours)) {
      sprintf('<span class="mdc-status" style="background:%s">%s</span>',
              status_colours[[status]], status)
    } else {
      ""
    }
  }

  summary_text <- function(row) {
    if (!row$present) {
      return(if_else(row$status == "pending",
                     paste("Pending: expected from", row$added_in, "once its checkpoint is written"),
                     "Not found in the object"))
    }
    na_text <- paste(format_count(row$n_na), "NA")
    if (row$type == "continuous") {
      paste0("min ", format_number(row$min), " · median ", format_number(row$median),
             " · max ", format_number(row$max), " · ", na_text)
    } else {
      paste0(format_count(row$n_levels), if_else(row$n_levels == 1, " level · ", " levels · "),
             na_text, "<br>top: ", escape_text(row$top_levels))
    }
  }

  card_pills <- function(row) {
    paste0(
      pill(row$category, category_colour(row$category)),
      pill(row$type, type_colours[[row$type]]),
      ghost_pill(row$added_in),
      if (!is.na(row$class) && row$class != "NA") ghost_pill(row$class) else "",
      if (!is.null(supplier) && row$provider == supplier && isTRUE(row$description_source == "this notebook")) {
        ghost_pill("description added here")
      } else {
        ""
      }
    )
  }

  single_card <- function(row) {
    flagged <- row$status != "documented"
    description <- if_else(is.na(row$description),
                           "<em>No description in the registry.</em>",
                           escape_text(row$description))
    note <- if (is.na(row$note)) "" else sprintf('<div class="mdc-note">Note: %s</div>', escape_text(row$note))
    sprintf(
      paste0('<div class="mdc-card%s" style="border-left-color:%s">',
             '<div class="mdc-head"><span class="mdc-name">%s</span>%s</div>',
             '<div class="mdc-pills">%s</div>',
             '<p class="mdc-desc">%s</p>%s',
             '<div class="mdc-summary">%s</div></div>'),
      if (flagged) " mdc-flag" else "", category_colour(row$category),
      escape_text(row$name), status_badge(row$status), card_pills(row),
      description, note, summary_text(row)
    )
  }

  family_card <- function(rows) {
    first_row <- rows[1, ]
    n_present <- sum(rows$present)
    family_status <- case_when(
      n_present == nrow(rows) ~ "documented",
      all(rows$status == "pending") ~ "pending",
      .default = "missing"
    )
    family_summary <- if (n_present == 0) {
      paste0(nrow(rows), " columns expected · pending: written by ", first_row$added_in)
    } else {
      present_rows <- filter(rows, present)
      paste0(n_present, " of ", nrow(rows), " columns present",
             " · medians ", format_number(min(present_rows$median)), " to ",
             format_number(max(present_rows$median)),
             " · overall range ", format_number(min(present_rows$min)), " to ",
             format_number(max(present_rows$max)),
             " · ", format_count(sum(present_rows$n_na)), " NA")
    }
    member_rows <- rows |>
      pmap_chr(\(...) {
        member <- list(...)
        sprintf("<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>",
                escape_text(member$name), format_number(member$min),
                format_number(member$median), format_number(member$max),
                format_count(member$n_na), member$status)
      }) |>
      paste(collapse = "")
    sprintf(
      paste0('<div class="mdc-card mdc-wide%s" style="border-left-color:%s">',
             '<div class="mdc-head"><span class="mdc-name">%s</span>%s</div>',
             '<div class="mdc-pills">%s%s</div>',
             '<p class="mdc-desc">%s</p>',
             '<div class="mdc-summary">%s</div>',
             '<details class="mdc-details"><summary>All %d %s columns</summary>',
             '<div class="mdc-scroll"><table class="mdc-members"><thead><tr>',
             '<th>Column</th><th>Min</th><th>Median</th><th>Max</th><th>NA</th><th>Status</th>',
             '</tr></thead><tbody>%s</tbody></table></div></details></div>'),
      if (family_status != "documented") " mdc-flag" else "",
      category_colour(first_row$category),
      escape_text(paste0(first_row$family, "<PATHWAY>")), status_badge(family_status),
      card_pills(mutate(first_row, class = "NA")), ghost_pill(paste(nrow(rows), "columns")),
      escape_text(first_row$description), family_summary,
      nrow(rows), escape_text(first_row$family), member_rows
    )
  }

  legend_html <- paste0(
    '<div class="mdc-legend"><b>Data type</b>',
    paste(map2_chr(names(type_colours), type_colours, pill), collapse = ""),
    '</div><div class="mdc-legend"><b>Category</b>',
    paste(map2_chr(names(category_colours), category_colours, pill), collapse = ""),
    "</div>"
  )

  status_counts <- count(registry, status)
  stats_html <- sprintf(
    '<div class="mdc-stats"><b>%d columns</b> · %s</div>',
    nrow(registry),
    paste(status_counts$n, status_counts$status, collapse = " · ")
  )

  category_blocks <- registry |>
    mutate(category = factor(category, levels = union(names(category_colours), unique(category)))) |>
    arrange(category) |>
    group_split(category) |>
    map_chr(\(rows) {
      category <- as.character(rows$category[1])
      cards <- rows |>
        mutate(card_key = coalesce(family, name)) |>
        group_split(card_key = factor(card_key, levels = unique(card_key))) |>
        map_chr(\(card_rows) {
          card_rows <- mutate(card_rows, category = as.character(category))
          if (is.na(card_rows$family[1])) single_card(card_rows[1, ]) else family_card(card_rows)
        }) |>
        paste(collapse = "")
      sprintf(
        '<div class="mdc-cat"><span class="mdc-dot" style="background:%s"></span>%s <small>(%d %s)</small></div><div class="mdc-grid">%s</div>',
        category_colour(category), htmlEscape(category), nrow(rows),
        if (nrow(rows) == 1) "column" else "columns", cards
      )
    }) |>
    paste(collapse = "")

  paste0(
    "\n```{=html}\n<style>", card_css, "</style>\n",
    if (legend) legend_html else "", stats_html, category_blocks,
    "\n```\n"
  )
}
