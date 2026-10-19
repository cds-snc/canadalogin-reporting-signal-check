# CanadaLogin Signal Check #N

For the two-week period of Month D to D.

Do not post the report link here. Share the preview on Slack and tag the reviewers.

## This edition

1. Figure 1:
2. Figure 2:
3. Figure 3:

## For reviewers

<!-- Anything to weigh: anomalies raised with the team, caveats, departures
from a cookbook recipe, partner-sensitive wording. Delete if none. -->

**Shared changes:** <!-- Footers, R/, _quarto.yml. These change every
edition on re-render. Write "None" if none. -->

## Author checklist

Data

- [ ] Preflight in `explore.qmd` passes for this period
- [ ] Every causal claim is checked against the per-application breakdown
- [ ] Each metric follows its cookbook recipe, or the departure is noted above

Writing

- [ ] Each paragraph opens with a bolded takeaway and bolds one or two numbers
- [ ] Every number in the prose is an inline expression
- [ ] No unlaunched partner is named, and no incident is blamed without a confirmed cause
- [ ] The closing line links the previous edition

Figures

- [ ] Alt text numbers match the latest render
- [ ] Axes start at zero, or the figure says why not

Render

- [ ] `lintr` is clean
- [ ] Footer archive links are filled in (they come from `.env`)
- [ ] October: spooky footer, with the bat only on the last edition before Halloween
- [ ] Preview is published and loads, and the link is shared on Slack

## Reviewing

- Read it as an executive would: does each bold title tell you the point?
- Flag any number that looks wrong or unexplained.
- Ask for more time if you need it. Approve when it is ready.

## Merge

No sooner than two hours after this PR opened. Merge once everyone in
@cds-snc/edcp-data-and-research who is not on leave has approved, or the two
hours pass with no request to hold.

Squash and merge with this message. Leave out "#", which GitHub reads as an
issue link:

```text
feat: add signal check edition N
```

## After merge

- [ ] Re-render from `main` and re-publish with `./publish.sh reports/<file>.html --push` (the URL stays the same)
- [ ] Check that no number moved in the re-render
- [ ] Save the message text in the publishing repo's `messages/`
- [ ] Upload to Google Drive and SharePoint
- [ ] Email readers
- [ ] Post in the EDCP Teams channel and #edcp-data-and-research, and crosspost to #canadalogin
