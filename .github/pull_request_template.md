# CanadaLogin Signal Check N

For the two-week period of Month D through D.

## This edition

1. Figure 1:
2. Figure 2:
3. Figure 3:

## Author checklist

- [ ] Preflight in `explore.qmd` passes for this period
- [ ] Each paragraph opens with a bolded takeaway and bolds one or two numbers
- [ ] Every number in the prose is an inline expression
- [ ] The closing line links the previous edition
- [ ] Alt text numbers match the latest render
- [ ] Axes start at zero, or the figure says why not
- [ ] `lintr` is clean
- [ ] Footer archive links are filled in (they come from `.env`)
- [ ] Preview is published and loads, and the link is shared on Slack

## Reviewing

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
