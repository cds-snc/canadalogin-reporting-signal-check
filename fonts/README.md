# Brand typeface

Source Sans 3, the current release of the Source Sans Pro named in the CDS Brand
Guide. Vendored so that neither rendering a report nor reading one needs network
access.

Two formats, because nothing reads both:

| Files | Used by | Purpose |
| --- | --- | --- |
| `*.woff2` (6) | `reports/_fonts.scss` | Document text. Quarto inlines them at render time. |
| `*.ttf` (2) | `R/branding.R` | ggplot figures via showtext. `sysfonts` cannot read WOFF2. |

Keep the two in step. If the typeface is ever changed, both sets have to move
together or the prose and the graphs will disagree.

## Provenance

- **WOFF2**, latin subset, ~16 KB each: `@fontsource/source-sans-3` 5.3.0, via
  `cdn.jsdelivr.net/npm/@fontsource/source-sans-3@5.3.0/files/`.
- **TTF**, weights 400 and 600, ~235 KB each: `fonts.gstatic.com`, the same
  files `sysfonts::font_add_google("Source Sans 3")` used to fetch at render
  time, so the figures render identically to before they were vendored.

## Licence

SIL Open Font License 1.1. Full text in `LICENSE.txt`.

> Copyright 2010-2024 Adobe (http://www.adobe.com/), with Reserved Font Name
> 'Source'.

The OFL permits redistribution, bundling, and embedding in documents. It
requires that the copyright notice and licence travel with the font, which is
what `LICENSE.txt` is for, and it forbids selling the font on its own.
